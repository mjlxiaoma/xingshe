import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/local_database.dart';
import '../location/track_synchronizer.dart';
import 'media_bridge.dart';

final mediaBridgeProvider = Provider<MediaBridge>((_) => MediaBridge());

final tripPhotoControllerProvider = Provider<TripPhotoController>(
  (ref) => TripPhotoController(
    database: ref.watch(localTripDatabaseProvider),
    mediaBridge: ref.watch(mediaBridgeProvider),
  ),
);

class TripPhotoController {
  TripPhotoController({
    required this.database,
    required this.mediaBridge,
    String Function()? newID,
  }) : _newID = newID ?? _randomID;

  final LocalTripDatabase database;
  final MediaBridge mediaBridge;
  final String Function() _newID;

  Future<LocalTripPhoto?> capture(String tripID) async {
    final trip = await (database.select(
      database.localTrips,
    )..where((row) => row.id.equals(tripID))).getSingleOrNull();
    if (trip == null || !const {'recording', 'paused'}.contains(trip.status)) {
      throw StateError('当前行摄不能添加照片');
    }
    final captured = await mediaBridge.capturePhoto();
    if (captured == null) return null;
    final id = _newID();
    await database
        .into(database.localTripPhotos)
        .insert(
          LocalTripPhotosCompanion.insert(
            id: id,
            tripId: tripID,
            photoSource: const Value('camera'),
            filePath: captured.uri,
            takenAt: captured.takenAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );
    return (database.select(
      database.localTripPhotos,
    )..where((row) => row.id.equals(id))).getSingle();
  }
}

String _randomID() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
