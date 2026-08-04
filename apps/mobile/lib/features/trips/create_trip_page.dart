import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/trip_recording_controller.dart';
import '../spots/spot_list_page.dart';

const _clearSpot = Object();

class CreateTripPage extends ConsumerStatefulWidget {
  const CreateTripPage({super.key});

  @override
  ConsumerState<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends ConsumerState<CreateTripPage> {
  final _titleController = TextEditingController();
  ShootingSpot? _spot;
  bool _starting = false;
  String? _titleError;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spots = ref.watch(spotListProvider);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(onClose: () => context.go('/')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '开始一次新的行摄',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '给这段路一个名字。开始后，轨迹和照片只保存在本机。',
                      style: TextStyle(
                        color: Color(0xFF667268),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 17),
                    TextField(
                      key: const Key('trip-title-field'),
                      controller: _titleController,
                      maxLength: 40,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: '行程标题',
                        hintText: '例如：滨江追光',
                        errorText: _titleError,
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onChanged: (_) {
                        if (_titleError != null) {
                          setState(() => _titleError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _SpotField(
                      spot: _spot,
                      loading: spots.isLoading,
                      onTap: () => _chooseSpot(spots.value?.items),
                    ),
                    const SizedBox(height: 12),
                    const _PrivacyNotice(),
                    const SizedBox(height: 20),
                    const Text(
                      '开始前确认',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _Fact(icon: Icons.location_on, text: '仅在行摄期间使用定位'),
                    const SizedBox(height: 12),
                    const _Fact(icon: Icons.notifications, text: '后台记录时显示常驻通知'),
                    const SizedBox(height: 12),
                    const _Fact(icon: Icons.stop_circle, text: '结束行摄后立即停止定位'),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      key: const Key('trip-continue-button'),
                      onPressed: _starting ? null : _continue,
                      icon: _starting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward),
                      label: Text(_starting ? '正在开始' : '继续'),
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

  Future<void> _chooseSpot(List<ShootingSpot>? spots) async {
    if (spots == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('机位暂不可用，可先跳过')));
      return;
    }
    final selected = await showModalBottomSheet<Object>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.not_interested),
              title: const Text('不关联机位'),
              onTap: () => Navigator.pop(context, _clearSpot),
            ),
            for (final spot in spots)
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(spot.name),
                subtitle: Text(spot.address ?? '地址待补充'),
                onTap: () => Navigator.pop(context, spot),
              ),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(
      () => _spot = identical(selected, _clearSpot)
          ? null
          : selected as ShootingSpot,
    );
  }

  Future<void> _continue() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = '请输入行程标题');
      return;
    }
    final allowed = await context.push<bool>('/permissions');
    if (!mounted || allowed != true) return;
    setState(() => _starting = true);
    final tripID = _newTripID();
    try {
      await ref
          .read(tripRecordingControllerProvider)
          .createAndStart(id: tripID, title: title, spotID: _spot?.id);
      if (mounted) context.go('/trip/active/$tripID');
    } on Object {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('行摄启动失败，请重试')));
    }
  }

  String _newTripID() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

class TripStartedPage extends StatelessWidget {
  const TripStartedPage({super.key, required this.tripID});

  final String tripID;

  @override
  Widget build(BuildContext context) => Scaffold(
    key: const Key('trip-active-page'),
    backgroundColor: const Color(0xFFEAF0E8),
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route, size: 56, color: Color(0xFF2D6B3F)),
            const SizedBox(height: 12),
            const Text(
              '行摄已开始',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '正在记录本地轨迹',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.outlined(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            tooltip: '关闭',
          ),
          const Text(
            '准备',
            style: TextStyle(
              color: Color(0xFF667268),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _SpotField extends StatelessWidget {
  const _SpotField({
    required this.spot,
    required this.loading,
    required this.onTap,
  });

  final ShootingSpot? spot;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    key: const Key('trip-spot-field'),
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1E9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.photo_camera, color: Color(0xFF2D6B3F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '关联机位（可选）',
                  style: TextStyle(color: Color(0xFF667268), fontSize: 10),
                ),
                const SizedBox(height: 2),
                Text(
                  spot?.name ?? (loading ? '正在加载机位' : '暂不关联'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF667268)),
        ],
      ),
    ),
  );
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F6F3),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Row(
      children: [
        Icon(Icons.lock, color: Color(0xFF2D6B3F)),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('本地优先记录', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text(
                '轨迹和原始照片不会上传',
                style: TextStyle(color: Color(0xFF667268), fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFF2D6B3F), size: 20),
      const SizedBox(width: 10),
      Text(text, style: const TextStyle(fontSize: 12)),
    ],
  );
}
