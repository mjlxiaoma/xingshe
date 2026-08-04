import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/location/track_synchronizer.dart';
import 'package:xingshe/features/share/trip_share_image.dart';
import 'package:xingshe/features/share/trip_share_card.dart';
import 'package:xingshe/features/share/trip_share_preview_page.dart';

void main() {
  testWidgets('renders a privacy-safe share card without photos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = LocalTripDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final startedAt = DateTime.utc(2026, 7, 28, 9);
    const privateAddress = '测试市示例路 123 号';
    const privateEmail = 'privacy-test@example.invalid';
    const fakeToken = 'test.header.signature';
    await database
        .into(database.localSpotCache)
        .insert(
          LocalSpotCacheCompanion.insert(
            spotId: 'spot-private',
            name: '不公开机位',
            description: const Value('$privateEmail $fakeToken'),
            latitude: 0,
            longitude: 0,
            address: const Value(privateAddress),
            updatedAt: startedAt,
          ),
        );
    await database
        .into(database.localTrips)
        .insert(
          LocalTripsCompanion.insert(
            id: 'trip-1',
            spotId: const Value('spot-private'),
            title: '滨江追光',
            startedAt: startedAt,
            endedAt: Value(startedAt.add(const Duration(hours: 1))),
            status: 'completed',
            distanceMeters: const Value(4820),
            durationSeconds: const Value(5058),
            createdAt: startedAt,
            updatedAt: startedAt,
          ),
        );
    await database.batch((batch) {
      batch.insertAll(database.localTrackPoints, [
        _point(30.123456, 120.123456, startedAt),
        _point(
          30.133456,
          120.143456,
          startedAt.add(const Duration(minutes: 1)),
        ),
      ]);
    });
    final model = TripShareCardModel.fromLocal(
      trip: await (database.select(
        database.localTrips,
      )..where((row) => row.id.equals('trip-1'))).getSingle(),
      tracks: await (database.select(
        database.localTrackPoints,
      )..where((row) => row.tripId.equals('trip-1'))).get(),
      photoCount: 0,
    );
    expect(model.route, hasLength(2));
    expect(
      model.route.every(
        (point) => point.x >= 0 && point.x <= 1 && point.y >= 0 && point.y <= 1,
      ),
      isTrue,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localTripDatabaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: TripSharePreviewPage(tripID: 'trip-1')),
      ),
    );
    await _pumpFrames(tester);

    expect(find.byKey(const Key('trip-share-card')), findsOneWidget);
    expect(find.text('滨江追光'), findsOneWidget);
    expect(find.text('4.82 km'), findsOneWidget);
    expect(find.text('01:24'), findsOneWidget);
    expect(find.text('0 张'), findsOneWidget);
    expect(find.byKey(const Key('trip-share-route')), findsOneWidget);
    expect(find.text('已隐藏精确地址与个人信息'), findsOneWidget);
    expect(find.text('图片仅在本机生成，不上传服务器'), findsOneWidget);
    expect(find.textContaining('30.123456'), findsNothing);
    expect(find.textContaining('120.123456'), findsNothing);
    expect(find.text(privateAddress), findsNothing);
    expect(find.textContaining(privateEmail), findsNothing);
    expect(find.textContaining(fakeToken), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('generates the share image locally and reports failures', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = await _database();
    addTearDown(database.close);
    var generated = false;
    String? sharedPath;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localTripDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: TripSharePreviewPage(
            tripID: 'trip-1',
            generator: (_) async {
              generated = true;
              return File('temporary-trip.png');
            },
            shareImage: (path) async => sharedPath = path,
          ),
        ),
      ),
    );
    await _pumpFrames(tester);

    await tester.tap(find.byKey(const Key('generate-trip-share-image')));
    await tester.pumpAndSettle();
    expect(generated, isTrue);
    expect(find.text('分享图已在本机生成'), findsOneWidget);
    expect(find.text('重新生成'), findsOneWidget);
    await tester.tap(find.byKey(const Key('share-trip-image')));
    await tester.pumpAndSettle();
    expect(sharedPath, 'temporary-trip.png');
    expect(tester.takeException(), isNull);
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .clearSnackBars();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localTripDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: TripSharePreviewPage(
            tripID: 'trip-1',
            generator: (_) async => throw StateError('encoding failed'),
          ),
        ),
      ),
    );
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('generate-trip-share-image')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('分享图生成失败，请重试'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  test('writes PNG bytes to a temporary directory', () async {
    final bytes = Uint8List.fromList(const [137, 80, 78, 71, 13, 10, 26, 10]);
    final image = await writeTripSharePng(bytes);
    addTearDown(() => image.parent.delete(recursive: true));
    expect(await image.readAsBytes(), bytes);
    expect(image.path, endsWith('trip.png'));
  });
}

Future<LocalTripDatabase> _database() async {
  final database = LocalTripDatabase.forTesting(NativeDatabase.memory());
  final startedAt = DateTime.utc(2026, 7, 28, 9);
  await database
      .into(database.localTrips)
      .insert(
        LocalTripsCompanion.insert(
          id: 'trip-1',
          title: '测试行程',
          startedAt: startedAt,
          status: 'completed',
          createdAt: startedAt,
          updatedAt: startedAt,
        ),
      );
  return database;
}

LocalTrackPointsCompanion _point(
  double latitude,
  double longitude,
  DateTime recordedAt,
) => LocalTrackPointsCompanion.insert(
  tripId: 'trip-1',
  latitude: latitude,
  longitude: longitude,
  recordedAt: recordedAt,
  source: 'gps',
);

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}
