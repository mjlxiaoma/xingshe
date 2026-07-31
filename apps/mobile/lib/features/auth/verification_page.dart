import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_providers.dart';
import '../../core/auth/auth_session.dart';
import '../../core/auth/token_store.dart';

typedef VerifyCode = Future<SessionTokens> Function(String email, String code);

final verifyCodeProvider = Provider<VerifyCode>((ref) {
  return (email, code) async {
    final deviceID = await ref.read(tokenStoreProvider).deviceID();
    return ref
        .read(apiClientProvider)
        .request<SessionTokens>(
          '/auth/login',
          method: 'POST',
          data: {'email': email, 'code': code, 'device_id': deviceID},
          decode: (data) {
            final json = data as Map<String, dynamic>;
            return SessionTokens(
              accessToken: json['access_token'] as String,
              refreshToken: json['refresh_token'] as String,
            );
          },
        );
  };
});

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF17201A);
    const muted = Color(0xFF667268);
    const primary = Color(0xFF2D6B3F);
    const primarySoft = Color(0xFFE7F1E9);
    const surfaceSoft = Color(0xFFF4F6F3);
    const border = Color(0xFFDDE3DD);
    const error = Color(0xFFBA1A1A);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.outlined(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: '返回',
                    ),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('收不到？'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.mark_email_read,
                      color: primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '输入 6 位验证码',
                    style: TextStyle(
                      color: text,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '验证码已发送至 ${_maskEmail(widget.email)}',
                    style: const TextStyle(color: muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Semantics(
                    label: '6 位验证码',
                    textField: true,
                    child: GestureDetector(
                      onTap: _focusNode.requestFocus,
                      child: Stack(
                        children: [
                          Row(
                            children: List.generate(6, (index) {
                              final value = index < _controller.text.length
                                  ? _controller.text[index]
                                  : '';
                              return Expanded(
                                child: Container(
                                  height: 58,
                                  margin: EdgeInsets.only(
                                    right: index == 5 ? 0 : 8,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _error == null ? border : error,
                                      width: _error == null ? 1 : 2,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    value,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0.01,
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                autofocus: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                onChanged: (_) => setState(() => _error = null),
                                onSubmitted: (_) => _login(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.error, color: error, size: 17),
                        const SizedBox(width: 6),
                        Text(
                          _error!,
                          style: const TextStyle(color: error, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loading ? null : _login,
                    icon: _loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: const Text('验证并登录'),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      '返回上一页可重新发送',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: surfaceSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield, color: primary, size: 20),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            '验证码不会出现在日志中\n登录成功后安全保存会话 Token',
                            style: TextStyle(
                              color: muted,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_controller.text.length != 6) {
      setState(() => _error = '请输入完整的 6 位验证码');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tokens = await ref.read(verifyCodeProvider)(
        widget.email,
        _controller.text,
      );
      await ref.read(authSessionProvider.notifier).authenticate(tokens);
      if (mounted) context.go('/me');
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = exception is ApiException && exception.code == 'AUTH_1002'
            ? '验证码不正确，请检查后重试'
            : '登录失败，请稍后重试';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final prefix = parts.first;
    final visible = prefix.substring(0, prefix.length.clamp(1, 3));
    return '$visible***@${parts.last}';
  }
}
