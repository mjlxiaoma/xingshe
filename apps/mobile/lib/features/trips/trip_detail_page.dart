import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/local_database.dart';
import '../../core/location/track_synchronizer.dart';
import '../../core/map/map_provider.dart';

class TripDetailPage extends ConsumerWidget {
  const TripDetailPage({super.key, required this.tripID});

  final String tripID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(localTripDatabaseProvider);
    final trip = (database.select(
      database.localTrips,
    )..where((row) => row.id.equals(tripID))).watchSingleOrNull();
    final tracks =
        (database.select(database.localTrackPoints)
              ..where((row) => row.tripId.equals(tripID))
              ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]))
            .watch();
    final photos = (database.select(
      database.localTripPhotos,
    )..where((row) => row.tripId.equals(tripID))).watch();
    return Scaffold(
      key: const Key('trip-detail-page'),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/trips'),
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
        ),
        title: const Text('行程详情'),
      ),
      body: StreamBuilder<LocalTrip?>(
        stream: trip,
        builder: (context, tripSnapshot) {
          if (tripSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final value = tripSnapshot.data;
          if (value == null) return const Center(child: Text('行程不存在'));
          return StreamBuilder<List<LocalTrackPoint>>(
            stream: tracks,
            initialData: const [],
            builder: (context, trackSnapshot) =>
                StreamBuilder<List<LocalTripPhoto>>(
                  stream: photos,
                  initialData: const [],
                  builder: (context, photoSnapshot) => _DetailContent(
                    trip: value,
                    tracks: trackSnapshot.data ?? const [],
                    photoCount: photoSnapshot.data?.length ?? 0,
                  ),
                ),
          );
        },
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({
    required this.trip,
    required this.tracks,
    required this.photoCount,
  });

  final LocalTrip trip;
  final List<LocalTrackPoint> tracks;
  final int photoCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
    children: [
      SizedBox(
        key: const Key('trip-route-map'),
        height: 236,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: tracks.isEmpty
              ? const _EmptyRoute()
              : MapConsentGate(
                  mapProvider: ref.watch(mapProviderProvider),
                  scene: _scene(trip.id, tracks),
                  onDecline: () =>
                      context.canPop() ? context.pop() : context.go('/trips'),
                  onPrivacy: () => context.push('/privacy'),
                ),
        ),
      ),
      const SizedBox(height: 13),
      Text(
        trip.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 3),
      Text(
        '${_dateTime(trip.startedAt)}${trip.endedAt == null ? '' : ' - ${_time(trip.endedAt!)}'} · 已完成',
        style: const TextStyle(color: Color(0xFF667268), fontSize: 10),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          _Metric(label: '距离', value: _distance(trip.distanceMeters)),
          const SizedBox(width: 6),
          _Metric(label: '时长', value: _duration(trip.durationSeconds)),
          const SizedBox(width: 6),
          _Metric(label: '轨迹点', value: '${tracks.length}'),
          const SizedBox(width: 6),
          _Metric(label: '照片', value: '$photoCount 张'),
        ],
      ),
    ],
  );
}

class _EmptyRoute extends StatelessWidget {
  const _EmptyRoute();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    key: Key('trip-route-empty'),
    color: Color(0xFFEAF0E8),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_outlined, size: 42, color: Color(0xFF2D6B3F)),
          SizedBox(height: 8),
          Text(
            '本次行程没有轨迹点',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF667268), fontSize: 9),
          ),
        ],
      ),
    ),
  );
}

MapScene _scene(String tripID, List<LocalTrackPoint> tracks) {
  final points = tracks
      .map(
        (point) => MapCoordinate(
          latitude: point.latitude,
          longitude: point.longitude,
          system: mapCoordinateSystemFromAPI(point.coordinateSystem),
        ),
      )
      .toList(growable: false);
  final latitudes = points.map((point) => point.latitude);
  final longitudes = points.map((point) => point.longitude);
  final minLatitude = latitudes.reduce((a, b) => a < b ? a : b);
  final maxLatitude = latitudes.reduce((a, b) => a > b ? a : b);
  final minLongitude = longitudes.reduce((a, b) => a < b ? a : b);
  final maxLongitude = longitudes.reduce((a, b) => a > b ? a : b);
  final latitudeSpan = (maxLatitude - minLatitude).abs();
  final longitudeSpan = (maxLongitude - minLongitude).abs();
  final span = latitudeSpan > longitudeSpan ? latitudeSpan : longitudeSpan;
  return MapScene(
    center: MapCoordinate(
      latitude: (minLatitude + maxLatitude) / 2,
      longitude: (minLongitude + maxLongitude) / 2,
      system: points.first.system,
    ),
    zoom: span < 0.01 ? 15 : (span < 0.05 ? 13 : 11),
    markers: [
      MapMarker(id: '$tripID-start', title: '起点', position: points.first),
      MapMarker(id: '$tripID-end', title: '终点', position: points.last),
    ],
    polylines: points.length < 2
        ? const []
        : [MapPolyline(id: tripID, points: points)],
  );
}

String _dateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.year}.${local.month.toString().padLeft(2, '0')}.'
      '${local.day.toString().padLeft(2, '0')}  ${_time(local)}';
}

String _time(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
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
