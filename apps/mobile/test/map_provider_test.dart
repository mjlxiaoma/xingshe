import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/map/map_provider.dart';

void main() {
  testWidgets('mock map provider renders an abstract map scene', (
    tester,
  ) async {
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

    expect(find.byKey(const Key('mock-map-provider')), findsOneWidget);
    expect(provider, isA<MapProvider>());
  });
}
