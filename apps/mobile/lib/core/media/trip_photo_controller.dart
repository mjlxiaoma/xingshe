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
    await _requireActive(tripID);
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

  Future<int> importPhotos(String tripID) async {
    await _requireActive(tripID);
    final photos = await mediaBridge.importPhotos();
    if (photos.isEmpty) return 0;
    final createdAt = DateTime.now().toUtc();
    await database.transaction(() async {
      for (final photo in photos) {
        await database
            .into(database.localTripPhotos)
            .insert(
              LocalTripPhotosCompanion.insert(
                id: _newID(),
                tripId: tripID,
                photoSource: const Value('gallery'),
                filePath: photo.uri,
                takenAt: photo.takenAt,
                createdAt: createdAt,
              ),
            );
      }
    });
    return photos.length;
  }

  Future<void> removeAssociation(String photoID) async {
    final deleted = await (database.delete(
      database.localTripPhotos,
    )..where((row) => row.id.equals(photoID))).go();
    if (deleted != 1) throw StateError('照片关联不存在');
  }

  Future<void> deleteCameraOriginal(String photoID) async {
    final photo = await (database.select(
      database.localTripPhotos,
    )..where((row) => row.id.equals(photoID))).getSingleOrNull();
    if (photo == null) throw StateError('照片关联不存在');
    if (photo.photoSource != 'camera') {
      throw StateError('导入照片的系统原图必须在系统相册中管理');
    }
    await mediaBridge.deletePhoto(photo.filePath);
    await removeAssociation(photoID);
  }

  Future<void> _requireActive(String tripID) async {
    final trip = await (database.select(
      database.localTrips,
    )..where((row) => row.id.equals(tripID))).getSingleOrNull();
    if (trip == null || !const {'recording', 'paused'}.contains(trip.status)) {
      throw StateError('当前行摄不能添加照片');
    }
  }
}

String _randomID() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
