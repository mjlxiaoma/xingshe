import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_providers.dart';
import '../../core/auth/auth_session.dart';
import '../../core/location/trip_recording_controller.dart';
import '../profile/profile_page.dart';

typedef RevokeSession = Future<void> Function(String refreshToken);

final revokeSessionProvider = Provider<RevokeSession>(
  (ref) =>
      (refreshToken) => ref
          .read(apiClientProvider)
          .request<void>(
            '/auth/logout',
            method: 'POST',
            data: {'refresh_token': refreshToken},
            decode: (_) {},
          ),
);

final logoutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final tokens = await ref.read(tokenStoreProvider).readTokens();
    try {
      if (tokens != null) {
        await ref.read(revokeSessionProvider)(tokens.refreshToken);
      }
    } finally {
      await ref.read(authSessionProvider.notifier).expire();
    }
  };
});

typedef DeleteAccount = Future<bool> Function(bool clearLocalTrips);

final deleteAccountProvider = Provider<DeleteAccount>((ref) {
  return (clearLocalTrips) async {
    await ref
        .read(apiClientProvider)
        .request<void>('/me', method: 'DELETE', decode: (_) {});
    var localTripsCleared = true;
    if (clearLocalTrips) {
      try {
        await ref.read(tripRecordingControllerProvider).deleteAllLocalTrips();
      } on Object {
        localTripsCleared = false;
      }
    }
    await ref.read(authSessionProvider.notifier).expire();
    return localTripsCleared;
  };
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).value;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton.outlined(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        children: [
          const _SectionLabel('账号'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1E3322),
              child: Text(
                user?.nickname.characters.firstOrNull ?? '行',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(user?.nickname ?? '行摄者'),
            subtitle: Text(user == null ? '当前账号' : _maskEmail(user.email)),
            trailing: const Icon(Icons.edit, color: Color(0xFF2D6B3F)),
            onTap: () => context.pop(),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('权限与隐私'),
          _SettingsRow(
            icon: Icons.location_on,
            title: '定位权限',
            detail: '按需授权',
            onTap: () => context.push('/permissions'),
          ),
          _SettingsRow(
            icon: Icons.photo_camera,
            title: '相机与照片权限',
            detail: '按需授权',
            onTap: () => context.push('/permissions'),
          ),
          _SettingsRow(
            icon: Icons.policy,
            title: '隐私说明',
            detail: '查看数据处理规则',
            onTap: () => context.push('/privacy'),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('本地数据'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Icon(Icons.storage, color: Color(0xFF2D6B3F)),
                SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '本地行程与照片关联',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '退出登录不会删除本地行程',
                        style: TextStyle(
                          color: Color(0xFF667268),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextButton.icon(
            key: const Key('open-account-deletion'),
            onPressed: () => context.push('/account/delete'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFBA1A1A),
              minimumSize: const Size.fromHeight(46),
            ),
            icon: const Icon(Icons.person_remove_outlined),
            label: const Text('删除账号'),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFBA1A1A),
              side: const BorderSide(color: Color(0xFFBA1A1A)),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('退出登录'),
          ),
          const SizedBox(height: 20),
          const Text(
            '行摄 Android MVP · 0.1.0',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF667268), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录？'),
        content: const Text('账号会话将被清除，本地行程和照片不会删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(logoutProvider)();
    } catch (_) {
      // Local logout succeeds even when the server cannot be reached.
    }
    if (context.mounted) context.go('/login');
  }

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final count = parts.first.length.clamp(1, 3);
    return '${parts.first.substring(0, count)}***@${parts.last}';
  }
}

class AccountDeletionPage extends ConsumerStatefulWidget {
  const AccountDeletionPage({super.key});

  @override
  ConsumerState<AccountDeletionPage> createState() =>
      _AccountDeletionPageState();
}

class _AccountDeletionPageState extends ConsumerState<AccountDeletionPage> {
  bool _clearLocalTrips = false;
  bool _deleting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton.outlined(
          onPressed: _deleting ? null : () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        title: const Text('删除账号'),
        centerTitle: true,
      ),
      body: _deleting
          ? const Center(
              key: Key('account-deletion-progress'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text('正在删除账号…'),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                const _DeletionWarning(),
                const SizedBox(height: 18),
                const _SectionLabel('本地数据'),
                const SizedBox(height: 6),
                CheckboxListTile(
                  key: const Key('clear-local-trips-option'),
                  value: _clearLocalTrips,
                  onChanged: (value) =>
                      setState(() => _clearLocalTrips = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('同时清理本地行程'),
                  subtitle: const Text('默认保留。勾选后会删除行程、轨迹和照片关联，不删除系统相册原图。'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    key: const Key('account-deletion-error'),
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFFFEDEA),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFBA1A1A)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('account-deletion-submit'),
                  onPressed: _confirmAndDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFBA1A1A),
                  ),
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: Text(_error == null ? '继续删除' : '重试删除'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  key: const Key('cancel-account-deletion'),
                  onPressed: () => context.pop(),
                  child: const Text('取消操作'),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认永久删除账号？'),
        content: Text(
          _clearLocalTrips
              ? '服务端账号、Token 和收藏将删除；本机行程也将清理。系统相册原图仍需单独处理。'
              : '服务端账号、Token 和收藏将删除；本地行程和系统相册原图将保留。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('返回'),
          ),
          FilledButton(
            key: const Key('confirm-account-deletion'),
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBA1A1A),
            ),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      final localTripsCleared = await ref.read(deleteAccountProvider)(
        _clearLocalTrips,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          key: const Key('account-deletion-success'),
          title: const Text('账号已删除'),
          content: Text(
            !localTripsCleared
                ? '服务端账号已删除，但本地行程清理失败，可在行程页继续手动删除。系统相册原图仍保留。'
                : _clearLocalTrips
                ? '服务端账号和本地行程已删除。系统相册原图仍保留。'
                : '服务端账号已删除，本地行程和系统相册原图已保留。',
          ),
          actions: [
            FilledButton(
              key: const Key('finish-account-deletion'),
              onPressed: () => Navigator.pop(context),
              child: const Text('完成'),
            ),
          ],
        ),
      );
      if (mounted) context.go('/login');
    } on Object {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = '删除失败，请检查网络后重试。本地行程不会因本次失败而删除。';
        });
      }
    }
  }
}

