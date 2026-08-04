import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/local_database.dart';
import '../../core/location/track_synchronizer.dart';

class TripHistoryPage extends ConsumerWidget {
  const TripHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(localTripDatabaseProvider);
    final trips =
        (database.select(database.localTrips)
              ..where((row) => row.status.equals('completed'))
              ..orderBy([(row) => OrderingTerm.desc(row.startedAt)]))
            .watch();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '仅保存在此设备',
                        style: TextStyle(
                          color: Color(0xFF667268),
                          fontSize: 11,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '我的行摄',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  key: const Key('create-trip-button'),
                  onPressed: () => context.push('/trip'),
                  icon: const Icon(Icons.add),
                  tooltip: '新建行摄',
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LocalTrip>>(
              stream: trips,
              initialData: const [],
              builder: (context, snapshot) {
                final values = snapshot.data ?? const [];
                if (values.isEmpty) return const _EmptyHistory();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: values.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _TripCard(values[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => Center(
    key: const Key('trip-history-empty'),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.route, size: 42, color: Color(0xFF2D6B3F)),
          const SizedBox(height: 12),
          const Text(
            '暂无本地行程',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          const Text(
            '完成行摄后，记录会保存在此设备。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF667268), fontSize: 11),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => context.push('/trip'),
            icon: const Icon(Icons.add),
            label: const Text('开始行摄'),
          ),
        ],
      ),
    ),
  );
}

class _TripCard extends StatelessWidget {
  const _TripCard(this.trip);

  final LocalTrip trip;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      key: Key('trip-history-${trip.id}'),
      onTap: () => context.push('/trips/${trip.id}'),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDDE3DD)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            const SizedBox(
              key: Key('trip-history-cover'),
              width: 92,
              height: 92,
              child: ColoredBox(
                color: Color(0xFFEAF0E8),
                child: Icon(
                  Icons.landscape,
                  color: Color(0xFF2D6B3F),
                  size: 30,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _date(trip.startedAt),
                      style: const TextStyle(
                        color: Color(0xFF667268),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trip.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.route,
                          size: 15,
                          color: Color(0xFF2D6B3F),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _distance(trip.distanceMeters),
                          style: const TextStyle(
                            color: Color(0xFF667268),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right, color: Color(0xFF667268)),
            ),
          ],
        ),
      ),
    ),
  );
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')}  '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}

String _distance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(2)} km';
