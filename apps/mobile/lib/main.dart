import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(const ProviderScope(child: XingSheApp()));

class XingSheApp extends StatelessWidget {
  const XingSheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '行摄',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6B3F)),
        useMaterial3: true,
      ),
      home: const _StartupScreen(),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF1E3322),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.photo_camera, size: 52, color: Color(0xFFE85D45)),
              SizedBox(height: 20),
              Text(
                '行摄',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '发现机位，记录每一次追光。',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Icon(Icons.lock, size: 16, color: Color(0xFFD4A020)),
                  SizedBox(width: 8),
                  Text(
                    '轨迹与照片默认只保存在本机',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
