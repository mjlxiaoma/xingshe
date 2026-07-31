import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermission { location, backgroundLocation, camera, photos }

extension on AppPermission {
  Permission get platform => switch (this) {
    AppPermission.location => Permission.locationWhenInUse,
    AppPermission.backgroundLocation => Permission.locationAlways,
    AppPermission.camera => Permission.camera,
    AppPermission.photos => Permission.photos,
  };
}

typedef PermissionReader =
    Future<PermissionStatus> Function(AppPermission permission);

final permissionStatusReaderProvider = Provider<PermissionReader>(
  (_) =>
      (permission) => permission.platform.status,
);
final permissionRequesterProvider = Provider<PermissionReader>(
  (_) =>
      (permission) => permission.platform.request(),
);
final appSettingsOpenerProvider = Provider<Future<bool> Function()>(
  (_) => openAppSettings,
);

final appPermissionsProvider =
    NotifierProvider<
      AppPermissionsController,
      Map<AppPermission, PermissionStatus>
    >(AppPermissionsController.new);

class AppPermissionsController
    extends Notifier<Map<AppPermission, PermissionStatus>> {
  @override
  Map<AppPermission, PermissionStatus> build() => const {};

  Future<PermissionStatus> refresh(AppPermission permission) async {
    final status = await ref.read(permissionStatusReaderProvider)(permission);
    state = {...state, permission: status};
    return status;
  }

  Future<PermissionStatus> request(AppPermission permission) async {
    final status = await ref.read(permissionRequesterProvider)(permission);
    state = {...state, permission: status};
    return status;
  }

  Future<bool> openSettings() => ref.read(appSettingsOpenerProvider)();
}

class PermissionExplanationPage extends ConsumerStatefulWidget {
  const PermissionExplanationPage({super.key});

  @override
  ConsumerState<PermissionExplanationPage> createState() =>
      _PermissionExplanationPageState();
}

class _PermissionExplanationPageState
    extends ConsumerState<PermissionExplanationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appPermissionsProvider.notifier).refresh(AppPermission.location);
    });
  }

  @override
  Widget build(BuildContext context) {
    const primarySoft = Color(0xFFE7F1E9);
    const surfaceSoft = Color(0xFFF4F6F3);
    const text = Color(0xFF17201A);
    const muted = Color(0xFF667268);
    const coral = Color(0xFFE85D45);
    final status = ref.watch(appPermissionsProvider)[AppPermission.location];

    return Scaffold(
      backgroundColor: Colors.white,
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
                    OutlinedButton(
                      onPressed: () => context.pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(44, 44),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back, color: text),
                    ),
                    const Text(
                      '1 / 2',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _RoutePainter()),
                          ),
                          Center(
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: coral,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '允许记录行摄轨迹',
                      style: TextStyle(
                        color: text,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '只有你主动开始行摄后，我们才会读取位置。切到后台时仍需持续记录，结束后服务立即停止。',
                      style: TextStyle(color: muted, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: surfaceSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _PermissionFact(
                              icon: Icons.my_location,
                              title: '精确定位',
                              detail: '绘制路线并计算距离',
                            ),
                            SizedBox(height: 12),
                            _PermissionFact(
                              icon: Icons.screen_lock_portrait,
                              title: '后台定位',
                              detail: '锁屏和切后台时继续记录',
                            ),
                            SizedBox(height: 12),
                            _PermissionFact(
                              icon: Icons.visibility_off,
                              title: '隐私保护',
                              detail: '不上传完整轨迹或原始照片',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => _requestLocation(status),
                      icon: const Icon(Icons.location_on),
                      label: Text(status?.isGranted == true ? '继续' : '允许定位'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton.icon(
                        onPressed: () => context.pop(false),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('暂不，返回'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestLocation(PermissionStatus? current) async {
    if (current?.isGranted == true) {
      context.pop(true);
      return;
    }
    final status = await ref
        .read(appPermissionsProvider.notifier)
        .request(AppPermission.location);
    if (!mounted) return;
    if (status.isGranted) {
      context.pop(true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('需要定位权限才能记录轨迹'),
        action: SnackBarAction(
          label: '前往设置',
          onPressed: () =>
              ref.read(appPermissionsProvider.notifier).openSettings(),
        ),
      ),
    );
  }
}

class _PermissionFact extends StatelessWidget {
  const _PermissionFact({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2D6B3F), size: 21),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              detail,
              style: const TextStyle(color: Color(0xFF667268), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(size.width * 0.09, size.height * 0.19)
      ..scale(size.width * 0.82 / 275, size.height * 0.61 / 110);
    final route = Path()
      ..moveTo(10, 90)
      ..relativeCubicTo(45, -85, 100, 15, 150, -52)
      ..relativeCubicTo(45, -58, 80, 27, 105, -23);
    canvas
      ..drawPath(
        route,
        Paint()
          ..color = const Color(0xFF83AA8D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
