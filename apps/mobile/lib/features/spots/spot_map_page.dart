import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/map/map_provider.dart';
import 'spot_list_page.dart';

final mapSpotsProvider = FutureProvider<List<ShootingSpot>>(
  (ref) async =>
      (await ref.read(loadSpotsProvider)(page: 1, pageSize: 100)).items,
  retry: (_, _) => null,
);

class SpotMapPage extends ConsumerStatefulWidget {
  const SpotMapPage({super.key});

  @override
  ConsumerState<SpotMapPage> createState() => _SpotMapPageState();
}

class _SpotMapPageState extends ConsumerState<SpotMapPage> {
  ShootingSpot? _selected;

  @override
  Widget build(BuildContext context) {
    final spots = ref.watch(mapSpotsProvider);
    final items = spots.value ?? const <ShootingSpot>[];
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
            if (spots.isLoading) const _MapStatus('正在加载摄影机位'),
            if (spots.hasError)
              _MapError(onRetry: () => ref.invalidate(mapSpotsProvider)),
            if (_selected case final spot?) _SpotSummary(spot),
          ],
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) => Container(
    key: const Key('map-spot-summary'),
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
                style: const TextStyle(color: Color(0xFF667268), fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
