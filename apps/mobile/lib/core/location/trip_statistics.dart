import 'dart:math';

import 'package:drift/drift.dart';

import '../database/local_database.dart';

const _earthRadiusMeters = 6371008.8;

double calculateTripDistance(
  Iterable<LocalTrackPoint> values, {
  double maxAccuracyMeters = 50,
  double maxSpeedMetersPerSecond = 60,
}) {
  final points = values.toList()
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  LocalTrackPoint? previous;
  var total = 0.0;
  for (final point in points) {
    final accuracy = point.accuracy;
    if (point.latitude < -90 ||
        point.latitude > 90 ||
        point.longitude < -180 ||
        point.longitude > 180 ||
        (accuracy != null && (accuracy < 0 || accuracy > maxAccuracyMeters))) {
      continue;
    }
    if (previous == null) {
      previous = point;
      continue;
    }
    final seconds =
        point.recordedAt.difference(previous.recordedAt).inMilliseconds / 1000;
    if (seconds <= 0) continue;
    final segment = _haversine(previous, point);
    final noiseFloor = max(previous.accuracy ?? 0, accuracy ?? 0);
    if (segment < noiseFloor || segment / seconds > maxSpeedMetersPerSecond) {
      continue;
    }
    total += segment;
    previous = point;
  }
  return total;
}

Future<double> refreshTripDistance(
  LocalTripDatabase database,
  String tripID,
) async {
  final points =
      await (database.select(database.localTrackPoints)
            ..where((row) => row.tripId.equals(tripID))
            ..orderBy([(row) => OrderingTerm.asc(row.recordedAt)]))
          .get();
  final distance = calculateTripDistance(points);
  await (database.update(database.localTrips)
        ..where((row) => row.id.equals(tripID)))
      .write(LocalTripsCompanion(distanceMeters: Value(distance)));
  return distance;
}

double _haversine(LocalTrackPoint start, LocalTrackPoint end) {
  final lat1 = _radians(start.latitude);
  final lat2 = _radians(end.latitude);
  final deltaLat = lat2 - lat1;
  final deltaLon = _radians(end.longitude - start.longitude);
  final a =
      sin(deltaLat / 2) * sin(deltaLat / 2) +
      cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
  final bounded = a.clamp(0.0, 1.0);
  return _earthRadiusMeters * 2 * atan2(sqrt(bounded), sqrt(1 - bounded));
}

double _radians(double degrees) => degrees * pi / 180;
