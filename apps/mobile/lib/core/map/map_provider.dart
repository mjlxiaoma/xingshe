import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kw_amap_base/kw_amap_base.dart' as amap_base;
import 'package:kw_amap_map/kw_amap_map.dart' as amap;

class MapConfig {
  static const amapAndroidKey = String.fromEnvironment('AMAP_ANDROID_KEY');

  static bool get isConfigured => amapAndroidKey.trim().isNotEmpty;
}

@immutable
class MapCoordinate {
  const MapCoordinate({
    required this.latitude,
    required this.longitude,
    this.system = MapCoordinateSystem.gcj02,
  });

  final double latitude;
  final double longitude;
  final MapCoordinateSystem system;
}

enum MapCoordinateSystem { wgs84, gcj02 }

MapCoordinateSystem mapCoordinateSystemFromAPI(String value) =>
    value == 'WGS84' ? MapCoordinateSystem.wgs84 : MapCoordinateSystem.gcj02;

class MapCoordinateConverter {
  static MapCoordinate toGCJ02(MapCoordinate coordinate) {
    if (coordinate.system == MapCoordinateSystem.gcj02 ||
        _outsideChina(coordinate)) {
      return MapCoordinate(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
      );
    }
    const earthRadius = 6378245.0;
    const eccentricity = 0.00669342162296594323;
    var latitudeOffset = _latitudeOffset(
      coordinate.longitude - 105,
      coordinate.latitude - 35,
    );
    var longitudeOffset = _longitudeOffset(
      coordinate.longitude - 105,
      coordinate.latitude - 35,
    );
    final radians = coordinate.latitude / 180 * math.pi;
    final magic = 1 - eccentricity * math.sin(radians) * math.sin(radians);
    final root = math.sqrt(magic);
    latitudeOffset =
        (latitudeOffset * 180) /
        ((earthRadius * (1 - eccentricity)) / (magic * root) * math.pi);
    longitudeOffset =
        (longitudeOffset * 180) /
        (earthRadius / root * math.cos(radians) * math.pi);
    return MapCoordinate(
      latitude: coordinate.latitude + latitudeOffset,
      longitude: coordinate.longitude + longitudeOffset,
    );
  }

  static bool _outsideChina(MapCoordinate coordinate) =>
      coordinate.longitude < 72.004 ||
      coordinate.longitude > 137.8347 ||
      coordinate.latitude < 0.8293 ||
      coordinate.latitude > 55.8271;

  static double _latitudeOffset(double x, double y) {
    var value =
        -100 +
        2 * x +
        3 * y +
        0.2 * y * y +
        0.1 * x * y +
        0.2 * math.sqrt(x.abs());
    value +=
        (20 * math.sin(6 * x * math.pi) + 20 * math.sin(2 * x * math.pi)) *
        2 /
        3;
    value +=
        (20 * math.sin(y * math.pi) + 40 * math.sin(y / 3 * math.pi)) * 2 / 3;
    return value +
        (160 * math.sin(y / 12 * math.pi) + 320 * math.sin(y * math.pi / 30)) *
            2 /
            3;
  }

  static double _longitudeOffset(double x, double y) {
    var value =
        300 + x + 2 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * math.sqrt(x.abs());
    value +=
        (20 * math.sin(6 * x * math.pi) + 20 * math.sin(2 * x * math.pi)) *
        2 /
        3;
    value +=
        (20 * math.sin(x * math.pi) + 40 * math.sin(x / 3 * math.pi)) * 2 / 3;
    return value +
        (150 * math.sin(x / 12 * math.pi) + 300 * math.sin(x / 30 * math.pi)) *
            2 /
            3;
  }
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
    this.showUserLocation = false,
    this.onLocationChanged,
  });

  final MapCoordinate center;
  final double zoom;
  final List<MapMarker> markers;
  final List<MapPolyline> polylines;
  final ValueChanged<MapMarker>? onMarkerTap;
  final bool showUserLocation;
  final ValueChanged<MapCoordinate>? onLocationChanged;
}

abstract interface class MapProvider {
  Widget buildMap(BuildContext context, MapScene scene);
}

