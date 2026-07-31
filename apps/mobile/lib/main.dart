import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(const ProviderScope(child: XingSheApp()));

const _primary = Color(0xFF2D6B3F);
const _primarySoft = Color(0xFFE7F1E9);
const _surfaceSoft = Color(0xFFF4F6F3);
const _surfaceDark = Color(0xFF1E3322);
const _text = Color(0xFF17201A);
const _muted = Color(0xFF667268);
const _coral = Color(0xFFE85D45);

final _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          _AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const _HomePage()),
        GoRoute(path: '/map', builder: (_, _) => const _MapPage()),
        GoRoute(path: '/trip', builder: (_, _) => const _TripPage()),
        GoRoute(path: '/me', builder: (_, _) => const _ProfilePage()),
      ],
    ),
  ],
);

class XingSheApp extends StatelessWidget {
  const XingSheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '行摄',
      routerConfig: _router,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: _primary,
          secondary: _coral,
          surface: Colors.white,
          error: Color(0xFFBA1A1A),
          onSurface: _text,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: _text,
          displayColor: _text,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _coral,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          height: 64,
          backgroundColor: Colors.white,
          indicatorColor: _primarySoft,
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell({required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const paths = ['/', '/map', '/trip', '/me'];
    final index = paths.indexOf(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (value) => context.go(paths[value]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: '地图',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: '行摄',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '下午好，行摄者',
                    style: TextStyle(color: _muted, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '去捕捉今天的光',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const _IconLabel(icon: Icons.location_on, label: '杭州'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 184,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surfaceDark,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.explore, color: Color(0xFFD4A020), size: 18),
                    SizedBox(width: 6),
                    Text(
                      '今日推荐',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
                Spacer(),
                Text(
                  '钱江新城日落线',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '18:24 日落 · 江景与城市天际线',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go('/trip'),
            icon: const Icon(Icons.route),
            label: const Text('开始行摄'),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '附近机位',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => context.go('/map'),
                child: const Text('查看全部'),
              ),
            ],
          ),
          const _PlaceholderBand(icon: Icons.photo_camera, label: '滨江日落机位'),
        ],
      ),
    );
  }
}

class _MapPage extends StatelessWidget {
  const _MapPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          const ColoredBox(color: Color(0xFFEAF0E8), child: SizedBox.expand()),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              child: const ListTile(
                dense: true,
                leading: Icon(Icons.search, color: _muted),
                title: Text(
                  '搜索地点或摄影机位',
                  style: TextStyle(color: _muted, fontSize: 14),
                ),
                trailing: Icon(Icons.tune, color: _primary),
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.map_outlined, size: 64, color: _primary),
          ),
        ],
      ),
    );
  }
}

class _TripPage extends StatelessWidget {
  const _TripPage();

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      eyebrow: '准备',
      title: '开始一次新的行摄',
      icon: Icons.route,
      detail: '轨迹和照片默认只保存在本机',
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    return const _SimplePage(
      eyebrow: '我的',
      title: '常用功能',
      icon: Icons.person,
      detail: '本地行程 · 收藏机位 · 隐私与权限',
    );
  }
}

class _SimplePage extends StatelessWidget {
  const _SimplePage({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.detail,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eyebrow, style: const TextStyle(color: _muted, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 52, color: _primary),
                    const SizedBox(height: 12),
                    Text(
                      detail,
                      style: const TextStyle(color: _muted, fontSize: 13),
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
}

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, color: _primary, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _PlaceholderBand extends StatelessWidget {
  const _PlaceholderBand({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDE3DD)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 80,
            color: _primarySoft,
            child: Icon(icon, color: _primary, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const Icon(Icons.chevron_right, color: _muted),
        ],
      ),
    );
  }
}
