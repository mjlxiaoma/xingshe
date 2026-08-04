import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/database/local_database.dart';

@immutable
class ShareRoutePoint {
  const ShareRoutePoint(this.x, this.y);

  final double x;
  final double y;
}

@immutable
class TripShareCardModel {
  const TripShareCardModel({
    required this.title,
    required this.date,
    required this.distance,
    required this.duration,
    required this.photoCount,
    required this.route,
  });

  factory TripShareCardModel.fromLocal({
    required LocalTrip trip,
    required Iterable<LocalTrackPoint> tracks,
    required int photoCount,
  }) {
    final ordered = tracks.toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return TripShareCardModel(
      title: trip.title,
      date: _date(trip.startedAt),
      distance: _distance(trip.distanceMeters),
      duration: _duration(trip.durationSeconds),
      photoCount: max(0, photoCount),
      route: _normalize(ordered),
    );
  }

  final String title;
  final String date;
  final String distance;
  final String duration;
  final int photoCount;
  final List<ShareRoutePoint> route;
}

class TripShareCard extends StatelessWidget {
  const TripShareCard({super.key, required this.model, this.cover});

  final TripShareCardModel model;
  final Widget? cover;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('trip-share-card'),
    width: 300,
    height: 548,
    child: ColoredBox(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 206,
            child: Stack(
              fit: StackFit.expand,
              children: [
                cover ??
                    const ColoredBox(
                      color: Color(0xFF1E3322),
                      child: Icon(
                        Icons.landscape,
                        color: Color(0xFFD4A020),
                        size: 54,
                      ),
                    ),
                const ColoredBox(color: Color(0x4D102616)),
                const Positioned(
                  left: 16,
                  top: 14,
                  child: Row(
                    children: [
                      Icon(Icons.photo_camera, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        '行摄',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 34,
                  child: Text(
                    model.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Text(
                    model.date,
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _Stat(label: '距离', value: model.distance),
                      const SizedBox(width: 4),
                      _Stat(label: '时长', value: model.duration),
                      const SizedBox(width: 4),
                      _Stat(label: '照片', value: '${model.photoCount} 张'),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Expanded(child: _RouteThumbnail(points: model.route)),
                  const SizedBox(height: 13),
                  const Row(
                    children: [
                      Icon(Icons.shield, color: Color(0xFF2D6B3F), size: 15),
                      SizedBox(width: 6),
                      Text(
                        '已隐藏精确地址与个人信息',
                        style: TextStyle(
                          color: Color(0xFF2D6B3F),
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: ColoredBox(
      color: const Color(0xFFF4F6F3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        child: Column(
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF667268), fontSize: 8),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RouteThumbnail extends StatelessWidget {
  const _RouteThumbnail({required this.points});

  final List<ShareRoutePoint> points;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('trip-share-route'),
    color: const Color(0xFFEAF0E8),
    child: points.isEmpty
        ? const Center(
            child: Text(
              '无公开路线',
              style: TextStyle(color: Color(0xFF667268), fontSize: 10),
            ),
          )
        : CustomPaint(painter: _RoutePainter(points)),
  );
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter(this.points);

  final List<ShareRoutePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 18.0;
    Offset offset(ShareRoutePoint point) => Offset(
      padding + point.x * (size.width - padding * 2),
      padding + point.y * (size.height - padding * 2),
    );
    final path = Path()
      ..moveTo(offset(points.first).dx, offset(points.first).dy);
    for (final point in points.skip(1)) {
      final value = offset(point);
      path.lineTo(value.dx, value.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE85D45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(
      offset(points.first),
      6,
      Paint()..color = const Color(0xFF2D6B3F),
    );
    canvas.drawCircle(
      offset(points.last),
      6,
      Paint()..color = const Color(0xFFE85D45),
    );
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.points != points;
}

List<ShareRoutePoint> _normalize(List<LocalTrackPoint> tracks) {
  if (tracks.isEmpty) return const [];
  final minLatitude = tracks.map((point) => point.latitude).reduce(min);
  final maxLatitude = tracks.map((point) => point.latitude).reduce(max);
  final minLongitude = tracks.map((point) => point.longitude).reduce(min);
  final maxLongitude = tracks.map((point) => point.longitude).reduce(max);
  final latitudeSpan = maxLatitude - minLatitude;
  final longitudeSpan = maxLongitude - minLongitude;
  return tracks
      .map(
        (point) => ShareRoutePoint(
          longitudeSpan == 0
              ? 0.5
              : (point.longitude - minLongitude) / longitudeSpan,
          latitudeSpan == 0
              ? 0.5
              : 1 - (point.latitude - minLatitude) / latitudeSpan,
        ),
      )
      .toList(growable: false);
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')}';
}

String _distance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(2)} km';

String _duration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}';
}
