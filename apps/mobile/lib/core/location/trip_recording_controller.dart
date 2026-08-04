import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/local_database.dart';
import 'location_bridge.dart';
import 'track_synchronizer.dart';

final tripRecordingControllerProvider = Provider<TripRecordingController>(
  (ref) => TripRecordingController(
    database: ref.watch(localTripDatabaseProvider),
    locationBridge: ref.watch(locationBridgeProvider),
    synchronizer: ref.watch(trackSynchronizerProvider),
  ),
);

class TripRecordingController {
  const TripRecordingController({
    required this.database,
    required this.locationBridge,
    required this.synchronizer,
  });

  final LocalTripDatabase database;
  final LocationBridge locationBridge;
  final TrackSynchronizer synchronizer;

  Future<void> createAndStart({
    required String id,
    required String title,
    String? spotID,
    DateTime? startedAt,
  }) async {
    final name = title.trim();
    if (id.isEmpty || name.isEmpty) throw ArgumentError('行摄标题不能为空');
    final now = (startedAt ?? DateTime.now()).toUtc();
    await database
        .into(database.localTrips)
        .insert(
          LocalTripsCompanion.insert(
            id: id,
            spotId: Value(spotID),
            title: name,
            startedAt: now,
            status: 'draft',
            createdAt: now,
            updatedAt: now,
          ),
        );
    try {
      await start(id);
    } on Object {
      await (database.delete(
        database.localTrips,
      )..where((row) => row.id.equals(id))).go();
      rethrow;
    }
  }

  Future<void> start(
    String tripID, {
    Duration interval = const Duration(seconds: 5),
    double minDistanceMeters = 10,
  }) async {
    final trip = await _require(tripID, {'draft'});
    if (await _activeTrip(exceptID: tripID) != null) {
      throw StateError('已有进行中的行摄');
    }
    await locationBridge.start(
      tripID: tripID,
      interval: interval,
      minDistanceMeters: minDistanceMeters,
    );
    await _update(trip, 'recording');
  }

  Future<void> pause(String tripID) async {
    final trip = await _require(tripID, {'recording'});
    await locationBridge.pause();
    await _update(trip, 'paused');
  }

  Future<void> resume(String tripID) async {
    final trip = await _require(tripID, {'paused'});
    await locationBridge.resume();
    await _update(trip, 'recording');
  }

  Future<void> complete(String tripID, {DateTime? endedAt}) async {
    final trip = await _require(tripID, {'recording', 'paused'});
    await locationBridge.stop();
    await synchronizer.synchronize(tripID: tripID);
    final finishedAt = (endedAt ?? DateTime.now()).toUtc();
    await (database.update(
      database.localTrips,
    )..where((row) => row.id.equals(trip.id))).write(
      LocalTripsCompanion(
        status: const Value('completed'),
        endedAt: Value(finishedAt),
        updatedAt: Value(finishedAt),
      ),
    );
  }

  Future<LocalTrip?> restore() async {
    final trip = await _activeTrip();
    if (trip == null) return null;

    final nativeStatus = await locationBridge.status();
    if (trip.status == 'recording') {
      if (nativeStatus == 'idle') {
        await locationBridge.start(tripID: trip.id);
      } else {
        await locationBridge.resume();
      }
    } else if (nativeStatus == 'idle') {
      await locationBridge.start(tripID: trip.id);
      await locationBridge.pause();
    } else {
      await locationBridge.pause();
    }
    return trip;
  }

  Future<LocalTrip> _require(String tripID, Set<String> allowed) async {
    final trip = await (database.select(
      database.localTrips,
    )..where((row) => row.id.equals(tripID))).getSingleOrNull();
    if (trip == null || !allowed.contains(trip.status)) {
      throw StateError('当前行摄状态不允许此操作');
    }
    return trip;
  }

  Future<LocalTrip?> _activeTrip({String? exceptID}) =>
      (database.select(database.localTrips)
            ..where(
              (row) =>
                  row.status.isIn(const ['recording', 'paused']) &
                  (exceptID == null
                      ? const Constant(true)
                      : row.id.equals(exceptID).not()),
            )
            ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> _update(LocalTrip trip, String status) async {
    final now = DateTime.now().toUtc();
    await (database.update(
      database.localTrips,
    )..where((row) => row.id.equals(trip.id))).write(
      LocalTripsCompanion(status: Value(status), updatedAt: Value(now)),
    );
  }
}
