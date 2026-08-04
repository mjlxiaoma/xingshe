import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';
import '../../core/auth/auth_session.dart';
import 'spot_list_page.dart';
import 'spot_map_page.dart';

typedef LoadSpot = Future<ShootingSpot> Function(String id);
typedef SetSpotFavorite = Future<void> Function(String id, bool favorite);

final loadSpotProvider = Provider<LoadSpot>(
  (ref) =>
      (id) => ref
          .read(apiClientProvider)
          .request<ShootingSpot>('/spots/$id', decode: ShootingSpot.fromJson),
);

final setSpotFavoriteProvider = Provider<SetSpotFavorite>(
  (ref) =>
      (id, favorite) => ref
          .read(apiClientProvider)
          .request<void>(
            '/spots/$id/favorite',
            method: favorite ? 'POST' : 'DELETE',
            decode: (_) {},
          ),
);

final spotDetailProvider = FutureProvider.family<ShootingSpot, String>(
  (ref, id) => ref.read(loadSpotProvider)(id),
  retry: (_, _) => null,
);

class SpotDetailPage extends ConsumerStatefulWidget {
  const SpotDetailPage({super.key, required this.spotID});

  final String spotID;

  @override
  ConsumerState<SpotDetailPage> createState() => _SpotDetailPageState();
}

class _SpotDetailPageState extends ConsumerState<SpotDetailPage> {
  bool? _favorite;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ref
            .watch(spotDetailProvider(widget.spotID))
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _DetailError(
                onRetry: () =>
                    ref.invalidate(spotDetailProvider(widget.spotID)),
              ),
              data: (spot) => _DetailContent(
                spot: spot,
                favorite: _favorite ?? spot.isFavorited,
                saving: _saving,
                onFavorite: () => _toggleFavorite(spot),
              ),
            ),
      ),
    );
  }

  Future<void> _toggleFavorite(ShootingSpot spot) async {
    if (_saving) return;
    if (!await ref.read(authSessionProvider.future)) {
      if (mounted) context.push('/login');
      return;
    }
    final value = !(_favorite ?? spot.isFavorited);
    setState(() => _saving = true);
    try {
      await ref.read(setSpotFavoriteProvider)(spot.id, value);
      if (!mounted) return;
      setState(() => _favorite = value);
      ref.invalidate(spotListProvider);
      ref.invalidate(mapSpotsProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('收藏状态更新失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.spot,
    required this.favorite,
    required this.saving,
    required this.onFavorite,
  });

  final ShootingSpot spot;
  final bool favorite;
  final bool saving;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(
          children: [
            _Hero(spot),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spot.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              spot.address ?? '地址待补充',
                              style: const TextStyle(
                                color: Color(0xFF667268),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton.outlined(
                        key: const Key('spot-favorite-button'),
                        onPressed: saving ? null : onFavorite,
                        icon: saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                favorite
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                              ),
                        tooltip: favorite ? '取消收藏' : '收藏机位',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: spot.tags.map(_Tag.new).toList(growable: false),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    spot.description,
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 14),
                  _Fact(value: spot.bestTime ?? '待补充'),
                  const SizedBox(height: 12),
                  _PositionPreview(spot),
                ],
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFDDE3DD))),
        ),
        child: OutlinedButton.icon(
          key: const Key('spot-navigation-button'),
          onPressed: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('系统导航入口将在后续接入'))),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          icon: const Icon(Icons.navigation),
          label: const Text('导航'),
        ),
      ),
    ],
  );
}

class _Hero extends StatelessWidget {
  const _Hero(this.spot);

  final ShootingSpot spot;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 238,
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (spot.coverURL case final url?)
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const _HeroPlaceholder(),
          )
        else
          const _HeroPlaceholder(),
        const ColoredBox(color: Color(0x32102616)),
        Positioned(
          left: 16,
          top: 16,
          child: IconButton.filled(
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xE8FFFFFF),
              foregroundColor: const Color(0xFF17201A),
            ),
            icon: const Icon(Icons.arrow_back),
            tooltip: '返回',
          ),
        ),
        if (spot.bestTime case final value?)
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xE81E3322),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
      ],
    ),
  );
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFF1E3322),
    child: Center(
      child: Icon(Icons.landscape, color: Color(0xFFD4A020), size: 54),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F6F3),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: const TextStyle(color: Color(0xFF667268), fontSize: 10),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F6F3),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        const Icon(Icons.schedule, color: Color(0xFF2D6B3F), size: 20),
        const SizedBox(width: 10),
        const Text('最佳时间：', style: TextStyle(fontSize: 10)),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _PositionPreview extends StatelessWidget {
  const _PositionPreview(this.spot);

  final ShootingSpot spot;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('spot-map-position'),
    onTap: () => context.go('/map'),
    borderRadius: BorderRadius.circular(6),
    child: Container(
      height: 86,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0E8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFE85D45),
            foregroundColor: Colors.white,
            child: Icon(Icons.photo_camera, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '地图位置',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${spot.latitude.toStringAsFixed(5)}, ${spot.longitude.toStringAsFixed(5)} · ${spot.coordinateSystem}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667268),
                    fontSize: 10,
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

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    key: const Key('spot-detail-error'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('机位详情加载失败'),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('重试'),
        ),
      ],
    ),
  );
}
