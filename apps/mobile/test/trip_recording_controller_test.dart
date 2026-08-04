import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/location/location_bridge.dart';
import 'package:xingshe/core/location/track_synchronizer.dart';
import 'package:xingshe/core/location/trip_recording_controller.dart';

void main() {
  late LocalTripDatabase database;
  late List<Map<String, Object?>> pending;
  late String nativeStatus;
  late LocationBridge bridge;
  late TripRecordingController controller;

  setUp(() {
    database = LocalTripDatabase.forTesting(NativeDatabase.memory());
    pending = [];
    nativeStatus = 'idle';
    bridge = LocationBridge.testing((method, arguments) async {
      switch (method) {
        case 'startLocationTracking':
        case 'resumeLocationTracking':
          nativeStatus = 'recording';
          return null;
        case 'pauseLocationTracking':
          nativeStatus = 'paused';
          return null;
        case 'stopLocationTracking':
          nativeStatus = 'idle';
          return null;
        case 'getTrackingStatus':
          return {'status': nativeStatus};
        case 'getPendingTrackPoints':
          return pending;
        case 'clearPendingTrackPoints':
          final ids =
              Map<String, Object?>.from(arguments as Map)['native_log_ids']!
                  as List<String>;
          pending.removeWhere((point) => ids.contains(point['native_log_id']));
          return {'cleared': ids.length};
      }
      return null;
    }, Stream.empty);
    final synchronizer = TrackSynchronizer(
      database: database,
      locationBridge: bridge,
    );
    controller = TripRecordingController(
      database: database,
      locationBridge: bridge,
      synchronizer: synchronizer,
    );
  });

  tearDown(() => database.close());

  test('supports recording transitions and blocks completed trips', () async {
    await _insertTrip(database, 'trip-1', 'draft');

    await controller.start('trip-1');
    expect(await _status(database, 'trip-1'), 'recording');
    await controller.pause('trip-1');
    expect(await _status(database, 'trip-1'), 'paused');
    await controller.resume('trip-1');
    expect(await _status(database, 'trip-1'), 'recording');

    final startedAt = DateTime.utc(2026, 8, 4, 8);
    await database.batch((batch) {
      batch.insertAll(database.localTrackPoints, [
        LocalTrackPointsCompanion.insert(
          tripId: 'trip-1',
          latitude: 30.2,
          longitude: 120.1,
          accuracy: const Value(5),
          recordedAt: startedAt,
          source: 'gps',
        ),
        LocalTrackPointsCompanion.insert(
          tripId: 'trip-1',
          latitude: 30.201,
          longitude: 120.1,
          accuracy: const Value(5),
          recordedAt: startedAt.add(const Duration(minutes: 1)),
          source: 'gps',
        ),
      ]);
    });

    final endedAt = DateTime.utc(2026, 8, 4, 9);
    await controller.complete('trip-1', endedAt: endedAt);
    final completed = await database.select(database.localTrips).getSingle();
    expect(completed.status, 'completed');
    expect(completed.endedAt?.toUtc(), endedAt);
    expect(completed.distanceMeters, greaterThan(100));
    expect(nativeStatus, 'idle');
    await expectLater(controller.resume('trip-1'), throwsStateError);

    pending.add(_point('trip-1', 'late-native'));
    expect(await controller.synchronizer.synchronize(), 1);
    final tracks = await database.select(database.localTrackPoints).get();
    expect(tracks, hasLength(2));
    expect(tracks.any((point) => point.nativeLogId == 'late-native'), isFalse);
    expect(pending, isEmpty);
  });

  test('restores a paused trip after the native service is lost', () async {
    await _insertTrip(database, 'trip-1', 'paused');

    final restored = await controller.restore();

    expect(restored?.id, 'trip-1');
    expect(nativeStatus, 'paused');
  });

  test('excludes paused time from the persisted duration', () async {
    final startedAt = DateTime.utc(2026, 8, 4, 8);
    await _insertTrip(database, 'trip-1', 'recording');
    await (database.update(database.localTrips)
          ..where((row) => row.id.equals('trip-1')))
        .write(LocalTripsCompanion(updatedAt: Value(startedAt)));

    await controller.pause(
      'trip-1',
      transitionedAt: startedAt.add(const Duration(seconds: 20)),
    );
    await controller.resume(
      'trip-1',
      transitionedAt: startedAt.add(const Duration(seconds: 50)),
    );
    await controller.complete(
      'trip-1',
      endedAt: startedAt.add(const Duration(seconds: 70)),
    );

    expect(
      (await database.select(database.localTrips).getSingle()).durationSeconds,
      40,
    );
  });

  test('native sticky service restores its persisted state', () {
    final source = File(
      'android/app/src/main/kotlin/com/xingshe/app/TripLocationService.kt',
    ).readAsStringSync();

    expect(source, contains('else -> restore()'));
    expect(source, contains('"recording" -> resume()'));
    expect(source, contains('"paused" -> pause()'));
    expect(source, contains('if (status() != "recording") return'));
  });
}

Future<void> _insertTrip(LocalTripDatabase database, String id, String status) {
  final now = DateTime.utc(2026, 8, 4);
  return database
      .into(database.localTrips)
      .insert(
        LocalTripsCompanion.insert(
          id: id,
          title: id,
          startedAt: now,
          status: status,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<String> _status(LocalTripDatabase database, String tripID) async =>
    (await (database.select(
      database.localTrips,
    )..where((row) => row.id.equals(tripID))).getSingle()).status;

Map<String, Object?> _point(String tripID, String nativeLogID) => {
  'type': 'location',
  'native_log_id': nativeLogID,
  'trip_id': tripID,
  'coordinate_system': 'WGS84',
  'latitude': 30.2,
  'longitude': 120.1,
  'accuracy': 8.0,
  'source': 'gps',
  'recorded_at': '2026-08-04T08:00:00.000Z',
};
