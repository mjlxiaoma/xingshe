import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/api/api_providers.dart';
import '../../core/map/map_provider.dart';
import '../../core/permissions/app_permissions.dart';
import 'spot_list_page.dart';

final mapSpotsProvider = FutureProvider<List<ShootingSpot>>(
  (ref) async =>
      (await ref.read(loadSpotsProvider)(page: 1, pageSize: 100)).items,
  retry: (_, _) => null,
);

typedef LoadNearbySpots =
    Future<List<ShootingSpot>> Function(double latitude, double longitude);

final loadNearbySpotsProvider = Provider<LoadNearbySpots>(
  (ref) =>
      (latitude, longitude) => ref
          .read(apiClientProvider)
          .request<SpotPage>(
            '/spots',
            queryParameters: {
              'latitude': latitude,
              'longitude': longitude,
              'radius': 50000,
              'page': 1,
              'page_size': 100,
            },
            decode: SpotPage.fromJson,
          )
          .then((page) => page.items),
);

class SpotMapPage extends ConsumerStatefulWidget {
  const SpotMapPage({super.key});

  @override
  ConsumerState<SpotMapPage> createState() => _SpotMapPageState();
}

class _SpotMapPageState extends ConsumerState<SpotMapPage> {
  ShootingSpot? _selected;
  List<ShootingSpot>? _nearby;
  MapCoordinate? _lastLocation;
  bool _locationEnabled = false;
  bool _loadingNearby = false;
  bool _nearbyFailed = false;

  @override
  Widget build(BuildContext context) {
    final spots = ref.watch(mapSpotsProvider);
    final items = _nearby ?? spots.value ?? const <ShootingSpot>[];
    final markers = items
        .map(
          (spot) => MapMarker(
            id: spot.id,
            title: spot.name,
            position: MapCoordinate(
              latitude: spot.latitude,
              longitude: spot.longitude,
              system: mapCoordinateSystemFromAPI(spot.coordinateSystem),
            ),
          ),
        )
        .toList(growable: false);
    return SafeArea(
      child: MapConsentGate(
        mapProvider: ref.watch(mapProviderProvider),
        scene: MapScene(
          center: const MapCoordinate(latitude: 34.2, longitude: 108.9),
          zoom: 4,
          markers: markers,
          showUserLocation: _locationEnabled,
          onLocationChanged: _loadNearby,
          onMarkerTap: (marker) => setState(
            () => _selected = items.cast<ShootingSpot?>().firstWhere(
              (spot) => spot?.id == marker.id,
              orElse: () => null,
            ),
          ),
        ),
        onDecline: () => context.go('/'),
        onPrivacy: () => context.push('/privacy'),
        mapOverlay: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _MapSearchBar(),
            const SizedBox(height: 8),
            _NearbyAction(
              enabled: _locationEnabled,
              loading: _loadingNearby,
              failed: _nearbyFailed,
              onPressed: _nearbyFailed && _lastLocation != null
                  ? () => _fetchNearby(_lastLocation!, retry: true)
                  : _enableLocation,
            ),
            if (spots.isLoading) const _MapStatus('正在加载摄影机位'),
            if (spots.hasError)
              _MapError(onRetry: () => ref.invalidate(mapSpotsProvider)),
            if (_selected case final spot?) _SpotSummary(spot),
          ],
        ),
      ),
    );
  }

  Future<void> _enableLocation() async {
    final status = await ref
        .read(appPermissionsProvider.notifier)
        .request(AppPermission.location);
    if (!mounted) return;
    if (status.isGranted) {
      setState(() {
        _locationEnabled = true;
        _nearbyFailed = false;
      });
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('未获得前台定位权限，继续显示默认列表')));
  }

  Future<void> _loadNearby(MapCoordinate location) => _fetchNearby(location);

  Future<void> _fetchNearby(
    MapCoordinate location, {
    bool retry = false,
  }) async {
    if (_loadingNearby || (_lastLocation != null && !retry)) return;
    setState(() {
      _lastLocation = location;
      _loadingNearby = true;
      _nearbyFailed = false;
    });
    try {
      final nearby = await ref.read(loadNearbySpotsProvider)(
        location.latitude,
        location.longitude,
      );
      if (mounted) {
        setState(() {
          _nearby = nearby;
          _selected = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _nearbyFailed = true);
    } finally {
      if (mounted) setState(() => _loadingNearby = false);
    }
  }
}

class _NearbyAction extends StatelessWidget {
  const _NearbyAction({
    required this.enabled,
    required this.loading,
    required this.failed,
    required this.onPressed,
  });

  final bool enabled;
  final bool loading;
  final bool failed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: FilledButton.tonalIcon(
      key: const Key('nearby-spots-action'),
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(failed ? Icons.refresh : Icons.my_location),
      label: Text(
        failed
            ? '附近加载失败，重试'
            : enabled
            ? '正在使用当前位置 · 距离仅供参考'
            : '使用当前位置查找附近机位',
      ),
    ),
  );
}

class _MapSearchBar extends StatelessWidget {
  const _MapSearchBar();

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    child: ListTile(
      dense: true,
      leading: const Icon(Icons.search, color: Color(0xFF667268)),
      title: const Text(
        '搜索地点或摄影机位',
        style: TextStyle(color: Color(0xFF667268), fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF2D6B3F)),
      onTap: () => context.go('/spots'),
    ),
  );
}

class _MapStatus extends StatelessWidget {
  const _MapStatus(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('map-spots-loading'),
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    ),
  );
}

class _MapError extends StatelessWidget {
  const _MapError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('map-spots-error'),
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
    ),
    child: ListTile(
      dense: true,
      leading: const Icon(Icons.error_outline, color: Color(0xFFBA1A1A)),
      title: const Text('机位加载失败', style: TextStyle(fontSize: 11)),
      trailing: TextButton(onPressed: onRetry, child: const Text('重试')),
    ),
  );
}

class _SpotSummary extends StatelessWidget {
  const _SpotSummary(this.spot);

  final ShootingSpot spot;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('map-spot-summary'),
    onTap: () => context.push('/spots/${spot.id}'),
    borderRadius: BorderRadius.circular(6),
    child: Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 5)],
      ),
      child: Row(
        children: [
          const Icon(Icons.photo_camera, color: Color(0xFF2D6B3F)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  spot.address ?? spot.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667268),
                    fontSize: 10,
                  ),
                ),
                if (spot.distanceMeters case final distance?)
                  Text(
                    '约 ${(distance / 1000).toStringAsFixed(1)} km · 距离仅供参考',
                    style: const TextStyle(
                      color: Color(0xFF667268),
                      fontSize: 9,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF2D6B3F)),
        ],
      ),
    ),
  );
}
