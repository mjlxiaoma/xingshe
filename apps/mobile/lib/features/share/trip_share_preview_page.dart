import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/local_database.dart';
import '../../core/location/track_synchronizer.dart';
import 'trip_share_card.dart';

class TripSharePreviewPage extends ConsumerWidget {
  const TripSharePreviewPage({super.key, required this.tripID});

  final String tripID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(localTripDatabaseProvider);
    final trip = (database.select(
      database.localTrips,
    )..where((row) => row.id.equals(tripID))).watchSingleOrNull();
    final tracks =
        (database.select(database.localTrackPoints)
              ..where((row) => row.tripId.equals(tripID))
              ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]))
            .watch();
    final photos = (database.select(
      database.localTripPhotos,
    )..where((row) => row.tripId.equals(tripID))).watch();
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
                        child: TripShareCard(
                          model: TripShareCardModel.fromLocal(
                            trip: value,
                            tracks: trackSnapshot.data ?? const [],
                            photoCount: photoSnapshot.data?.length ?? 0,
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
                    ],
                  ),
                ),
          );
        },
      ),
    );
  }
}
