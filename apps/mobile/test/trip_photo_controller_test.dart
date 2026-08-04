import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/media/media_bridge.dart';
import 'package:xingshe/core/media/trip_photo_controller.dart';

void main() {
  test('attaches a captured content URI to the active trip', () async {
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
    final controller = TripPhotoController(
      database: database,
      mediaBridge: MediaBridge.testing(
        () async => {
          'uri': 'content://media/external/images/media/test',
          'taken_at': now.millisecondsSinceEpoch,
        },
      ),
      newID: () => 'photo-1',
    );

    final photo = await controller.capture('trip-1');

    expect(photo?.tripId, 'trip-1');
    expect(photo?.photoSource, 'camera');
    expect(photo?.filePath, startsWith('content://'));
  });

  test('Android capture writes through MediaStore without logging paths', () {
    final source = File(
      'android/app/src/main/kotlin/com/xingshe/app/PhotoCaptureBridge.kt',
    ).readAsStringSync();

    expect(source, contains('MediaStore.Images.Media.RELATIVE_PATH'));
    expect(source, contains('Environment.DIRECTORY_PICTURES}/XingShe'));
    expect(source, contains('MediaStore.EXTRA_OUTPUT'));
    expect(source, isNot(contains('android.util.Log')));
  });
}
