import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/location/location_bridge.dart';
import 'package:xingshe/core/location/track_synchronizer.dart';
import 'package:xingshe/core/media/media_bridge.dart';
import 'package:xingshe/core/media/trip_photo_controller.dart';
import 'package:xingshe/core/permissions/app_permissions.dart';
import 'package:xingshe/features/trips/active_trip_page.dart';
import 'package:xingshe/features/trips/trip_detail_page.dart';

void main() {
  testWidgets('shows metrics and controls recording through completion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = LocalTripDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime.now().toUtc();
    await database
        .into(database.localTrips)
        .insert(
          LocalTripsCompanion.insert(
            id: 'trip-1',
            title: '城市追光',
            startedAt: now,
            status: 'recording',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.localTrackPoints)
        .insert(
          LocalTrackPointsCompanion.insert(
            tripId: 'trip-1',
            latitude: 0,
            longitude: 0,
            recordedAt: now,
            source: 'gps',
          ),
        );
    await database
        .into(database.localTripPhotos)
        .insert(
          LocalTripPhotosCompanion.insert(
            id: 'photo-1',
            tripId: 'trip-1',
            filePath: 'content://test/photo',
            takenAt: now,
            createdAt: now,
          ),
        );
    var nativeStatus = 'recording';
    final requestedPermissions = <AppPermission>[];
    final bridge = LocationBridge.testing((method, _) async {
      switch (method) {
        case 'pauseLocationTracking':
          nativeStatus = 'paused';
          return null;
        case 'resumeLocationTracking':
          nativeStatus = 'recording';
          return null;
        case 'stopLocationTracking':
          nativeStatus = 'idle';
          return null;
        case 'getPendingTrackPoints':
          return <Object?>[];
      }
      return null;
    }, Stream.empty);
    final router = GoRouter(
      initialLocation: '/active',
      routes: [
        GoRoute(
          path: '/trips/:tripId',
          builder: (_, state) =>
              TripDetailPage(tripID: state.pathParameters['tripId']!),
        ),
        GoRoute(
          path: '/active',
          builder: (_, _) => const ActiveTripPage(tripID: 'trip-1'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localTripDatabaseProvider.overrideWithValue(database),
          locationBridgeProvider.overrideWithValue(bridge),
          mediaBridgeProvider.overrideWithValue(
            MediaBridge.testing(
              () async => {
                'uri': 'content://media/external/images/media/captured',
                'taken_at': now.millisecondsSinceEpoch,
              },
            ),
          ),
          permissionRequesterProvider.overrideWithValue((permission) async {
            requestedPermissions.add(permission);
            return PermissionStatus.granted;
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await _pumpFrames(tester);

    expect(find.text('城市追光'), findsOneWidget);
    final duration = tester.widget<Text>(
      find.byKey(const Key('trip-duration')),
    );
    expect(duration.data, matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')));
    expect(find.text('0 m'), findsOneWidget);
    expect(find.text('1 个'), findsOneWidget);
    expect(find.text('1 张'), findsOneWidget);
    expect(requestedPermissions, isEmpty);

    await tester.tap(find.byKey(const Key('trip-camera-button')));
    await _pumpFrames(tester);
    await tester.tap(find.text('拍照'));
    await _pumpFrames(tester);
    expect(requestedPermissions, [AppPermission.camera]);
    expect(find.text('2 张'), findsOneWidget);

    await tester.tap(find.byKey(const Key('trip-pause-resume-button')));
    await _pumpFrames(tester);
    expect(find.text('已暂停'), findsOneWidget);
    expect(nativeStatus, 'paused');

    await tester.tap(find.byKey(const Key('trip-pause-resume-button')));
    await _pumpFrames(tester);
    expect(find.text('正在记录'), findsOneWidget);
    expect(nativeStatus, 'recording');

    await tester.tap(find.byKey(const Key('trip-end-button')));
    await _pumpFrames(tester);
    await tester.tap(find.byKey(const Key('trip-confirm-end-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const Key('trip-detail-page')), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);
    expect(find.text('2 张'), findsOneWidget);
    expect(
      (await database.select(database.localTrips).getSingle()).status,
      'completed',
    );
    expect(nativeStatus, 'idle');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump();
}
