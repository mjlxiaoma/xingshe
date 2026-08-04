import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/location/location_bridge.dart';
import 'package:xingshe/core/location/track_synchronizer.dart';

void main() {
  test('retries native cleanup without duplicating Drift points', () async {
    final database = LocalTripDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.utc(2026, 8, 4);
    await database
        .into(database.localTrips)
        .insert(
          LocalTripsCompanion.insert(
            id: 'trip-1',
            title: 'trip-1',
            startedAt: now,
            status: 'recording',
            createdAt: now,
            updatedAt: now,
          ),
        );

    var failCleanup = true;
    final pending = <Map<String, Object?>>[
      {
        'type': 'location',
        'native_log_id': 'native-1',
        'trip_id': 'trip-1',
        'coordinate_system': 'WGS84',
        'latitude': 30.2,
        'longitude': 120.1,
        'accuracy': 8.0,
        'source': 'gps',
        'recorded_at': '2026-08-04T08:00:00.000Z',
      },
    ];
    final bridge = LocationBridge.testing((method, arguments) async {
      if (method == 'getPendingTrackPoints') return pending;
      if (method == 'clearPendingTrackPoints') {
        if (failCleanup) {
          failCleanup = false;
          throw const LocationBridgeException('LOCATION_IO', 'cleanup failed');
        }
        final ids =
            Map<String, Object?>.from(arguments as Map)['native_log_ids']!
                as List<String>;
        pending.removeWhere((point) => ids.contains(point['native_log_id']));
        return {'cleared': ids.length};
      }
      throw StateError('unexpected method: $method');
    }, Stream.empty);
    final synchronizer = TrackSynchronizer(
      database: database,
      locationBridge: bridge,
    );

    await expectLater(synchronizer.synchronize(), throwsA(isA<Exception>()));
    expect(
      await database.select(database.localTrackPoints).get(),
      hasLength(1),
    );

    expect(await synchronizer.synchronize(), 1);
    expect(
      await database.select(database.localTrackPoints).get(),
      hasLength(1),
    );
    expect(pending, isEmpty);
  });
}
