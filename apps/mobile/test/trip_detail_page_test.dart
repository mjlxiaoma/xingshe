import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/location/track_synchronizer.dart';
import 'package:xingshe/core/map/map_provider.dart';
import 'package:xingshe/features/trips/trip_detail_page.dart';

void main() {
  testWidgets('shows route endpoints statistics and an empty route state', (
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
            durationSeconds: const Value(3600),
            createdAt: startedAt,
            updatedAt: startedAt,
          ),
        );
    await database.batch((batch) {
      batch.insertAll(database.localTrackPoints, [
        _point(
          'second',
          30.21,
          120.11,
          startedAt.add(const Duration(minutes: 2)),
        ),
        _point('first', 30.20, 120.10, startedAt),
      ]);
      batch.insert(
        database.localTripPhotos,
        LocalTripPhotosCompanion.insert(
          id: 'photo-1',
          tripId: 'trip-1',
          filePath: 'content://test/photo',
          takenAt: startedAt,
          createdAt: startedAt,
        ),
      );
    });
    final map = _TestMapProvider();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localTripDatabaseProvider.overrideWithValue(database),
          mapProviderProvider.overrideWithValue(map),
          mapConsentStoreProvider.overrideWithValue(
            MapConsentStore.testing(() async => true, () async {}),
          ),
        ],
        child: const MaterialApp(home: TripDetailPage(tripID: 'trip-1')),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('滨江追光'), findsOneWidget);
    expect(find.text('4.82 km'), findsOneWidget);
    expect(find.text('01:00:00'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1 张'), findsOneWidget);
    expect(map.scene?.markers.map((marker) => marker.title), ['起点', '终点']);
    expect(map.scene?.polylines.single.points, hasLength(2));
    expect(map.scene?.polylines.single.points.first.latitude, 30.20);

    await database.delete(database.localTrackPoints).go();
    await _pumpFrames(tester);
    expect(find.byKey(const Key('trip-route-empty')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

LocalTrackPointsCompanion _point(
  String nativeID,
  double latitude,
  double longitude,
  DateTime recordedAt,
) => LocalTrackPointsCompanion.insert(
  tripId: 'trip-1',
  nativeLogId: Value(nativeID),
  coordinateSystem: const Value('WGS84'),
  latitude: latitude,
  longitude: longitude,
  recordedAt: recordedAt,
  source: 'gps',
);

class _TestMapProvider implements MapProvider {
  MapScene? scene;

  @override
  Widget buildMap(BuildContext context, MapScene value) {
    scene = value;
    return const ColoredBox(color: Color(0xFFEAF0E8));
  }
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}
