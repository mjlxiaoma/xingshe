import 'dart:io';

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
            filePath: 'content://media/external/images/media/1',
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

  test('migrates v1 data without loss', () async {
    await database.close();
    final executor = NativeDatabase.memory(
      setup: (raw) {
        raw
          ..execute('''
            CREATE TABLE local_trips (
              id TEXT NOT NULL PRIMARY KEY,
              title TEXT NOT NULL,
              started_at INTEGER NOT NULL,
              ended_at INTEGER,
              status TEXT NOT NULL,
              distance_meters REAL NOT NULL DEFAULT 0,
              duration_seconds INTEGER NOT NULL DEFAULT 0,
              cover_photo_path TEXT,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''')
          ..execute('''
            CREATE TABLE local_track_points (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              trip_id TEXT NOT NULL REFERENCES local_trips(id),
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              altitude REAL,
              accuracy REAL,
              speed REAL,
              bearing REAL,
              recorded_at INTEGER NOT NULL,
              source TEXT NOT NULL
            )
          ''')
          ..execute('''
            CREATE TABLE local_trip_photos (
              id TEXT NOT NULL PRIMARY KEY,
              trip_id TEXT NOT NULL REFERENCES local_trips(id),
              file_path TEXT NOT NULL,
              thumbnail_path TEXT,
              latitude REAL,
              longitude REAL,
              taken_at INTEGER NOT NULL,
              width INTEGER,
              height INTEGER,
              created_at INTEGER NOT NULL
            )
          ''')
          ..execute('''
            CREATE TABLE local_spot_cache (
              spot_id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              description TEXT,
              latitude REAL NOT NULL,
              longitude REAL NOT NULL,
              cover_url TEXT,
              best_time TEXT,
              tags_json TEXT NOT NULL DEFAULT '[]',
              updated_at INTEGER NOT NULL
            )
          ''')
          ..execute(
            "INSERT INTO local_trips VALUES "
            "('trip-old', '旧行程', 1, NULL, 'completed', 0, 0, NULL, 1, 1)",
          )
          ..execute(
            "INSERT INTO local_track_points "
            "(trip_id, latitude, longitude, recorded_at, source) "
            "VALUES ('trip-old', 30, 120, 1, 'gps')",
          )
          ..execute(
            "INSERT INTO local_trip_photos VALUES "
            "('photo-old', 'trip-old', 'content://old', NULL, NULL, NULL, 1, NULL, NULL, 1)",
          )
          ..execute(
            "INSERT INTO local_spot_cache VALUES "
            "('spot-old', '旧机位', NULL, 30, 120, NULL, NULL, '[]', 1)",
          )
          ..execute('PRAGMA user_version = 1');
      },
    );
    final migrated = LocalTripDatabase.forTesting(executor);
    addTearDown(migrated.close);

    expect(
      (await migrated.select(migrated.localTrips).getSingle()).title,
      '旧行程',
    );
    expect(
      (await migrated.select(migrated.localTrackPoints).getSingle())
          .coordinateSystem,
      'WGS84',
    );
    expect(
      (await migrated.select(migrated.localTripPhotos).getSingle()).photoSource,
      'camera',
    );
    expect(
      (await migrated.select(migrated.localSpotCache).getSingle())
          .coordinateSystem,
      'GCJ02',
    );
  });

  test('rejects duplicate native log IDs', () async {
    final now = DateTime.utc(2026, 7, 31);
    await _insertTrip(database, 'trip-1', now);
    final point = LocalTrackPointsCompanion.insert(
      tripId: 'trip-1',
      nativeLogId: const Value('native-1'),
      latitude: 30,
      longitude: 120,
      recordedAt: now,
      source: 'gps',
    );
    await database.into(database.localTrackPoints).insert(point);

    await expectLater(
      database.into(database.localTrackPoints).insert(point),
      throwsA(isA<SqliteException>()),
    );
  });

  test('deleting a trip cascades only its track and photo rows', () async {
    final now = DateTime.utc(2026, 7, 31);
    for (final tripId in ['trip-1', 'trip-2']) {
      await _insertTrip(database, tripId, now);
      await database
          .into(database.localTrackPoints)
          .insert(
            LocalTrackPointsCompanion.insert(
              tripId: tripId,
              latitude: 30,
              longitude: 120,
              recordedAt: now,
              source: 'gps',
            ),
          );
      await database
          .into(database.localTripPhotos)
          .insert(
            LocalTripPhotosCompanion.insert(
              id: 'photo-$tripId',
              tripId: tripId,
              filePath: 'content://$tripId',
              takenAt: now,
              createdAt: now,
            ),
          );
    }

    await (database.delete(
      database.localTrips,
    )..where((row) => row.id.equals('trip-1'))).go();

    expect(
      (await database.select(database.localTrips).getSingle()).id,
      'trip-2',
    );
    expect(
      (await database.select(database.localTrackPoints).getSingle()).tripId,
      'trip-2',
    );
    expect(
      (await database.select(database.localTripPhotos).getSingle()).tripId,
      'trip-2',
    );
  });

  test('Android automatic backup is disabled', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
  });
}

Future<void> _insertTrip(LocalTripDatabase database, String id, DateTime now) =>
    database
        .into(database.localTrips)
        .insert(
          LocalTripsCompanion.insert(
            id: id,
            title: id,
            startedAt: now,
            status: 'recording',
            createdAt: now,
            updatedAt: now,
          ),
        );
