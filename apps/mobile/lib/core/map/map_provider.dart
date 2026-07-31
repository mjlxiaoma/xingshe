import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MapConfig {
  static const amapAndroidKey = String.fromEnvironment('AMAP_ANDROID_KEY');
}

@immutable
class MapCoordinate {
  const MapCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

@immutable
class MapMarker {
  const MapMarker({required this.id, required this.position, this.title});

  final String id;
  final MapCoordinate position;
  final String? title;
}

@immutable
class MapPolyline {
  const MapPolyline({required this.id, required this.points});

  final String id;
  final List<MapCoordinate> points;
}

@immutable
class MapScene {
  const MapScene({
    required this.center,
    this.zoom = 13,
    this.markers = const [],
    this.polylines = const [],
    this.onMarkerTap,
  });

  final MapCoordinate center;
  final double zoom;
  final List<MapMarker> markers;
  final List<MapPolyline> polylines;
  final ValueChanged<MapMarker>? onMarkerTap;
}

abstract interface class MapProvider {
  Widget buildMap(BuildContext context, MapScene scene);
}

final mapProviderProvider = Provider<MapProvider>(
  (_) => const MockMapProvider(),
);

class MockMapProvider implements MapProvider {
  const MockMapProvider();

  @override
  Widget buildMap(BuildContext context, MapScene scene) {
    return const ColoredBox(
      key: Key('mock-map-provider'),
      color: Color(0xFFEAF0E8),
      child: Center(
        child: Icon(Icons.map_outlined, size: 64, color: Color(0xFF2D6B3F)),
      ),
    );
  }
}
