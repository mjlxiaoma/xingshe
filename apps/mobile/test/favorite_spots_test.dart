import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/auth/auth_session.dart';
import 'package:xingshe/core/auth/token_store.dart';
import 'package:xingshe/features/spots/favorite_spots_page.dart';
import 'package:xingshe/features/spots/spot_detail_page.dart';
import 'package:xingshe/features/spots/spot_list_page.dart';

void main() {
  testWidgets('lists, searches, and removes a favorite spot', (tester) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var removed = false;
    final store = TokenStore.testing(
      read: (key) async => key.contains('access') ? 'access' : 'refresh',
      write: (_, _) async {},
      delete: (_) async {},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          loadFavoriteSpotsProvider.overrideWithValue(
            () async => removed ? const [] : [_spot],
          ),
          setSpotFavoriteProvider.overrideWithValue((id, favorite) async {
            expect(id, 'spot-1');
            expect(favorite, isFalse);
            removed = true;
          }),
        ],
        child: const MaterialApp(home: FavoriteSpotsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('西湖日落'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('favorite-search')), '夜景');
    await tester.pump();
    expect(find.text('没有找到相关收藏'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('favorite-search')), '日落');
    await tester.pump();
    expect(find.text('西湖日落'), findsOneWidget);

    await tester.tap(find.byKey(const Key('unfavorite-spot-1')));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
    expect(find.text('还没有收藏机位'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows guest and retryable error states', (tester) async {
    final guestStore = TokenStore.testing(
      read: (_) async => null,
      write: (_, _) async {},
      delete: (_) async {},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tokenStoreProvider.overrideWithValue(guestStore)],
        child: const MaterialApp(home: FavoriteSpotsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('favorites-guest')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    var calls = 0;
    final signedInStore = TokenStore.testing(
      read: (key) async => key.contains('access') ? 'access' : 'refresh',
      write: (_, _) async {},
      delete: (_) async {},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(signedInStore),
          loadFavoriteSpotsProvider.overrideWithValue(() async {
            calls++;
            if (calls == 1) throw Exception('offline');
            return const [];
          }),
        ],
        child: const MaterialApp(home: FavoriteSpotsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('favorites-error')), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const Key('favorites-empty')), findsOneWidget);
  });
}

const _spot = ShootingSpot(
  id: 'spot-1',
  name: '西湖日落',
  description: '描述',
  latitude: 30.2,
  longitude: 120.1,
  coordinateSystem: 'GCJ02',
  address: '杭州市',
  tags: ['日落', '湖景'],
  isFavorited: true,
);
