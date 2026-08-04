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
    expect(source, contains('Intent.ACTION_OPEN_DOCUMENT'));
    expect(source, contains('Intent.EXTRA_ALLOW_MULTIPLE'));
    expect(source, contains('takePersistableUriPermission'));
    expect(source, isNot(contains('copyTo(')));
    expect(source, isNot(contains('android.util.Log')));
  });

  test(
    'imports multiple persistent content URIs without copying files',
    () async {
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
              status: 'paused',
              createdAt: now,
              updatedAt: now,
            ),
          );
      var nextID = 0;
      final controller = TripPhotoController(
        database: database,
        mediaBridge: MediaBridge.testing(
          () async => null,
          () async => [
            {
              'uri': 'content://gallery/one',
              'taken_at': now.millisecondsSinceEpoch,
            },
            {
              'uri': 'content://gallery/two',
              'taken_at': now.millisecondsSinceEpoch,
            },
          ],
        ),
        newID: () => 'gallery-${nextID++}',
      );

      expect(await controller.importPhotos('trip-1'), 2);
      final photos = await database.select(database.localTripPhotos).get();
      expect(photos, hasLength(2));
      expect(photos.every((photo) => photo.photoSource == 'gallery'), isTrue);
      expect(
        photos.every((photo) => photo.filePath.startsWith('content://')),
        isTrue,
      );
    },
  );

  test('cancelling gallery selection leaves the trip unchanged', () async {
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
      mediaBridge: MediaBridge.testing(() async => null),
    );

    expect(await controller.importPhotos('trip-1'), 0);
    expect(await database.select(database.localTripPhotos).get(), isEmpty);
  });
}
