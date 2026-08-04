import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xingshe/core/auth/auth_session.dart';
import 'package:xingshe/core/auth/token_store.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/location/location_bridge.dart';
import 'package:xingshe/core/location/track_synchronizer.dart';
import 'package:xingshe/core/map/map_provider.dart';
import 'package:xingshe/core/permissions/app_permissions.dart';
import 'package:xingshe/features/spots/spot_list_page.dart';
import 'package:xingshe/main.dart';

void main() {
  testWidgets('creates and starts a trip after location consent', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final database = LocalTripDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    var nativeStatus = 'idle';
    final bridge = LocationBridge.testing((method, _) async {
      if (method == 'getPendingTrackPoints') return <Object?>[];
      if (method == 'getTrackingStatus') return {'status': nativeStatus};
      if (method == 'startLocationTracking') nativeStatus = 'recording';
      return null;
    }, Stream.empty);
    final store = TokenStore.testing(
      read: (_) async => null,
      write: (_, _) async {},
      delete: (_) async {},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          mapConsentStoreProvider.overrideWithValue(
            MapConsentStore.testing(() async => false, () async {}),
          ),
          localTripDatabaseProvider.overrideWithValue(database),
          locationBridgeProvider.overrideWithValue(bridge),
          loadSpotsProvider.overrideWithValue(
            ({keyword = '', page = 1, pageSize = 10}) async => SpotPage(
              items: const [
                ShootingSpot(
                  id: 'spot-1',
                  name: '测试机位',
                  description: '测试数据',
                  latitude: 0,
                  longitude: 0,
                  coordinateSystem: 'GCJ02',
                  tags: [],
                  isFavorited: false,
                ),
              ],
              page: page,
              pageSize: pageSize,
              total: 1,
            ),
          ),
          permissionStatusReaderProvider.overrideWithValue(
            (_) async => PermissionStatus.denied,
          ),
          permissionRequesterProvider.overrideWithValue(
            (_) async => PermissionStatus.granted,
          ),
        ],
        child: const XingSheApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('行摄'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-trip-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('trip-title-field')),
      '  城市追光  ',
    );
    await tester.tap(find.byKey(const Key('trip-spot-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试机位'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('trip-continue-button')));
    await tester.pumpAndSettle();
    expect(find.text('允许记录行摄轨迹'), findsOneWidget);

    await tester.tap(find.text('允许定位'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('trip-active-page')), findsOneWidget);
    final trip = await database.select(database.localTrips).getSingle();
    expect(trip.title, '城市追光');
    expect(trip.spotId, 'spot-1');
    expect(trip.status, 'recording');
    expect(nativeStatus, 'recording');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.takeException(), isNull);
  });
}
