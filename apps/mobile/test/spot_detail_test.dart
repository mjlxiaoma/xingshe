import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/auth/auth_session.dart';
import 'package:xingshe/core/auth/token_store.dart';
import 'package:xingshe/features/spots/spot_detail_page.dart';
import 'package:xingshe/features/spots/spot_list_page.dart';

void main() {
  testWidgets('shows spot details and toggles favorite for a signed-in user', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool? favorite;
    final store = TokenStore.testing(
      read: (key) async => key.contains('access') ? 'access' : 'refresh',
      write: (_, _) async {},
      delete: (_) async {},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          loadSpotProvider.overrideWithValue((_) async => _spot),
          setSpotFavoriteProvider.overrideWithValue((_, value) async {
            favorite = value;
          }),
        ],
        child: const MaterialApp(home: SpotDetailPage(spotID: 'spot-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('西湖日落'), findsOneWidget);
    expect(find.text('杭州市西湖区'), findsOneWidget);
    expect(find.text('日落前 30 分钟'), findsNWidgets(2));
    expect(find.text('日落'), findsOneWidget);
    expect(find.byKey(const Key('spot-map-position')), findsOneWidget);

    await tester.tap(find.byKey(const Key('spot-favorite-button')));
    await tester.pumpAndSettle();
    expect(favorite, isTrue);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    await tester.tap(find.byKey(const Key('spot-navigation-button')));
    await tester.pump();
    expect(find.text('系统导航入口将在后续接入'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a retryable detail error', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          loadSpotProvider.overrideWithValue((_) async {
            calls++;
            if (calls == 1) throw Exception('offline');
            return _spot;
          }),
        ],
        child: const MaterialApp(home: SpotDetailPage(spotID: 'spot-1')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('spot-detail-error')), findsOneWidget);
    await tester.tap(find.text('重试'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('西湖日落'), findsOneWidget);
  });
}

const _spot = ShootingSpot(
  id: 'spot-1',
  name: '西湖日落',
  description: '沿湖拍摄水面与远山。',
  latitude: 30.25779,
  longitude: 120.14741,
  coordinateSystem: 'GCJ02',
  address: '杭州市西湖区',
  bestTime: '日落前 30 分钟',
  tags: ['日落', '湖景'],
  isFavorited: false,
);
