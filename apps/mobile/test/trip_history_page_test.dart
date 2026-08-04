import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/location/track_synchronizer.dart';
import 'package:xingshe/features/trips/trip_history_page.dart';

void main() {
  testWidgets('shows empty state then completed trips newest first', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = LocalTripDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final router = GoRouter(
      initialLocation: '/trips',
      routes: [
        GoRoute(path: '/trips', builder: (_, _) => const TripHistoryPage()),
        GoRoute(
          path: '/trips/:tripId',
          builder: (_, state) =>
              Scaffold(body: Text('detail-${state.pathParameters['tripId']}')),
        ),
        GoRoute(path: '/trip', builder: (_, _) => const SizedBox.shrink()),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localTripDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await _pumpFrames(tester);
    expect(find.byKey(const Key('trip-history-empty')), findsOneWidget);

    final older = DateTime.utc(2026, 7, 20, 6);
    final newer = DateTime.utc(2026, 7, 28, 17, 42);
    await database.batch((batch) {
      batch.insertAll(database.localTrips, [
        _trip('older', '北山街晨雾', older, 3600),
        _trip('newer', '滨江追光', newer, 4820),
        _trip('active', '进行中', newer, 0, status: 'recording'),
      ]);
    });
    await _pumpFrames(tester);

    expect(find.text('进行中'), findsNothing);
    expect(find.byKey(const Key('trip-history-cover')), findsNWidgets(2));
    expect(find.text('4.82 km'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('滨江追光')).dy,
      lessThan(tester.getTopLeft(find.text('北山街晨雾')).dy),
    );

    await tester.tap(find.byKey(const Key('trip-history-newer')));
    await _pumpFrames(tester);
    expect(find.text('detail-newer'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}

LocalTripsCompanion _trip(
  String id,
  String title,
  DateTime startedAt,
  double distance, {
  String status = 'completed',
}) => LocalTripsCompanion.insert(
  id: id,
  title: title,
  startedAt: startedAt,
  status: status,
  distanceMeters: Value(distance),
  endedAt: status == 'completed'
      ? Value(startedAt.add(const Duration(hours: 1)))
      : const Value.absent(),
  createdAt: startedAt,
  updatedAt: startedAt,
);

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}
