import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/location/track_synchronizer.dart';
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
    await database
        .into(database.localTrips)
        .insert(
          LocalTripsCompanion.insert(
            id: 'trip-1',
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
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
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
