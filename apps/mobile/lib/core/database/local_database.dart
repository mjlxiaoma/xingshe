import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'local_database.g.dart';

class LocalTrips extends Table {
  TextColumn get id => text()();
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

class LocalTrackPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get tripId => text().references(LocalTrips, #id)();
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

class LocalTripPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(LocalTrips, #id)();
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 1) await migrator.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
