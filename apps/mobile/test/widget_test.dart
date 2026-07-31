import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/main.dart';

void main() {
  testWidgets('starts in the app shell and navigates all tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: XingSheApp()));

    expect(find.text('去捕捉今天的光'), findsOneWidget);
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('地图'), findsOneWidget);
    expect(find.text('行摄'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    await tester.tap(find.text('地图'));
    await tester.pumpAndSettle();
    expect(find.text('搜索地点或摄影机位'), findsOneWidget);

    await tester.tap(find.text('行摄'));
    await tester.pumpAndSettle();
    expect(find.text('开始一次新的行摄'), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    expect(find.text('常用功能'), findsOneWidget);
  });
}
