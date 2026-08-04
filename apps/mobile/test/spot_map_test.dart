import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/map/map_provider.dart';
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
