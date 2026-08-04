import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kw_amap_map/kw_amap_map.dart';
import 'package:xingshe/core/map/map_provider.dart';

void main() {
  testWidgets('Android provider reports a missing AMap key', (tester) async {
    const scene = MapScene(
      center: MapCoordinate(latitude: 30.2741, longitude: 120.1551),
      markers: [
        MapMarker(
          id: 'spot-1',
          position: MapCoordinate(latitude: 30.25, longitude: 120.16),
        ),
      ],
      polylines: [
        MapPolyline(
          id: 'trip-1',
          points: [
            MapCoordinate(latitude: 30.25, longitude: 120.16),
            MapCoordinate(latitude: 30.26, longitude: 120.17),
          ],
        ),
      ],
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = container.read(mapProviderProvider);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) => provider.buildMap(context, scene)),
      ),
    );

    expect(find.byKey(const Key('amap-missing-key')), findsOneWidget);
    expect(find.text('尚未配置高德地图 Android Key'), findsOneWidget);
    expect(provider, isA<MapProvider>());
  });

  testWidgets('mock provider remains available for isolated tests', (
    tester,
  ) async {
    const provider = MockMapProvider();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => provider.buildMap(
            context,
            const MapScene(
              center: MapCoordinate(latitude: 30.2741, longitude: 120.1551),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('mock-map-provider')), findsOneWidget);
  });

  test(
    'configured Android provider creates a privacy-compliant AMap widget',
    () {
      const provider = AndroidMapProvider(configured: true);
      final widget = provider.buildMap(
        TestBuildContext(),
        const MapScene(
          center: MapCoordinate(latitude: 30.2741, longitude: 120.1551),
        ),
      );

      expect(widget, isA<AMapWidget>());
      final map = widget as AMapWidget;
      expect(map.apiKey, isNull);
      expect(
        map.privacyStatement,
        const AMapPrivacyStatement(
          hasContains: true,
          hasShow: true,
          hasAgree: true,
        ),
      );
    },
  );

  testWidgets('consent gate does not build a map before agreement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var granted = false;
    var declined = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapConsentStoreProvider.overrideWithValue(
            MapConsentStore.testing(
              () async => false,
              () async => granted = true,
            ),
          ),
        ],
        child: MaterialApp(
          home: MapConsentGate(
            mapProvider: const MockMapProvider(),
            scene: const MapScene(
              center: MapCoordinate(latitude: 30.2741, longitude: 120.1551),
            ),
            onDecline: () => declined = true,
            onPrivacy: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('amap-consent-ungranted')), findsOneWidget);
    expect(find.byKey(const Key('mock-map-provider')), findsNothing);
    expect(find.text('查看隐私说明'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('不同意'));
    expect(declined, isTrue);
    expect(granted, isFalse);
    expect(find.byKey(const Key('mock-map-provider')), findsNothing);
  });

  testWidgets('consent is persisted before the map is built', (tester) async {
    final write = Completer<void>();
    var writeStarted = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapConsentStoreProvider.overrideWithValue(
            MapConsentStore.testing(() async => false, () {
              writeStarted = true;
              return write.future;
            }),
          ),
        ],
        child: MaterialApp(
          home: MapConsentGate(
            mapProvider: const MockMapProvider(),
            scene: const MapScene(
              center: MapCoordinate(latitude: 30.2741, longitude: 120.1551),
            ),
            onDecline: () {},
            onPrivacy: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('同意并继续'));
    await tester.pump();

    expect(writeStarted, isTrue);
    expect(find.byKey(const Key('amap-consent-granting')), findsOneWidget);
    expect(find.text('正在保存同意状态'), findsOneWidget);
    expect(find.byKey(const Key('mock-map-provider')), findsNothing);

    write.complete();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('amap-consent-granted')), findsOneWidget);
    expect(find.byKey(const Key('mock-map-provider')), findsOneWidget);
    expect(find.text('已同意 · 地图隐私设置已保存'), findsOneWidget);
  });
}

class TestBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
