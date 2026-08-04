import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/features/spots/spot_list_page.dart';

void main() {
  test('decodes the paged spot response', () {
    final page = SpotPage.fromJson({
      'items': [_spotJson('1', '西湖日落')],
      'page': 1,
      'page_size': 10,
      'total': 1,
    });

    expect(page.items.single.name, '西湖日落');
    expect(page.items.single.latitude, 30.2);
    expect(page.items.single.tags, ['日落', '湖景']);
    expect(page.total, 1);
  });

  test(
    'search resets pagination and load more appends the next page',
    () async {
      final calls = <({String keyword, int page, int pageSize})>[];
      final container = ProviderContainer(
        overrides: [
          loadSpotsProvider.overrideWithValue(({
            keyword = '',
            page = 1,
            pageSize = 10,
          }) async {
            calls.add((keyword: keyword, page: page, pageSize: pageSize));
            return SpotPage(
              items: [
                ShootingSpot.fromJson(
                  _spotJson('$keyword-$page', '$keyword$page'),
                ),
              ],
              page: page,
              pageSize: pageSize,
              total: 2,
            );
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(spotListProvider.future);
      await container.read(spotListProvider.notifier).search('  日落  ');
      await container.read(spotListProvider.notifier).loadMore();

      final state = container.read(spotListProvider).requireValue;
      expect(calls, [
        (keyword: '', page: 1, pageSize: 10),
        (keyword: '日落', page: 1, pageSize: 10),
        (keyword: '日落', page: 2, pageSize: 10),
      ]);
      expect(state.items.map((spot) => spot.name), ['日落1', '日落2']);
      expect(state.hasMore, isFalse);
    },
  );

  testWidgets('shows loading, results, search, and load more states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final first = Completer<SpotPage>();
    final second = Completer<SpotPage>();
    var call = 0;
    await _pumpPage(tester, ({keyword = '', page = 1, pageSize = 10}) {
      call++;
      if (call == 1) return first.future;
      if (page == 2) return second.future;
      return Future.value(
        SpotPage(items: const [], page: 1, pageSize: pageSize, total: 0),
      );
    });

    expect(find.byKey(const Key('spot-loading')), findsOneWidget);
    first.complete(
      SpotPage(
        items: [ShootingSpot.fromJson(_spotJson('1', '西湖日落'))],
        page: 1,
        pageSize: 10,
        total: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('西湖日落'), findsOneWidget);
    expect(find.byKey(const Key('spot-load-more')), findsOneWidget);

    await tester.tap(find.byKey(const Key('spot-load-more')));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    second.complete(
      SpotPage(
        items: [ShootingSpot.fromJson(_spotJson('2', '城市夜景'))],
        page: 2,
        pageSize: 10,
        total: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('城市夜景'), findsOneWidget);
    expect(find.byKey(const Key('spot-load-more')), findsNothing);

    await tester.enterText(find.byKey(const Key('spot-search-field')), '不存在');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('spot-empty')), findsOneWidget);
    expect(find.text('没有找到相关机位'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an error state and retries', (tester) async {
    var calls = 0;
    await _pumpPage(tester, ({keyword = '', page = 1, pageSize = 10}) async {
      calls++;
      if (calls == 1) throw Exception('offline');
      return SpotPage(
        items: const [],
        page: page,
        pageSize: pageSize,
        total: 0,
      );
    });
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('spot-error')), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const Key('spot-empty')), findsOneWidget);
  });
}

Future<void> _pumpPage(WidgetTester tester, LoadSpots load) =>
    tester.pumpWidget(
      ProviderScope(
        overrides: [loadSpotsProvider.overrideWithValue(load)],
        child: const MaterialApp(home: Scaffold(body: SpotListPage())),
      ),
    );

Map<String, dynamic> _spotJson(String id, String name) => {
  'id': id,
  'name': name,
  'description': '描述',
  'latitude': 30.2,
  'longitude': 120.1,
  'coordinate_system': 'GCJ02',
  'address': '杭州市',
  'cover_url': null,
  'best_time': '日落',
  'tags': ['日落', '湖景'],
  'is_favorited': false,
  'distance_meters': null,
};
