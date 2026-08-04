import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/local_database.dart';
import '../../core/location/track_synchronizer.dart';
import '../../core/location/trip_recording_controller.dart';

class ActiveTripPage extends ConsumerStatefulWidget {
  const ActiveTripPage({super.key, required this.tripID});

  final String tripID;

  @override
  ConsumerState<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends ConsumerState<ActiveTripPage> {
  late final Stream<LocalTrip?> _trip;
  late final Stream<List<LocalTrackPoint>> _tracks;
  late final Stream<List<LocalTripPhoto>> _photos;

  @override
  void initState() {
    super.initState();
    final database = ref.read(localTripDatabaseProvider);
    _trip = (database.select(
      database.localTrips,
    )..where((row) => row.id.equals(widget.tripID))).watchSingleOrNull();
    _tracks = (database.select(
      database.localTrackPoints,
    )..where((row) => row.tripId.equals(widget.tripID))).watch();
    _photos = (database.select(
      database.localTripPhotos,
    )..where((row) => row.tripId.equals(widget.tripID))).watch();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LocalTrip?>(
      stream: _trip,
      builder: (context, tripSnapshot) {
        final value = tripSnapshot.data;
        if (value == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return StreamBuilder<List<LocalTrackPoint>>(
          stream: _tracks,
          initialData: const [],
          builder: (context, trackSnapshot) =>
              StreamBuilder<List<LocalTripPhoto>>(
                stream: _photos,
                initialData: const [],
                builder: (context, photoSnapshot) => _ActiveTripView(
                  trip: value,
                  pointCount: trackSnapshot.data?.length ?? 0,
                  photoCount: photoSnapshot.data?.length ?? 0,
                ),
              ),
        );
      },
    );
  }
}

class _ActiveTripView extends ConsumerStatefulWidget {
  const _ActiveTripView({
    required this.trip,
    required this.pointCount,
    required this.photoCount,
  });

  final LocalTrip trip;
  final int pointCount;
  final int photoCount;

  @override
  ConsumerState<_ActiveTripView> createState() => _ActiveTripViewState();
}

class _ActiveTripViewState extends ConsumerState<_ActiveTripView> {
  bool _busy = false;

  bool get _paused => widget.trip.status == 'paused';

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('trip-active-page'),
    backgroundColor: const Color(0xFFEAF0E8),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const Positioned.fill(
                  child: CustomPaint(painter: _TrackPainter()),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusBadge(paused: _paused),
                      const Spacer(),
                      Text(
                        widget.trip.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.trip.spotId != null) ...[
                        const SizedBox(height: 5),
                        const Text(
                          '已关联摄影机位',
                          style: TextStyle(
                            color: Color(0xFF667268),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFDDE3DD))),
            ),
            child: Column(
              children: [
                Text(
                  _duration(widget.trip.durationSeconds),
                  key: const Key('trip-duration'),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _Metric(
                      value: _distance(widget.trip.distanceMeters),
                      label: '距离',
                    ),
                    _Metric(value: '${widget.pointCount} 个', label: '轨迹点'),
                    _Metric(value: '${widget.photoCount} 张', label: '照片'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SizedBox.square(
                      dimension: 52,
                      child: IconButton.filledTonal(
                        key: const Key('trip-camera-button'),
                        onPressed: _busy ? null : () {},
                        icon: const Icon(Icons.photo_camera),
                        tooltip: '拍照',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('trip-pause-resume-button'),
                        onPressed: _busy ? null : _toggle,
                        icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                        label: Text(_paused ? '继续记录' : '暂停记录'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox.square(
                      dimension: 52,
                      child: IconButton.outlined(
                        key: const Key('trip-end-button'),
                        onPressed: _busy ? null : _end,
                        icon: const Icon(Icons.stop),
                        tooltip: '结束',
                      ),
                    ),
                  ],
                ),
                if (_paused) ...[
                  const SizedBox(height: 10),
                  const Text(
                    '暂停期间不记录轨迹',
                    style: TextStyle(color: Color(0xFF667268), fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      final controller = ref.read(tripRecordingControllerProvider);
      if (_paused) {
        await controller.resume(widget.trip.id);
      } else {
        await controller.pause(widget.trip.id);
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('定位状态更新失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _end() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('结束这次行摄？'),
        content: const Text('结束后将停止前台定位服务并封存轨迹，完成状态不能继续追加轨迹。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            key: const Key('trip-confirm-end-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('结束行摄'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(tripRecordingControllerProvider).complete(widget.trip.id);
      if (mounted) context.go('/');
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('结束行摄失败，请重试')));
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.paused});

  final bool paused;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFFDDE3DD)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          paused ? Icons.pause_circle : Icons.gps_fixed,
          color: const Color(0xFF2D6B3F),
          size: 18,
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              paused ? '已暂停' : '正在记录',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              paused ? '定位记录已暂停' : '后台记录已开启',
              style: const TextStyle(color: Color(0xFF667268), fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF667268), fontSize: 10),
        ),
      ],
    ),
  );
}

class _TrackPainter extends CustomPainter {
  const _TrackPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x1683AA8D)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final route = Path()
      ..moveTo(size.width * 0.08, size.height * 0.73)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.35,
        size.width * 0.58,
        size.height * 0.8,
        size.width * 0.9,
        size.height * 0.24,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFF83AA8D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

String _duration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remaining = seconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${remaining.toString().padLeft(2, '0')}';
}

String _distance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(2)} km';
