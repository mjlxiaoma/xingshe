import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/location/location_bridge.dart';

void main() {
  test('invokes native methods with validated tracking arguments', () async {
    String? method;
    Object? arguments;
    final bridge = LocationBridge.testing((value, payload) async {
      method = value;
      arguments = payload;
      return value == 'getTrackingStatus' ? {'status': 'idle'} : null;
    }, () => const Stream.empty());

    await bridge.start(tripID: 'trip-1');
    expect(method, 'startLocationTracking');
    expect(arguments, {
      'trip_id': 'trip-1',
      'interval_ms': 5000,
      'min_distance_meters': 10.0,
    });
    expect(await bridge.status(), 'idle');
    await expectLater(
      bridge.start(tripID: '', interval: const Duration(milliseconds: 500)),
      throwsA(
        isA<LocationBridgeException>().having(
          (error) => error.code,
          'code',
          'LOCATION_INVALID_ARGUMENT',
        ),
      ),
    );
  });

  test('decodes events and normalizes platform errors', () async {
    final bridge = LocationBridge.testing(
      (_, _) => throw PlatformException(
        code: 'LOCATION_DENIED',
        message: 'permission denied',
      ),
      () => Stream.value({
        'type': 'location',
        'trip_id': 'trip-1',
        'latitude': 30.2,
        'longitude': 120.1,
        'altitude': 12.0,
        'accuracy': 8.5,
        'speed': 1.2,
        'bearing': 90.0,
        'recorded_at': '2026-01-01T10:00:00Z',
      }),
    );

    final point = await bridge.locations.first;
    expect(point.tripID, 'trip-1');
    expect(point.latitude, 30.2);
    expect(point.recordedAt.isUtc, isTrue);
    await expectLater(
      bridge.pause(),
      throwsA(
        isA<LocationBridgeException>().having(
          (error) => error.code,
          'code',
          'LOCATION_DENIED',
        ),
      ),
    );
  });
}
