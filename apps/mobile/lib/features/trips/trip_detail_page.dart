import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/local_database.dart';
import '../../core/location/track_synchronizer.dart';

class TripDetailPage extends ConsumerWidget {
  const TripDetailPage({super.key, required this.tripID});

  final String tripID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(localTripDatabaseProvider);
    final trip = (database.select(
      database.localTrips,
    )..where((row) => row.id.equals(tripID))).watchSingleOrNull();
    final photos = (database.select(
      database.localTripPhotos,
    )..where((row) => row.tripId.equals(tripID))).watch();
    return Scaffold(
      key: const Key('trip-detail-page'),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        title: const Text('行程详情'),
      ),
      body: StreamBuilder<LocalTrip?>(
        stream: trip,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final value = snapshot.data;
          if (value == null) return const Center(child: Text('行程不存在'));
          return StreamBuilder<List<LocalTripPhoto>>(
            stream: photos,
            initialData: const [],
            builder: (context, photoSnapshot) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF2D6B3F)),
                    SizedBox(width: 8),
                    Text('已完成', style: TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  value.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _Metric(
                      label: '距离',
                      value: _distance(value.distanceMeters),
                    ),
                    _Metric(
                      label: '时长',
                      value: _duration(value.durationSeconds),
                    ),
                    _Metric(
                      label: '照片',
                      value: '${photoSnapshot.data?.length ?? 0} 张',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF667268), fontSize: 10),
        ),
      ],
    ),
  );
}

String _duration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remaining = seconds % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${remaining.toString().padLeft(2, '0')}';
}

String _distance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(2)} km';
