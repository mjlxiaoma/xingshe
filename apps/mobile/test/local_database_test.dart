import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingshe/core/database/local_database.dart';

void main() {
  late LocalTripDatabase database;

  setUp(() => database = LocalTripDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('initializes and supports trip track photo and spot CRUD', () async {
    final now = DateTime.utc(2026, 7, 31);
    await database
        .into(database.localTrips)
        .insert(
          LocalTripsCompanion.insert(
            id: 'trip-1',
            title: '西湖日落',
            startedAt: now,
            status: 'recording',
            createdAt: now,
            updatedAt: now,
          ),
        );
    final pointID = await database
        .into(database.localTrackPoints)
        .insert(
          LocalTrackPointsCompanion.insert(
            tripId: 'trip-1',
            latitude: 30.25,
            longitude: 120.16,
            recordedAt: now,
            source: 'fused',
          ),
        );
    await database
        .into(database.localTripPhotos)
        .insert(
          LocalTripPhotosCompanion.insert(
            id: 'photo-1',
            tripId: 'trip-1',
            filePath: '/photos/original.jpg',
            takenAt: now,
            createdAt: now,
          ),
        );
    await database
        .into(database.localSpotCache)
        .insert(
          LocalSpotCacheCompanion.insert(
            spotId: 'spot-1',
            name: '北山街',
            latitude: 30.26,
            longitude: 120.14,
            updatedAt: now,
          ),
        );

    expect(pointID, 1);
    expect(
      (await database.select(database.localTrips).getSingle()).title,
      '西湖日落',
    );
    expect(
      await database.select(database.localTrackPoints).get(),
      hasLength(1),
    );
    expect(await database.select(database.localTripPhotos).get(), hasLength(1));
    expect(await database.select(database.localSpotCache).get(), hasLength(1));

    await (database.update(database.localTrips)
          ..where((row) => row.id.equals('trip-1')))
        .write(const LocalTripsCompanion(status: Value('completed')));
    expect(
      (await database.select(database.localTrips).getSingle()).status,
      'completed',
    );

    await (database.delete(
      database.localTripPhotos,
    )..where((row) => row.id.equals('photo-1'))).go();
    expect(await database.select(database.localTripPhotos).get(), isEmpty);
  });
}
