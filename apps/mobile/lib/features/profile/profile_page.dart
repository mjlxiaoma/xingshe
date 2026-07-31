import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';
import '../../core/auth/auth_session.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.nickname,
    this.avatarURL,
  });

  final String id;
  final String email;
  final String nickname;
  final String? avatarURL;

  factory UserProfile.fromJson(Object? data) {
    final json = data as Map<String, dynamic>;
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      avatarURL: json['avatar_url'] as String?,
    );
  }
}

typedef LoadProfile = Future<UserProfile> Function();
typedef UpdateProfile = Future<UserProfile> Function(String nickname);

final loadProfileProvider = Provider<LoadProfile>(
  (ref) =>
      () => ref
          .read(apiClientProvider)
          .request<UserProfile>('/me', decode: UserProfile.fromJson),
);

final updateProfileProvider = Provider<UpdateProfile>(
  (ref) =>
      (nickname) => ref
          .read(apiClientProvider)
          .request<UserProfile>(
            '/me',
            method: 'PATCH',
            data: {'nickname': nickname},
            decode: UserProfile.fromJson,
          ),
);

final profileProvider = AsyncNotifierProvider<ProfileController, UserProfile?>(
  ProfileController.new,
);

class ProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    if (!await ref.watch(authSessionProvider.future)) return null;
    return ref.read(loadProfileProvider)();
  }

  Future<bool> updateNickname(String nickname) async {
    final value = nickname.trim();
    if (value.length < 2 || value.length > 64) return false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(updateProfileProvider)(value),
    );
    return !state.hasError;
  }
}

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return SafeArea(
      child: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _ProfileError(onRetry: () => ref.invalidate(profileProvider)),
        data: (user) => user == null
            ? const _GuestProfile()
            : _AuthenticatedProfile(user: user),
      ),
    );
  }
}

class _GuestProfile extends StatelessWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我的',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          const Center(
            child: Icon(
              Icons.person_outline,
              size: 64,
              color: Color(0xFF2D6B3F),
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              '登录后查看个人资料与收藏机位',
              style: TextStyle(color: Color(0xFF667268), fontSize: 13),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push('/login'),
            icon: const Icon(Icons.login),
            label: const Text('邮箱登录'),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _AuthenticatedProfile extends ConsumerWidget {
  const _AuthenticatedProfile({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const primary = Color(0xFF2D6B3F);
    const muted = Color(0xFF667268);
    const soft = Color(0xFFF4F6F3);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '我的',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            IconButton.filledTonal(
              onPressed: null,
              icon: const Icon(Icons.settings),
              tooltip: '设置',
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: Color(0xFFDDE3DD)),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: const Color(0xFF1E3322),
                child: Text(
                  user.nickname.characters.firstOrNull ?? '行',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nickname,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maskEmail(user.email),
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: () => _editProfile(context, ref, user),
                icon: const Icon(Icons.edit, color: primary),
                tooltip: '编辑个人资料',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: _Stat(value: '0', label: '次行摄'),
            ),
            SizedBox(width: 6),
            Expanded(
              child: _Stat(value: '0.0', label: '公里'),
            ),
            SizedBox(width: 6),
            Expanded(
              child: _Stat(value: '0', label: '收藏机位'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          '常用功能',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const _MenuItem(
          icon: Icons.bookmark,
          title: '收藏机位',
          detail: '查看已收藏的摄影机位',
        ),
        const _MenuItem(icon: Icons.route, title: '本地行程', detail: '轨迹与照片仅在设备中'),
        const _MenuItem(
          icon: Icons.shield,
          title: '隐私与权限',
          detail: '查看定位和照片权限',
        ),
        const _MenuItem(icon: Icons.help, title: '帮助与反馈', detail: '常见问题与版本信息'),
        const SizedBox(height: 8),
        const Text(
          '账号资料保存在服务端；轨迹与原图仍仅保存在本机。',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, fontSize: 10),
        ),
        const SizedBox(height: 6),
        const ColoredBox(color: soft, child: SizedBox(height: 1)),
      ],
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    UserProfile user,
  ) async {
    final controller = TextEditingController(text: user.nickname);
    final formKey = GlobalKey<FormState>();
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          18,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '编辑个人资料',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: '关闭',
                  ),
                ],
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 29,
                  backgroundColor: Color(0xFF1E3322),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text('头像占位'),
                subtitle: Text('MVP 暂不上传头像文件'),
              ),
              TextFormField(
                controller: controller,
                maxLength: 64,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '昵称',
                  border: OutlineInputBorder(),
                  helperText: '2–64 个字符，保存后立即更新',
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  return length < 2 || length > 64 ? '请输入 2–64 个字符' : null;
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, true);
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('保存资料'),
              ),
            ],
          ),
        ),
      ),
    );
    if (save != true) {
      controller.dispose();
      return;
    }
    final updated = await ref
        .read(profileProvider.notifier)
        .updateNickname(controller.text);
    controller.dispose();
    if (!updated && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('资料保存失败，请重试')));
    }
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final count = parts.first.length.clamp(1, 3);
    return '${parts.first.substring(0, count)}***@${parts.last}';
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F6F3),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF667268), fontSize: 9),
        ),
      ],
    ),
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFE7F1E9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: const Color(0xFF2D6B3F), size: 21),
    ),
    title: Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(detail, style: const TextStyle(fontSize: 10)),
    trailing: const Icon(Icons.chevron_right),
  );
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('个人资料加载失败'),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('重试'),
        ),
      ],
    ),
  );
}
