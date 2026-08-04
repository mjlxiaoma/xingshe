import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';
import '../../core/auth/auth_session.dart';
import 'spot_detail_page.dart';
import 'spot_list_page.dart';
import 'spot_map_page.dart';

typedef LoadFavoriteSpots = Future<List<ShootingSpot>> Function();

final loadFavoriteSpotsProvider = Provider<LoadFavoriteSpots>(
  (ref) =>
      () => ref
          .read(apiClientProvider)
          .request<List<ShootingSpot>>(
            '/me/favorite-spots',
            decode: (data) => ((data as Map<String, dynamic>)['items'] as List)
                .map(ShootingSpot.fromJson)
                .toList(growable: false),
          ),
);

final favoriteSpotsProvider = FutureProvider<List<ShootingSpot>>(
  (ref) => ref.read(loadFavoriteSpotsProvider)(),
  retry: (_, _) => null,
);

class FavoriteSpotsPage extends ConsumerStatefulWidget {
  const FavoriteSpotsPage({super.key});

  @override
  ConsumerState<FavoriteSpotsPage> createState() => _FavoriteSpotsPageState();
}

class _FavoriteSpotsPageState extends ConsumerState<FavoriteSpotsPage> {
  String _query = '';
  final _removing = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton.outlined(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        title: const Text('收藏机位'),
        centerTitle: true,
      ),
      body: ref
          .watch(authSessionProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const _GuestFavorites(),
            data: (signedIn) => signedIn
                ? _buildFavorites(ref.watch(favoriteSpotsProvider))
                : const _GuestFavorites(),
          ),
    );
  }

  Widget _buildFavorites(
    AsyncValue<List<ShootingSpot>> favorites,
  ) => favorites.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, _) =>
        _FavoritesError(onRetry: () => ref.invalidate(favoriteSpotsProvider)),
    data: (items) {
      final query = _query.toLowerCase();
      final visible = items
          .where(
            (spot) =>
                query.isEmpty ||
                spot.name.toLowerCase().contains(query) ||
                spot.tags.any((tag) => tag.toLowerCase().contains(query)),
          )
          .toList(growable: false);
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '值得再去的光',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${items.length} 个收藏 · 收藏保存在账号中',
              style: const TextStyle(color: Color(0xFF667268), fontSize: 11),
            ),
            const SizedBox(height: 13),
            TextField(
              key: const Key('favorite-search'),
              decoration: InputDecoration(
                hintText: '搜索已收藏机位',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF4F6F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? _FavoritesEmpty(searching: items.isNotEmpty)
                  : ListView(
                      children: visible
                          .map(
                            (spot) => SpotListItem(
                              spot: spot,
                              trailing: _removing.contains(spot.id)
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : IconButton(
                                      key: Key('unfavorite-${spot.id}'),
                                      onPressed: () => _remove(spot),
                                      padding: EdgeInsets.zero,
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: 32,
                                            height: 32,
                                          ),
                                      icon: const Icon(Icons.bookmark),
                                      color: const Color(0xFFE85D45),
                                      tooltip: '取消收藏',
                                    ),
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
        ),
      );
    },
  );

  Future<void> _remove(ShootingSpot spot) async {
    if (_removing.contains(spot.id)) return;
    setState(() => _removing.add(spot.id));
    try {
      await ref.read(setSpotFavoriteProvider)(spot.id, false);
      ref.invalidate(favoriteSpotsProvider);
      ref.invalidate(spotListProvider);
      ref.invalidate(mapSpotsProvider);
      ref.invalidate(spotDetailProvider(spot.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('取消收藏失败，请重试')));
      }
    } finally {
      if (mounted) setState(() => _removing.remove(spot.id));
    }
  }
}

class _GuestFavorites extends StatelessWidget {
  const _GuestFavorites();

  @override
  Widget build(BuildContext context) => Center(
    key: const Key('favorites-guest'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bookmark_border, size: 52, color: Color(0xFF2D6B3F)),
        const SizedBox(height: 10),
        const Text('登录后查看账号收藏'),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => context.push('/login'),
          icon: const Icon(Icons.login),
          label: const Text('邮箱登录'),
        ),
      ],
    ),
  );
}

class _FavoritesEmpty extends StatelessWidget {
  const _FavoritesEmpty({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) => Center(
    key: const Key('favorites-empty'),
    child: Text(searching ? '没有找到相关收藏' : '还没有收藏机位'),
  );
}

class _FavoritesError extends StatelessWidget {
  const _FavoritesError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    key: const Key('favorites-error'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('收藏机位加载失败'),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('重试'),
        ),
      ],
    ),
  );
}
