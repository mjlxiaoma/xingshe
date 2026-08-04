import 'dart:async';

import 'package:flutter/services.dart';

class NativeLocationPoint {
  const NativeLocationPoint({
    required this.nativeLogID,
    required this.tripID,
    required this.coordinateSystem,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.recordedAt,
    required this.source,
    this.altitude,
    this.speed,
    this.bearing,
  });

  final String nativeLogID;
  final String tripID;
  final String coordinateSystem;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double accuracy;
  final double? speed;
  final double? bearing;
  final DateTime recordedAt;
  final String source;

  factory NativeLocationPoint.fromMap(Object? value) {
    final map = Map<String, Object?>.from(value as Map);
    if (map['type'] != 'location') {
      throw const FormatException('Unsupported location event');
    }
    return NativeLocationPoint(
      nativeLogID: map['native_log_id'] as String,
      tripID: map['trip_id'] as String,
      coordinateSystem: map['coordinate_system'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      bearing: (map['bearing'] as num?)?.toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String).toUtc(),
      source: map['source'] as String,
    );
  }
}

class LocationBridgeException implements Exception {
  const LocationBridgeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

class LocationBridge {
  LocationBridge()
    : this.testing(
        (method, arguments) => const MethodChannel(
          'com.xingshe.app/location',
        ).invokeMethod<Object?>(method, arguments),
        () => const EventChannel(
          'com.xingshe.app/location_events',
        ).receiveBroadcastStream(),
      );

  LocationBridge.testing(this._invoke, this._events);

  final Future<Object?> Function(String method, Object? arguments) _invoke;
  final Stream<Object?> Function() _events;

  Stream<NativeLocationPoint> get locations => _events()
      .map(NativeLocationPoint.fromMap)
      .transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) =>
              sink.addError(_exception(error), stackTrace),
        ),
      );

  Future<void> start({
    required String tripID,
    Duration interval = const Duration(seconds: 5),
    double minDistanceMeters = 10,
  }) async {
    if (tripID.trim().isEmpty ||
        interval.inMilliseconds < 1000 ||
        interval.inMilliseconds > 60000 ||
        minDistanceMeters < 0) {
      throw const LocationBridgeException(
        'LOCATION_INVALID_ARGUMENT',
        '定位参数无效',
      );
    }
    await _call('startLocationTracking', {
      'trip_id': tripID,
      'interval_ms': interval.inMilliseconds,
      'min_distance_meters': minDistanceMeters,
    });
  }

  Future<void> pause() => _call('pauseLocationTracking');

  Future<void> resume() => _call('resumeLocationTracking');

  Future<void> stop() => _call('stopLocationTracking');

  Future<String> status() async {
    final result = Map<String, Object?>.from(
      await _call('getTrackingStatus') as Map,
    );
    return result['status'] as String;
  }

  Future<List<NativeLocationPoint>> pendingPoints({String? tripID}) async =>
      (await _call('getPendingTrackPoints', {'trip_id': ?tripID}) as List)
          .map(NativeLocationPoint.fromMap)
          .toList(growable: false);

  Future<int> clearPendingPoints(List<String> nativeLogIDs) async {
    if (nativeLogIDs.isEmpty) {
      throw const LocationBridgeException(
        'LOCATION_INVALID_ARGUMENT',
        '待清理轨迹编号不能为空',
      );
    }
    final result = Map<String, Object?>.from(
      await _call('clearPendingTrackPoints', {'native_log_ids': nativeLogIDs})
          as Map,
    );
    return result['cleared'] as int;
  }

  Future<Object?> _call(String method, [Object? arguments]) async {
    try {
      return await _invoke(method, arguments);
    } catch (error) {
      throw _exception(error);
    }
  }

  static LocationBridgeException _exception(Object error) =>
      error is PlatformException
      ? LocationBridgeException(error.code, error.message ?? '原生定位调用失败')
      : error is LocationBridgeException
      ? error
      : const LocationBridgeException('LOCATION_CHANNEL_ERROR', '原生定位通道异常');
}
