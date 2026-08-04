import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/observability/error_reporter.dart';

void main() {
  test('allows API codes and redacts arbitrary sensitive text', () {
    expect(safeErrorCode('AUTH_INVALID_TOKEN'), 'AUTH_INVALID_TOKEN');
    expect(safeErrorCode('Bearer test-secret-token'), 'REDACTED');
    expect(safeErrorCode('123456'), 'REDACTED');
    expect(safeErrorCode('person@example.invalid'), 'REDACTED');
  });
}
