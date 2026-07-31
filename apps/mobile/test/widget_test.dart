import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/main.dart';

void main() {
  testWidgets('shows the XingShe startup screen', (tester) async {
    await tester.pumpWidget(const XingSheApp());

    expect(find.text('行摄'), findsOneWidget);
    expect(find.text('发现机位，记录每一次追光。'), findsOneWidget);
    expect(find.text('轨迹与照片默认只保存在本机'), findsOneWidget);
  });
}
