import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';

class ShootingSpot {
  const ShootingSpot({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.coordinateSystem,
    required this.tags,
    required this.isFavorited,
    this.address,
    this.coverURL,
    this.bestTime,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String coordinateSystem;
  final String? address;
  final String? coverURL;
  final String? bestTime;
  final List<String> tags;
  final bool isFavorited;
  final double? distanceMeters;

  factory ShootingSpot.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;
    return ShootingSpot(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      coordinateSystem: json['coordinate_system'] as String,
      address: json['address'] as String?,
      coverURL: json['cover_url'] as String?,
      bestTime: json['best_time'] as String?,
      tags: (json['tags'] as List<dynamic>).cast<String>(),
      isFavorited: json['is_favorited'] as bool,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
    );
  }
}

class SpotPage {
  const SpotPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<ShootingSpot> items;
  final int page;
  final int pageSize;
  final int total;

  factory SpotPage.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;
    return SpotPage(
      items: (json['items'] as List<dynamic>)
          .map(ShootingSpot.fromJson)
          .toList(growable: false),
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      total: json['total'] as int,
    );
  }
}

typedef LoadSpots =
    Future<SpotPage> Function({String keyword, int page, int pageSize});

final loadSpotsProvider = Provider<LoadSpots>(
  (ref) =>
      ({keyword = '', page = 1, pageSize = 10}) => ref
          .read(apiClientProvider)
          .request<SpotPage>(
            '/spots',
            queryParameters: {
              if (keyword.isNotEmpty) 'keyword': keyword,
              'page': page,
              'page_size': pageSize,
            },
            decode: SpotPage.fromJson,
          ),
);

class SpotListState {
  const SpotListState({
    required this.items,
    required this.keyword,
    required this.page,
    required this.total,
    this.loadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<ShootingSpot> items;
  final String keyword;
  final int page;
  final int total;
  final bool loadingMore;
  final bool loadMoreFailed;

  bool get hasMore => items.length < total;

  SpotListState copyWith({
    List<ShootingSpot>? items,
    int? page,
    bool? loadingMore,
    bool? loadMoreFailed,
  }) => SpotListState(
    items: items ?? this.items,
    keyword: keyword,
    page: page ?? this.page,
    total: total,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
  );
}

final spotListProvider =
    AsyncNotifierProvider<SpotListController, SpotListState>(
      SpotListController.new,
      retry: (_, _) => null,
    );

class SpotListController extends AsyncNotifier<SpotListState> {
  static const _pageSize = 10;

  @override
  Future<SpotListState> build() => _load(keyword: '', page: 1);

  Future<void> search(String keyword) async {
    final value = keyword.trim();
    if (state.value?.keyword == value) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(keyword: value, page: 1));
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(
      current.copyWith(loadingMore: true, loadMoreFailed: false),
    );
    try {
      final next = await _load(
        keyword: current.keyword,
        page: current.page + 1,
      );
      state = AsyncData(
        SpotListState(
          items: [...current.items, ...next.items],
          keyword: current.keyword,
          page: next.page,
          total: next.total,
        ),
      );
    } catch (_) {
      state = AsyncData(
        current.copyWith(loadingMore: false, loadMoreFailed: true),
      );
    }
  }

  Future<SpotListState> _load({
    required String keyword,
    required int page,
  }) async {
    final result = await ref.read(loadSpotsProvider)(
      keyword: keyword,
      page: page,
      pageSize: _pageSize,
    );
    return SpotListState(
      items: result.items,
      keyword: keyword,
      page: result.page,
      total: result.total,
    );
  }
}

class SpotListPage extends ConsumerStatefulWidget {
  const SpotListPage({super.key});

  @override
  ConsumerState<SpotListPage> createState() => _SpotListPageState();
}

class _SpotListPageState extends ConsumerState<SpotListPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spots = ref.watch(spotListProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(onMap: () => context.go('/map')),
            const SizedBox(height: 13),
            TextField(
              key: const Key('spot-search-field'),
              controller: _searchController,
              textInputAction: TextInputAction.search,
              maxLength: 128,
              decoration: InputDecoration(
                counterText: '',
                hintText: '搜索地点、标签或机位名称',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _search,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: '搜索机位',
                ),
                filled: true,
                fillColor: const Color(0xFFF4F6F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: spots.when(
                loading: () => const _LoadingState(),
                error: (_, _) => _ErrorState(
                  onRetry: () => ref.invalidate(spotListProvider),
                ),
                data: (value) => value.items.isEmpty
                    ? _EmptyState(keyword: value.keyword)
                    : _SpotResults(
                        state: value,
                        onLoadMore: () =>
                            ref.read(spotListProvider.notifier).loadMore(),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _search() {
    FocusScope.of(context).unfocus();
    ref.read(spotListProvider.notifier).search(_searchController.text);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onMap});

  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '全部城市 · 精选机位',
            style: TextStyle(color: Color(0xFF667268), fontSize: 11),
          ),
          Text(
            '摄影机位',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      IconButton.filledTonal(
        onPressed: onMap,
        icon: const Icon(Icons.map),
        tooltip: '切换到地图',
      ),
    ],
  );
}

class _SpotResults extends StatelessWidget {
  const _SpotResults({required this.state, required this.onLoadMore});

  final SpotListState state;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) => ListView.builder(
    key: const Key('spot-results'),
    itemCount: state.items.length + (state.hasMore ? 1 : 0),
    itemBuilder: (context, index) {
      if (index < state.items.length) return _SpotItem(state.items[index]);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: state.loadingMore
            ? const Center(
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : TextButton.icon(
                key: const Key('spot-load-more'),
                onPressed: onLoadMore,
                icon: Icon(
                  state.loadMoreFailed ? Icons.refresh : Icons.expand_more,
                ),
                label: Text(state.loadMoreFailed ? '加载失败，重试' : '加载更多'),
              ),
      );
    },
  );
}

class _SpotItem extends StatelessWidget {
  const _SpotItem(this.spot);

  final ShootingSpot spot;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push('/spots/${spot.id}'),
    child: Container(
      height: 116,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFDDE3DD))),
      ),
      child: Row(
        children: [
          _SpotCover(url: spot.coverURL),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      spot.isFavorited ? Icons.bookmark : Icons.bookmark_border,
                      color: const Color(0xFF2D6B3F),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  spot.address ?? '地址待补充',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF667268),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  children: spot.tags
                      .take(3)
                      .map((tag) => _Tag(tag))
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SpotCover extends StatelessWidget {
  const _SpotCover({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: const Color(0xFFE7F1E9),
      alignment: Alignment.center,
      child: const Icon(Icons.landscape, color: Color(0xFF2D6B3F), size: 30),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: 104,
        height: 96,
        child: url == null || url!.isEmpty
            ? placeholder
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(
    key: Key('spot-loading'),
    child: CircularProgressIndicator(),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context) => Center(
    key: const Key('spot-empty'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.landscape_outlined,
          size: 48,
          color: Color(0xFF2D6B3F),
        ),
        const SizedBox(height: 10),
        Text(keyword.isEmpty ? '暂无摄影机位' : '没有找到相关机位'),
        if (keyword.isNotEmpty)
          const Text(
            '换个关键词试试',
            style: TextStyle(color: Color(0xFF667268), fontSize: 11),
          ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    key: const Key('spot-error'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('机位加载失败，请检查网络'),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('重试'),
        ),
      ],
    ),
  );
}