class MapConsentStore {
  MapConsentStore({FlutterSecureStorage storage = const FlutterSecureStorage()})
    : this.testing(
        () async => await storage.read(key: _key) == 'granted',
        () => storage.write(key: _key, value: 'granted'),
      );

  MapConsentStore.testing(this._read, this._grant);

  static const _key = 'amap_privacy_consent';

  final Future<bool> Function() _read;
  final Future<void> Function() _grant;

  Future<bool> hasGranted() => _read();

  Future<void> grant() => _grant();
}

enum MapConsentStatus { notGranted, granting, granted }

final mapConsentStoreProvider = Provider<MapConsentStore>(
  (_) => MapConsentStore(),
);

final mapConsentProvider =
    AsyncNotifierProvider<MapConsentController, MapConsentStatus>(
      MapConsentController.new,
    );

class MapConsentController extends AsyncNotifier<MapConsentStatus> {
  @override
  Future<MapConsentStatus> build() async {
    final granted = await ref.read(mapConsentStoreProvider).hasGranted();
    return granted ? MapConsentStatus.granted : MapConsentStatus.notGranted;
  }

  Future<void> grant() async {
    state = const AsyncData(MapConsentStatus.granting);
    try {
      await ref.read(mapConsentStoreProvider).grant();
      state = const AsyncData(MapConsentStatus.granted);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

final mapProviderProvider = Provider<MapProvider>(
  (_) => const AndroidMapProvider(),
);

class AndroidMapProvider implements MapProvider {
  const AndroidMapProvider({this.configured});

  final bool? configured;

  @override
  Widget buildMap(BuildContext context, MapScene scene) {
    if (!(configured ?? MapConfig.isConfigured)) {
      return const ColoredBox(
        key: Key('amap-missing-key'),
        color: Color(0xFFEAF0E8),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.key_off, size: 48, color: Color(0xFF2D6B3F)),
                SizedBox(height: 12),
                Text(
                  '尚未配置高德地图 Android Key',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  '请通过 AMAP_ANDROID_KEY 本地编译参数配置',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF667268), fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final center = MapCoordinateConverter.toGCJ02(scene.center);
    return amap.AMapWidget(
      key: const Key('amap-map'),
      privacyStatement: const amap_base.AMapPrivacyStatement(
        hasContains: true,
        hasShow: true,
        hasAgree: true,
      ),
      initialCameraPosition: amap.CameraPosition(
        target: amap_base.LatLng(center.latitude, center.longitude),
        zoom: scene.zoom,
      ),
      markers: scene.markers.map((marker) {
        final position = MapCoordinateConverter.toGCJ02(marker.position);
        final nativeMarker = amap.Marker(
          position: amap_base.LatLng(position.latitude, position.longitude),
          infoWindow: amap.InfoWindow(title: marker.title),
          onTap: (_) => scene.onMarkerTap?.call(marker),
        );
        nativeMarker.setIdForCopy(marker.id);
        return nativeMarker;
      }).toSet(),
      myLocationStyleOptions: scene.showUserLocation
          ? amap.MyLocationStyleOptions(true)
          : null,
      onLocationChanged: scene.showUserLocation
          ? (location) => scene.onLocationChanged?.call(
              MapCoordinate(
                latitude: location.latLng.latitude,
                longitude: location.latLng.longitude,
              ),
            )
          : null,
      compassEnabled: true,
      scaleEnabled: true,
    );
  }
}

class MapConsentGate extends ConsumerWidget {
  const MapConsentGate({
    super.key,
    required this.mapProvider,
    required this.scene,
    required this.onDecline,
    required this.onPrivacy,
    this.mapOverlay,
  });

  final MapProvider mapProvider;
  final MapScene scene;
  final VoidCallback onDecline;
  final VoidCallback onPrivacy;
  final Widget? mapOverlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(mapConsentProvider)
        .when(
          loading: () => const _ConsentLoading(),
          error: (_, _) => _ConsentError(
            onDecline: onDecline,
            onRetry: () => ref.invalidate(mapConsentProvider),
          ),
          data: (status) => switch (status) {
            MapConsentStatus.notGranted => _ConsentPage(
              onDecline: onDecline,
              onPrivacy: onPrivacy,
              onGrant: () => ref.read(mapConsentProvider.notifier).grant(),
            ),
            MapConsentStatus.granting => _ConsentPage(
              granting: true,
              onDecline: onDecline,
              onPrivacy: onPrivacy,
              onGrant: () {},
            ),
            MapConsentStatus.granted => Stack(
              key: const Key('amap-consent-granted'),
              children: [
                Positioned.fill(child: mapProvider.buildMap(context, scene)),
                if (mapOverlay case final overlay?)
                  Positioned(left: 16, right: 16, top: 16, child: overlay),
                const Positioned(
                  left: 16,
                  bottom: 16,
                  child: _ConsentGrantedBadge(),
                ),
              ],
            ),
          },
        );
  }
}

class _ConsentLoading extends StatelessWidget {
  const _ConsentLoading();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    key: Key('amap-consent-loading'),
    color: Colors.white,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('正在检查地图隐私授权'),
        ],
      ),
    ),
  );
}

