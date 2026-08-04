import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:xingshe/core/map/map_provider.dart';
import 'package:xingshe/core/permissions/app_permissions.dart';
import 'package:xingshe/features/spots/spot_list_page.dart';
import 'package:xingshe/features/spots/spot_map_page.dart';

void main() {
  testWidgets('map markers use list data and show a summary when tapped', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final map = TestMapProvider();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapProviderProvider.overrideWithValue(map),
          mapConsentStoreProvider.overrideWithValue(
            MapConsentStore.testing(() async => true, () async {}),
          ),
          loadSpotsProvider.overrideWithValue(
            ({keyword = '', page = 1, pageSize = 10}) async => SpotPage(
              items: [_spot('1', '西湖日落'), _spot('2', '城市夜景')],
              page: 1,
              pageSize: pageSize,
              total: 2,
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SpotMapPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(map.scene?.markers.map((marker) => marker.title), ['西湖日落', '城市夜景']);
    tester
        .widget<TextButton>(find.byKey(const Key('marker-1')))
        .onPressed
        ?.call();
    await tester.pump();
    final summary = find.byKey(const Key('map-spot-summary'));
    expect(summary, findsOneWidget);
    expect(
      find.descendant(of: summary, matching: find.text('西湖日落')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: summary, matching: find.text('杭州市')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'requests only foreground permission before loading nearby spots',
    (tester) async {
      final requested = <AppPermission>[];
      final map = TestMapProvider();
      double? latitude;
      double? longitude;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mapProviderProvider.overrideWithValue(map),
            mapConsentStoreProvider.overrideWithValue(
              MapConsentStore.testing(() async => true, () async {}),
            ),
            permissionRequesterProvider.overrideWithValue((permission) async {
              requested.add(permission);
              return PermissionStatus.granted;
            }),
            loadSpotsProvider.overrideWithValue(
              ({keyword = '', page = 1, pageSize = 10}) async => SpotPage(
                items: [_spot('default', '默认列表')],
                page: 1,
                pageSize: pageSize,
                total: 1,
              ),
            ),
            loadNearbySpotsProvider.overrideWithValue((lat, lon) async {
              latitude = lat;
              longitude = lon;
              return [_nearbySpot];
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: SpotMapPage())),
        ),
      );
      await tester.pumpAndSettle();

      expect(requested, isEmpty);
      expect(map.scene?.showUserLocation, isFalse);
      await tester.tap(find.byKey(const Key('nearby-spots-action')));
      await tester.pump();
      expect(requested, [AppPermission.location]);
      expect(map.scene?.showUserLocation, isTrue);

      map.scene?.onLocationChanged?.call(
        const MapCoordinate(latitude: 30.25, longitude: 120.16),
      );
      await tester.pumpAndSettle();
      expect(latitude, 30.25);
      expect(longitude, 120.16);
      expect(map.scene?.markers.single.title, '附近日落');
      expect(find.textContaining('距离仅供参考'), findsOneWidget);
    },
  );

  testWidgets('denied foreground permission keeps the default list', (
    tester,
  ) async {
    final requested = <AppPermission>[];
    final map = TestMapProvider();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapProviderProvider.overrideWithValue(map),
          mapConsentStoreProvider.overrideWithValue(
            MapConsentStore.testing(() async => true, () async {}),
          ),
          permissionRequesterProvider.overrideWithValue((permission) async {
            requested.add(permission);
            return PermissionStatus.denied;
          }),
          loadSpotsProvider.overrideWithValue(
            ({keyword = '', page = 1, pageSize = 10}) async => SpotPage(
              items: [_spot('default', '默认列表')],
              page: 1,
              pageSize: pageSize,
              total: 1,
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: SpotMapPage())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nearby-spots-action')));
    await tester.pump();

    expect(requested, [AppPermission.location]);
    expect(requested, isNot(contains(AppPermission.backgroundLocation)));
    expect(map.scene?.showUserLocation, isFalse);
    expect(map.scene?.markers.single.title, '默认列表');
    expect(find.text('未获得前台定位权限，继续显示默认列表'), findsOneWidget);
  });
}

class TestMapProvider implements MapProvider {
  MapScene? scene;

  @override
  Widget buildMap(BuildContext context, MapScene value) {
    scene = value;
    return ColoredBox(
      color: Colors.white,
      child: Column(
        children: value.markers
            .map(
              (marker) => TextButton(
                key: Key('marker-${marker.id}'),
                onPressed: () => value.onMarkerTap?.call(marker),
                child: Text(marker.title ?? marker.id),
              ),
            )
            .toList(),
      ),
    );
  }
}

ShootingSpot _spot(String id, String name) => ShootingSpot(
  id: id,
  name: name,
  description: '机位描述',
  latitude: 30.2,
  longitude: 120.1,
  coordinateSystem: 'GCJ02',
  address: '杭州市',
  tags: const ['日落'],
  isFavorited: false,
);

const _nearbySpot = ShootingSpot(
  id: 'nearby',
  name: '附近日落',
  description: '描述',
  latitude: 30.26,
  longitude: 120.17,
  coordinateSystem: 'GCJ02',
  address: '杭州市',
  tags: ['日落'],
  isFavorited: false,
  distanceMeters: 1200,
);