class _DeletionWarning extends StatelessWidget {
  const _DeletionWarning();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    color: const Color(0xFFFFEDEA),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A), size: 34),
        SizedBox(height: 10),
        Text(
          '此操作无法撤销',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10),
        Text('• 服务端账号、登录 Token 和收藏将永久删除。'),
        SizedBox(height: 6),
        Text('• 本地行程默认保留，你可选择一并清理。'),
        SizedBox(height: 6),
        Text('• 系统相册原图不会自动删除，需在系统相册单独处理。'),
      ],
    ),
  );
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton.outlined(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        title: const Text('隐私说明'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: const [
          _PrivacyHero(),
          SizedBox(height: 12),
          Text(
            '更新日期：2026.07.30 · MVP 说明版',
            style: TextStyle(color: Color(0xFF667268), fontSize: 9),
          ),
          SizedBox(height: 8),
          _PrivacyItem(
            icon: Icons.smartphone,
            title: '保存在本机',
            detail: '完整轨迹、原始照片及照片关联默认只保存在设备中。',
          ),
          _PrivacyItem(
            icon: Icons.cloud_outlined,
            title: '账号服务保存',
            detail: '服务端仅保存邮箱、昵称、机位与收藏等必要账号数据。',
          ),
          _PrivacyItem(
            icon: Icons.location_on,
            title: '定位使用时机',
            detail: '仅在你主动开始行摄后读取位置，结束行摄时停止后台定位服务。',
          ),
          _PrivacyItem(
            icon: Icons.key,
            title: '按需请求权限',
            detail: '定位、相机和照片权限只在对应功能使用前请求，可随时在系统设置中关闭。',
          ),
          _PrivacyItem(
            icon: Icons.share,
            title: '分享由你决定',
            detail: '分享图在本机生成，调用系统分享面板前由你预览确认。',
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF667268),
      fontSize: 10,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: const Color(0xFF2D6B3F)),
    title: Text(title, style: const TextStyle(fontSize: 13)),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          detail,
          style: const TextStyle(color: Color(0xFF667268), fontSize: 10),
        ),
        const Icon(Icons.chevron_right, size: 20),
      ],
    ),
    onTap: onTap,
  );
}

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF1E3322),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Row(
      children: [
        Icon(Icons.shield, color: Color(0xFFD4A020), size: 40),
        SizedBox(width: 13),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '你的行程属于你',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '本地优先 · 最小上传 · 按需授权',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xFFDDE3DD))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F1E9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: const Color(0xFF2D6B3F), size: 20),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                detail,
                style: const TextStyle(
                  color: Color(0xFF667268),
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