class _ConsentPage extends StatelessWidget {
  const _ConsentPage({
    required this.onDecline,
    required this.onPrivacy,
    required this.onGrant,
    this.granting = false,
  });

  final VoidCallback onDecline;
  final VoidCallback onPrivacy;
  final VoidCallback onGrant;
  final bool granting;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key(granting ? 'amap-consent-granting' : 'amap-consent-ungranted'),
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.outlined(
                    onPressed: granting ? null : onDecline,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: '返回',
                  ),
                ),
                const Text(
                  '地图与位置',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 112,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1E9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3322),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.explore_outlined,
                color: Color(0xFFD4A020),
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '使用地图前，请先了解位置数据',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            '行摄使用高德 Android SDK 展示地图。地图服务会处理必要的设备与地图交互信息；只有在你主动使用位置功能时，应用才会读取位置数据。',
            style: TextStyle(
              color: Color(0xFF667268),
              fontSize: 11,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          const _ConsentFacts(),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFFDDE3DD)),
              borderRadius: BorderRadius.circular(6),
            ),
            leading: const Icon(
              Icons.policy_outlined,
              color: Color(0xFF2D6B3F),
              size: 19,
            ),
            title: const Text('查看隐私说明', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: granting ? null : onPrivacy,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: granting ? null : onDecline,
            icon: const Icon(Icons.close),
            label: const Text('不同意'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: granting ? null : onGrant,
            icon: granting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check),
            label: Text(granting ? '正在保存同意状态' : '同意并继续'),
          ),
        ],
      ),
    );
  }
}

class _ConsentFacts extends StatelessWidget {
  const _ConsentFacts();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F6F3),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Column(
      children: [
        _ConsentFact(
          icon: Icons.map_outlined,
          title: '高德地图 SDK',
          detail: '用于加载地图、手势交互与地图展示。',
        ),
        Divider(height: 1),
        _ConsentFact(
          icon: Icons.my_location,
          title: '位置数据',
          detail: '仅在对应功能使用时处理，不因打开应用而读取。',
        ),
        Divider(height: 1),
        _ConsentFact(
          icon: Icons.shield_outlined,
          title: '随时改变决定',
          detail: '可在系统设置中关闭位置权限。',
        ),
      ],
    ),
  );
}

class _ConsentFact extends StatelessWidget {
  const _ConsentFact({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF2D6B3F), size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(color: Color(0xFF667268), fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ConsentGrantedBadge extends StatelessWidget {
  const _ConsentGrantedBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_user, size: 13, color: Color(0xFF2D6B3F)),
        SizedBox(width: 4),
        Text(
          '已同意 · 地图隐私设置已保存',
          style: TextStyle(
            color: Color(0xFF2D6B3F),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _ConsentError extends StatelessWidget {
  const _ConsentError({required this.onDecline, required this.onRetry});

  final VoidCallback onDecline;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('amap-consent-error'),
    color: Colors.white,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44, color: Color(0xFFBA1A1A)),
            const SizedBox(height: 12),
            const Text(
              '无法保存地图隐私设置',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('重新尝试')),
            TextButton(onPressed: onDecline, child: const Text('返回')),
          ],
        ),
      ),
    ),
  );
}

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
