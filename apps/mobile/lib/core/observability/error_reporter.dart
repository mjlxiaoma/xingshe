import 'dart:convert';
import 'dart:developer' as developer;

enum AppErrorEvent { apiRequestFailed, sessionRefreshFailed }

typedef ErrorReporter =
    void Function(AppErrorEvent event, {String? code, int? status});

void reportErrorSafely(AppErrorEvent event, {String? code, int? status}) {
  final fields = <String, Object>{'event': event.name};
  if (code != null) fields['code'] = safeErrorCode(code);
  if (status != null) fields['status'] = status;
  developer.log(jsonEncode(fields), name: 'xingshe.error');
}

String safeErrorCode(String value) =>
    RegExp(r'^[A-Z][A-Z0-9_]{0,63}$').hasMatch(value) ? value : 'REDACTED';
