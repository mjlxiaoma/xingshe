import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/features/auth/email_login_page.dart';

void main() {
  test('validates email and supports retry after a send failure', () async {
    expect(validateEmail('bad-email'), '邮箱格式不正确');
    expect(validateEmail('user@example.com'), isNull);

    var attempts = 0;
    final container = ProviderContainer(
      overrides: [
        sendEmailCodeProvider.overrideWithValue((email) async {
          attempts++;
          expect(email, 'user@example.com');
          if (attempts == 1) throw Exception('offline');
        }),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(emailCodeRequestProvider.notifier);

    expect(await controller.send(' USER@EXAMPLE.COM '), isFalse);
    expect(container.read(emailCodeRequestProvider).hasError, isTrue);

    expect(await controller.send('user@example.com'), isTrue);
    expect(container.read(emailCodeRequestProvider).requireValue, 60);
    expect(attempts, 2);
  });
}
