import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/database/local_database.dart';
import 'package:xingshe/core/location/trip_statistics.dart';

void main() {
  test('calculates distance while filtering low accuracy drift and jitter', () {
    final start = DateTime.utc(2026, 8, 4);
    final points = [
      _point(1, 0, 0, 5, start),
      _point(2, 1, 1, 200, start.add(const Duration(seconds: 5))),
      _point(3, 0.5, 0, 5, start.add(const Duration(seconds: 10))),
      _point(4, 0.001, 0, 5, start.add(const Duration(seconds: 20))),
      _point(5, 0.00101, 0, 10, start.add(const Duration(seconds: 30))),
    ];

    expect(calculateTripDistance(points), closeTo(111.2, 1));
  });
}

LocalTrackPoint _point(
  int id,
  double latitude,
  double longitude,
  double accuracy,
  DateTime recordedAt,
) => LocalTrackPoint(
  id: id,
  tripId: 'trip-1',
  coordinateSystem: 'WGS84',
  latitude: latitude,
  longitude: longitude,
  accuracy: accuracy,
  recordedAt: recordedAt,
  source: 'gps',
);
