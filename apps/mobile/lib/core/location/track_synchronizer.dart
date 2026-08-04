import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/local_database.dart';
import 'location_bridge.dart';
import 'trip_statistics.dart';

final localTripDatabaseProvider = Provider<LocalTripDatabase>((ref) {
  final database = LocalTripDatabase();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final locationBridgeProvider = Provider<LocationBridge>(
  (_) => LocationBridge(),
);

final trackSynchronizerProvider = Provider<TrackSynchronizer>(
  (ref) => TrackSynchronizer(
    database: ref.watch(localTripDatabaseProvider),
    locationBridge: ref.watch(locationBridgeProvider),
  ),
);

class TrackSynchronizer {
  const TrackSynchronizer({
    required this.database,
    required this.locationBridge,
  });

  final LocalTripDatabase database;
  final LocationBridge locationBridge;

  Future<int> synchronize({String? tripID}) async {
    final points = await locationBridge.pendingPoints(tripID: tripID);
    if (points.isEmpty) return 0;

    final nativeLogIDs = points.map((point) => point.nativeLogID).toList();
    late final List<String> clearableIDs;
    await database.transaction(() async {
      final tripIDs = points.map((point) => point.tripID).toSet().toList();
      final trips = await (database.select(
        database.localTrips,
      )..where((row) => row.id.isIn(tripIDs))).get();
      final statuses = {for (final trip in trips) trip.id: trip.status};
      final completedIDs = <String>[];
      for (final point in points) {
        final status = statuses[point.tripID];
        if (status == null) continue;
        if (status == 'completed') {
          completedIDs.add(point.nativeLogID);
          continue;
        }
        await database
            .into(database.localTrackPoints)
            .insert(
              LocalTrackPointsCompanion.insert(
                tripId: point.tripID,
                nativeLogId: Value(point.nativeLogID),
                coordinateSystem: Value(point.coordinateSystem),
                latitude: point.latitude,
                longitude: point.longitude,
                altitude: Value(point.altitude),
                accuracy: Value(point.accuracy),
                speed: Value(point.speed),
                bearing: Value(point.bearing),
                recordedAt: point.recordedAt,
                source: point.source,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      final persisted = await (database.select(
        database.localTrackPoints,
      )..where((row) => row.nativeLogId.isIn(nativeLogIDs))).get();
      clearableIDs = {
        ...completedIDs,
        ...persisted.map((point) => point.nativeLogId).whereType<String>(),
      }.toList(growable: false);
      for (final tripID in tripIDs) {
        if (statuses[tripID] != null && statuses[tripID] != 'completed') {
          await refreshTripDistance(database, tripID);
        }
      }
    });

    return clearableIDs.isEmpty
        ? 0
        : locationBridge.clearPendingPoints(clearableIDs);
  }
}
