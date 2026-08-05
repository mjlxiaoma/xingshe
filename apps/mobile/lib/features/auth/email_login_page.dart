import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_providers.dart';

typedef SendEmailCode = Future<void> Function(String email);

final sendEmailCodeProvider = Provider<SendEmailCode>(
  (ref) =>
      (email) => ref
          .read(apiClientProvider)
          .request<void>(
            '/auth/email-code',
            method: 'POST',
            data: {'email': email},
            decode: (_) {},
          ),
);

final emailCodeRequestProvider =
    NotifierProvider<EmailCodeRequestController, AsyncValue<int>>(
      EmailCodeRequestController.new,
    );

class EmailCodeRequestController extends Notifier<AsyncValue<int>> {
  Timer? _timer;

  @override
  AsyncValue<int> build() {
    ref.onDispose(() => _timer?.cancel());
    return const AsyncData(0);
  }

  Future<bool> send(String email) async {
    _timer?.cancel();
    state = const AsyncLoading();
    try {
      await ref.read(sendEmailCodeProvider)(email.trim().toLowerCase());
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
    state = const AsyncData(60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.value ?? 0;
      if (remaining <= 1) {
        timer.cancel();
        state = const AsyncData(0);
      } else {
        state = AsyncData(remaining - 1);
      }
    });
    return true;
  }
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return '请输入邮箱地址';
  if (email.length > 255 ||
      !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return '邮箱格式不正确';
  }
  return null;
}

class EmailLoginPage extends ConsumerStatefulWidget {
  const EmailLoginPage({super.key});

  @override
  ConsumerState<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends ConsumerState<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const text = Color(0xFF17201A);
    const muted = Color(0xFF667268);
    const primary = Color(0xFF2D6B3F);
    const surfaceSoft = Color(0xFFF4F6F3);
    const coral = Color(0xFFE85D45);
    final request = ref.watch(emailCodeRequestProvider);
    final seconds = request.value ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 210,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/login.jpg', fit: BoxFit.cover),
                  const ColoredBox(color: Color(0x78102616)),
                  Positioned(
                    left: 18,
                    top: 18,
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: coral,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.photo_camera,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          '行摄',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 18,
                    top: 18,
                    child: TextButton(
                      onPressed: () => context.go('/'),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xE8FFFFFF),
                        foregroundColor: primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        '稍后浏览',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 18,
                    bottom: 28,
                    child: Text(
                      '收藏值得再去的光',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '邮箱验证码登录',
                        style: TextStyle(
                          color: text,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '登录后可收藏机位并同步账号信息；本地行程和照片不会上传。',
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: validateEmail,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          labelText: '邮箱',
                          hintText: 'name@example.com',
                          prefixIcon: const Icon(Icons.mail_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: request.isLoading || seconds > 0
                            ? null
                            : _sendCode,
                        icon: request.isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.mail),
                        label: Text(seconds > 0 ? '$seconds 秒后重试' : '发送验证码'),
                      ),
                      if (request.hasError) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage(request.error),
                          style: const TextStyle(
                            color: Color(0xFFBA1A1A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_user, color: primary, size: 20),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                '验证码 10 分钟内有效。我们不会在界面或日志中展示验证码。',
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
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton(
                          key: const Key('open-public-privacy'),
                          onPressed: () => context.push('/privacy'),
                          child: const Text(
                            '隐私说明与账号删除',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    final sent = await ref
        .read(emailCodeRequestProvider.notifier)
        .send(_emailController.text);
    if (sent && mounted) {
      context.push(
        '/verify',
        extra: _emailController.text.trim().toLowerCase(),
      );
    }
  }

  String _errorMessage(Object? error) =>
      error is ApiException ? '${error.message}，请重试' : '网络连接失败，请重试';
}
