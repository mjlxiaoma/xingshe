import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/location/track_synchronizer.dart';
import 'package:xingshe/core/media/media_bridge.dart';
import 'package:xingshe/core/media/trip_photo_controller.dart';
import 'package:xingshe/features/trips/trip_photo_gallery_page.dart';

void main() {
  testWidgets('previews photos and keeps imported originals outside deletion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
            endedAt: Value(now.add(const Duration(hours: 1))),
            status: 'completed',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database.batch((batch) {
      batch.insertAll(database.localTripPhotos, [
        _photo('camera', 'camera', 'content://camera/photo', now),
        _photo(
          'gallery',
          'gallery',
          'content://gallery/photo',
          now.add(const Duration(minutes: 1)),
        ),
      ]);
    });
    final deleted = <String>[];
    final bridge = MediaBridge.testing(
      () async => null,
      null,
      (_, _) async => base64Decode(_pixel),
      (uri) async => deleted.add(uri),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localTripDatabaseProvider.overrideWithValue(database),
          mediaBridgeProvider.overrideWithValue(bridge),
        ],
        child: const MaterialApp(home: TripPhotoGalleryPage(tripID: 'trip-1')),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('照片保存在设备本地，不会自动上传'), findsOneWidget);
    expect(find.text('行摄拍摄'), findsOneWidget);
    expect(find.text('相册导入'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trip-photo-gallery')));
    await _pumpFrames(tester);
    expect(find.byKey(const Key('trip-photo-preview')), findsOneWidget);
    await tester.tap(find.byKey(const Key('preview-delete-photo')));
    await _pumpFrames(tester);
    expect(find.textContaining('来自系统相册'), findsOneWidget);
    expect(find.byKey(const Key('delete-camera-original')), findsNothing);
    await tester.tap(find.byKey(const Key('remove-photo-association')));
    await _pumpFrames(tester);
    expect(deleted, isEmpty);
    expect(find.byKey(const Key('trip-photo-gallery')), findsNothing);

    await tester.tap(find.byKey(const Key('delete-photo-camera')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('delete-camera-original')));
    await _pumpFrames(tester);
    expect(find.text('确认删除系统相册原图？'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-delete-camera-original')));
    await _pumpFrames(tester);

    expect(deleted, ['content://camera/photo']);
    expect(find.byKey(const Key('trip-photo-gallery-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

LocalTripPhotosCompanion _photo(
  String id,
  String source,
  String uri,
  DateTime takenAt,
) => LocalTripPhotosCompanion.insert(
  id: id,
  tripId: 'trip-1',
  photoSource: Value(source),
  filePath: uri,
  takenAt: takenAt,
  createdAt: takenAt,
);

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

const _pixel =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
