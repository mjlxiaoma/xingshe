import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/local_database.dart';
import '../../core/location/track_synchronizer.dart';
import 'trip_share_card.dart';
import 'trip_share_image.dart';

typedef ShareImageGenerator = Future<File> Function(GlobalKey boundaryKey);

class TripSharePreviewPage extends ConsumerStatefulWidget {
  const TripSharePreviewPage({super.key, required this.tripID, this.generator});

  final String tripID;
  final ShareImageGenerator? generator;

  @override
  ConsumerState<TripSharePreviewPage> createState() =>
      _TripSharePreviewPageState();
}

class _TripSharePreviewPageState extends ConsumerState<TripSharePreviewPage> {
  final _cardKey = GlobalKey();
  bool _generating = false;
  File? _generatedImage;

  Future<void> _generate() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final image = await (widget.generator ?? generateTripShareImage)(
        _cardKey,
      );
      if (!mounted) return;
      setState(() => _generatedImage = image);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分享图已在本机生成')));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分享图生成失败，请重试')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = ref.watch(localTripDatabaseProvider);
    final trip = (database.select(
      database.localTrips,
    )..where((row) => row.id.equals(widget.tripID))).watchSingleOrNull();
    final tracks =
        (database.select(database.localTrackPoints)
              ..where((row) => row.tripId.equals(widget.tripID))
              ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]))
            .watch();
    final photos = (database.select(
      database.localTripPhotos,
    )..where((row) => row.tripId.equals(widget.tripID))).watch();
    return Scaffold(
      key: const Key('trip-share-preview-page'),
      appBar: AppBar(title: const Text('分享图预览')),
      backgroundColor: const Color(0xFFF4F6F3),
      body: StreamBuilder<LocalTrip?>(
        stream: trip,
        builder: (context, tripSnapshot) {
          final value = tripSnapshot.data;
          if (value == null) {
            return tripSnapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator())
                : const Center(child: Text('行程不存在'));
          }
          return StreamBuilder<List<LocalTrackPoint>>(
            stream: tracks,
            initialData: const [],
            builder: (context, trackSnapshot) =>
                StreamBuilder<List<LocalTripPhoto>>(
                  stream: photos,
                  initialData: const [],
                  builder: (context, photoSnapshot) => ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    children: [
                      Center(
                        child: RepaintBoundary(
                          key: _cardKey,
                          child: TripShareCard(
                            model: TripShareCardModel.fromLocal(
                              trip: value,
                              tracks: trackSnapshot.data ?? const [],
                              photoCount: photoSnapshot.data?.length ?? 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.smartphone,
                            color: Color(0xFF667268),
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '图片仅在本机生成，不上传服务器',
                            style: TextStyle(
                              color: Color(0xFF667268),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        key: const Key('generate-trip-share-image'),
                        onPressed: _generating ? null : _generate,
                        icon: _generating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.image_outlined),
                        label: Text(
                          _generating
                              ? '生成中'
                              : _generatedImage == null
                              ? '生成分享图'
                              : '重新生成',
                        ),
                      ),
                    ],
                  ),
                ),
          );
        },
      ),
    );
  }
}
