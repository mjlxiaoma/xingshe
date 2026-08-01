import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'local_database.g.dart';

@TableIndex(name: 'local_trips_started_at', columns: {#startedAt})
class LocalTrips extends Table {
  TextColumn get id => text()();
  TextColumn get spotId => text().nullable()();
  TextColumn get title => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get status => text().customConstraint(
    "NOT NULL CHECK (status IN ('draft', 'recording', 'paused', 'completed'))",
  )();
  RealColumn get distanceMeters => real().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  TextColumn get coverPhotoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(
  name: 'local_track_points_trip_recorded_at',
  columns: {#tripId, #recordedAt},
)
class LocalTrackPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tripId =>
      text().references(LocalTrips, #id, onDelete: KeyAction.cascade)();
  TextColumn get nativeLogId => text().nullable().unique()();
  TextColumn get coordinateSystem => text()
      .withDefault(const Constant('WGS84'))
      // ignore: recursive_getters
      .check(coordinateSystem.isIn(const ['WGS84', 'GCJ02']))();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get altitude => real().nullable()();
  RealColumn get accuracy => real().nullable()();
  RealColumn get speed => real().nullable()();
  RealColumn get bearing => real().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get source => text().customConstraint(
    "NOT NULL CHECK (source IN ('gps', 'network', 'fused'))",
  )();
}

@TableIndex(name: 'local_trip_photos_trip_id', columns: {#tripId})
class LocalTripPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get tripId =>
      text().references(LocalTrips, #id, onDelete: KeyAction.cascade)();
  TextColumn get photoSource => text()
      .withDefault(const Constant('camera'))
      // ignore: recursive_getters
      .check(photoSource.isIn(const ['camera', 'gallery']))();
  // Durable content:// URI for originals; cache paths may be stored separately.
  TextColumn get filePath => text()();
  TextColumn get thumbnailPath => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get takenAt => dateTime()();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class LocalSpotCache extends Table {
  TextColumn get spotId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get coordinateSystem => text()
      .withDefault(const Constant('GCJ02'))
      // ignore: recursive_getters
      .check(coordinateSystem.isIn(const ['WGS84', 'GCJ02']))();
  TextColumn get cityCode => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get coverUrl => text().nullable()();
  TextColumn get bestTime => text().nullable()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {spotId};
}

@DriftDatabase(
  tables: [LocalTrips, LocalTrackPoints, LocalTripPhotos, LocalSpotCache],
)
class LocalTripDatabase extends _$LocalTripDatabase {
  LocalTripDatabase() : super(driftDatabase(name: 'xingshe'));

  LocalTripDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 1) await migrator.createAll();
      if (from < 2) {
        await migrator.addColumn(localTrips, localTrips.spotId);
        await migrator.alterTable(
          TableMigration(
            localTrackPoints,
            newColumns: [
              localTrackPoints.nativeLogId,
              localTrackPoints.coordinateSystem,
            ],
          ),
        );
        await migrator.alterTable(
          TableMigration(
            localTripPhotos,
            newColumns: [localTripPhotos.photoSource],
          ),
        );
        await migrator.addColumn(
          localSpotCache,
          localSpotCache.coordinateSystem,
        );
        await migrator.addColumn(localSpotCache, localSpotCache.cityCode);
        await migrator.addColumn(localSpotCache, localSpotCache.address);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS local_trips_started_at '
          'ON local_trips (started_at)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS local_track_points_trip_recorded_at '
          'ON local_track_points (trip_id, recorded_at)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS local_trip_photos_trip_id '
          'ON local_trip_photos (trip_id)',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
