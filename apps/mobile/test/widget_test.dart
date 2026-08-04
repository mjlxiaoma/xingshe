import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/auth/auth_session.dart';
import 'package:xingshe/core/auth/token_store.dart';
import 'package:xingshe/core/map/map_provider.dart';
import 'package:xingshe/main.dart';

void main() {
  testWidgets('starts in the app shell and navigates all tabs', (tester) async {
    final store = TokenStore.testing(
      read: (_) async => null,
      write: (_, _) async {},
      delete: (_) async {},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStoreProvider.overrideWithValue(store),
          mapConsentStoreProvider.overrideWithValue(
            MapConsentStore.testing(() async => false, () async {}),
          ),
        ],
        child: const XingSheApp(),
      ),
    );

    expect(find.text('去捕捉今天的光'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('地图'), findsOneWidget);
    expect(find.text('行摄'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await tester.tap(find.text('地图'));
    await tester.pumpAndSettle();
    expect(find.text('使用地图前，请先了解位置数据'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('登录后查看个人资料与收藏机位'), findsOneWidget);

    await tester.tap(find.text('行摄'));
    await tester.pumpAndSettle();
    expect(find.text('开始一次新的行摄'), findsOneWidget);
  });
}
