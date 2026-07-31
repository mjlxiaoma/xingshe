// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_database.dart';

// ignore_for_file: type=lint
class $LocalTripsTable extends LocalTrips
    with TableInfo<$LocalTripsTable, LocalTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (status IN (\'draft\', \'recording\', \'paused\', \'completed\'))',
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<double> distanceMeters = GeneratedColumn<double>(
    'distance_meters',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coverPhotoPathMeta = const VerificationMeta(
    'coverPhotoPath',
  );
  @override
  late final GeneratedColumn<String> coverPhotoPath = GeneratedColumn<String>(
    'cover_photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    startedAt,
    endedAt,
    status,
    distanceMeters,
    durationSeconds,
    coverPhotoPath,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTrip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('cover_photo_path')) {
      context.handle(
        _coverPhotoPathMeta,
        coverPhotoPath.isAcceptableOrUnknown(
          data['cover_photo_path']!,
          _coverPhotoPathMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTrip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTrip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance_meters'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      coverPhotoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_photo_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalTripsTable createAlias(String alias) {
    return $LocalTripsTable(attachedDatabase, alias);
  }
}

class LocalTrip extends DataClass implements Insertable<LocalTrip> {
  final String id;
  final String title;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String status;
  final double distanceMeters;
  final int durationSeconds;
  final String? coverPhotoPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalTrip({
    required this.id,
    required this.title,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.distanceMeters,
    required this.durationSeconds,
    this.coverPhotoPath,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['status'] = Variable<String>(status);
    map['distance_meters'] = Variable<double>(distanceMeters);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    if (!nullToAbsent || coverPhotoPath != null) {
      map['cover_photo_path'] = Variable<String>(coverPhotoPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalTripsCompanion toCompanion(bool nullToAbsent) {
    return LocalTripsCompanion(
      id: Value(id),
      title: Value(title),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      status: Value(status),
      distanceMeters: Value(distanceMeters),
      durationSeconds: Value(durationSeconds),
      coverPhotoPath: coverPhotoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPhotoPath),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalTrip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTrip(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      status: serializer.fromJson<String>(json['status']),
      distanceMeters: serializer.fromJson<double>(json['distanceMeters']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      coverPhotoPath: serializer.fromJson<String?>(json['coverPhotoPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'status': serializer.toJson<String>(status),
      'distanceMeters': serializer.toJson<double>(distanceMeters),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'coverPhotoPath': serializer.toJson<String?>(coverPhotoPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalTrip copyWith({
    String? id,
    String? title,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    String? status,
    double? distanceMeters,
    int? durationSeconds,
    Value<String?> coverPhotoPath = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalTrip(
    id: id ?? this.id,
    title: title ?? this.title,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    status: status ?? this.status,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    coverPhotoPath: coverPhotoPath.present
        ? coverPhotoPath.value
        : this.coverPhotoPath,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalTrip copyWithCompanion(LocalTripsCompanion data) {
    return LocalTrip(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      status: data.status.present ? data.status.value : this.status,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      coverPhotoPath: data.coverPhotoPath.present
          ? data.coverPhotoPath.value
          : this.coverPhotoPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrip(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('coverPhotoPath: $coverPhotoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    startedAt,
    endedAt,
    status,
    distanceMeters,
    durationSeconds,
    coverPhotoPath,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTrip &&
          other.id == this.id &&
          other.title == this.title &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.status == this.status &&
          other.distanceMeters == this.distanceMeters &&
          other.durationSeconds == this.durationSeconds &&
          other.coverPhotoPath == this.coverPhotoPath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalTripsCompanion extends UpdateCompanion<LocalTrip> {
  final Value<String> id;
  final Value<String> title;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<String> status;
  final Value<double> distanceMeters;
  final Value<int> durationSeconds;
  final Value<String?> coverPhotoPath;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalTripsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.coverPhotoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTripsCompanion.insert({
    required String id,
    required String title,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    required String status,
    this.distanceMeters = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.coverPhotoPath = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       startedAt = Value(startedAt),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalTrip> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<String>? status,
    Expression<double>? distanceMeters,
    Expression<int>? durationSeconds,
    Expression<String>? coverPhotoPath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (status != null) 'status': status,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (coverPhotoPath != null) 'cover_photo_path': coverPhotoPath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTripsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<String>? status,
    Value<double>? distanceMeters,
    Value<int>? durationSeconds,
    Value<String?>? coverPhotoPath,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalTripsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<double>(distanceMeters.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (coverPhotoPath.present) {
      map['cover_photo_path'] = Variable<String>(coverPhotoPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTripsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('status: $status, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('coverPhotoPath: $coverPhotoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalTrackPointsTable extends LocalTrackPoints
    with TableInfo<$LocalTrackPointsTable, LocalTrackPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTrackPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_trips (id)',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  @override
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _speedMeta = const VerificationMeta('speed');
  @override
  late final GeneratedColumn<double> speed = GeneratedColumn<double>(
    'speed',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bearingMeta = const VerificationMeta(
    'bearing',
  );
  @override
  late final GeneratedColumn<double> bearing = GeneratedColumn<double>(
    'bearing',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (source IN (\'gps\', \'network\', \'fused\'))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    latitude,
    longitude,
    altitude,
    accuracy,
    speed,
    bearing,
    recordedAt,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_track_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTrackPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    }
    if (data.containsKey('speed')) {
      context.handle(
        _speedMeta,
        speed.isAcceptableOrUnknown(data['speed']!, _speedMeta),
      );
    }
    if (data.containsKey('bearing')) {
      context.handle(
        _bearingMeta,
        bearing.isAcceptableOrUnknown(data['bearing']!, _bearingMeta),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTrackPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTrackPoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      ),
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      ),
      speed: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}speed'],
      ),
      bearing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bearing'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $LocalTrackPointsTable createAlias(String alias) {
    return $LocalTrackPointsTable(attachedDatabase, alias);
  }
}

class LocalTrackPoint extends DataClass implements Insertable<LocalTrackPoint> {
  final int id;
  final String tripId;
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speed;
  final double? bearing;
  final DateTime recordedAt;
  final String source;
  const LocalTrackPoint({
    required this.id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speed,
    this.bearing,
    required this.recordedAt,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    if (!nullToAbsent || accuracy != null) {
      map['accuracy'] = Variable<double>(accuracy);
    }
    if (!nullToAbsent || speed != null) {
      map['speed'] = Variable<double>(speed);
    }
    if (!nullToAbsent || bearing != null) {
      map['bearing'] = Variable<double>(bearing);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['source'] = Variable<String>(source);
    return map;
  }

  LocalTrackPointsCompanion toCompanion(bool nullToAbsent) {
    return LocalTrackPointsCompanion(
      id: Value(id),
      tripId: Value(tripId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      accuracy: accuracy == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracy),
      speed: speed == null && nullToAbsent
          ? const Value.absent()
          : Value(speed),
      bearing: bearing == null && nullToAbsent
          ? const Value.absent()
          : Value(bearing),
      recordedAt: Value(recordedAt),
      source: Value(source),
    );
  }

  factory LocalTrackPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTrackPoint(
      id: serializer.fromJson<int>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      accuracy: serializer.fromJson<double?>(json['accuracy']),
      speed: serializer.fromJson<double?>(json['speed']),
      bearing: serializer.fromJson<double?>(json['bearing']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tripId': serializer.toJson<String>(tripId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'altitude': serializer.toJson<double?>(altitude),
      'accuracy': serializer.toJson<double?>(accuracy),
      'speed': serializer.toJson<double?>(speed),
      'bearing': serializer.toJson<double?>(bearing),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'source': serializer.toJson<String>(source),
    };
  }

  LocalTrackPoint copyWith({
    int? id,
    String? tripId,
    double? latitude,
    double? longitude,
    Value<double?> altitude = const Value.absent(),
    Value<double?> accuracy = const Value.absent(),
    Value<double?> speed = const Value.absent(),
    Value<double?> bearing = const Value.absent(),
    DateTime? recordedAt,
    String? source,
  }) => LocalTrackPoint(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    altitude: altitude.present ? altitude.value : this.altitude,
    accuracy: accuracy.present ? accuracy.value : this.accuracy,
    speed: speed.present ? speed.value : this.speed,
    bearing: bearing.present ? bearing.value : this.bearing,
    recordedAt: recordedAt ?? this.recordedAt,
    source: source ?? this.source,
  );
  LocalTrackPoint copyWithCompanion(LocalTrackPointsCompanion data) {
    return LocalTrackPoint(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      speed: data.speed.present ? data.speed.value : this.speed,
      bearing: data.bearing.present ? data.bearing.value : this.bearing,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrackPoint(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('speed: $speed, ')
          ..write('bearing: $bearing, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    latitude,
    longitude,
    altitude,
    accuracy,
    speed,
    bearing,
    recordedAt,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTrackPoint &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.altitude == this.altitude &&
          other.accuracy == this.accuracy &&
          other.speed == this.speed &&
          other.bearing == this.bearing &&
          other.recordedAt == this.recordedAt &&
          other.source == this.source);
}

class LocalTrackPointsCompanion extends UpdateCompanion<LocalTrackPoint> {
  final Value<int> id;
  final Value<String> tripId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> altitude;
  final Value<double?> accuracy;
  final Value<double?> speed;
  final Value<double?> bearing;
  final Value<DateTime> recordedAt;
  final Value<String> source;
  const LocalTrackPointsCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.speed = const Value.absent(),
    this.bearing = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.source = const Value.absent(),
  });
  LocalTrackPointsCompanion.insert({
    this.id = const Value.absent(),
    required String tripId,
    required double latitude,
    required double longitude,
    this.altitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.speed = const Value.absent(),
    this.bearing = const Value.absent(),
    required DateTime recordedAt,
    required String source,
  }) : tripId = Value(tripId),
       latitude = Value(latitude),
       longitude = Value(longitude),
       recordedAt = Value(recordedAt),
       source = Value(source);
  static Insertable<LocalTrackPoint> custom({
    Expression<int>? id,
    Expression<String>? tripId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? altitude,
    Expression<double>? accuracy,
    Expression<double>? speed,
    Expression<double>? bearing,
    Expression<DateTime>? recordedAt,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (speed != null) 'speed': speed,
      if (bearing != null) 'bearing': bearing,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (source != null) 'source': source,
    });
  }

  LocalTrackPointsCompanion copyWith({
    Value<int>? id,
    Value<String>? tripId,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double?>? altitude,
    Value<double?>? accuracy,
    Value<double?>? speed,
    Value<double?>? bearing,
    Value<DateTime>? recordedAt,
    Value<String>? source,
  }) {
    return LocalTrackPointsCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      recordedAt: recordedAt ?? this.recordedAt,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (speed.present) {
      map['speed'] = Variable<double>(speed.value);
    }
    if (bearing.present) {
      map['bearing'] = Variable<double>(bearing.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTrackPointsCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('speed: $speed, ')
          ..write('bearing: $bearing, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

class $LocalTripPhotosTable extends LocalTripPhotos
    with TableInfo<$LocalTripPhotosTable, LocalTripPhoto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalTripPhotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_trips (id)',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailPathMeta = const VerificationMeta(
    'thumbnailPath',
  );
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
    'thumbnail_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _takenAtMeta = const VerificationMeta(
    'takenAt',
  );
  @override
  late final GeneratedColumn<DateTime> takenAt = GeneratedColumn<DateTime>(
    'taken_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tripId,
    filePath,
    thumbnailPath,
    latitude,
    longitude,
    takenAt,
    width,
    height,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_trip_photos';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalTripPhoto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('trip_id')) {
      context.handle(
        _tripIdMeta,
        tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
        _thumbnailPathMeta,
        thumbnailPath.isAcceptableOrUnknown(
          data['thumbnail_path']!,
          _thumbnailPathMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('taken_at')) {
      context.handle(
        _takenAtMeta,
        takenAt.isAcceptableOrUnknown(data['taken_at']!, _takenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_takenAtMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalTripPhoto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalTripPhoto(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      thumbnailPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_path'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      takenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}taken_at'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalTripPhotosTable createAlias(String alias) {
    return $LocalTripPhotosTable(attachedDatabase, alias);
  }
}

class LocalTripPhoto extends DataClass implements Insertable<LocalTripPhoto> {
  final String id;
  final String tripId;
  final String filePath;
  final String? thumbnailPath;
  final double? latitude;
  final double? longitude;
  final DateTime takenAt;
  final int? width;
  final int? height;
  final DateTime createdAt;
  const LocalTripPhoto({
    required this.id,
    required this.tripId,
    required this.filePath,
    this.thumbnailPath,
    this.latitude,
    this.longitude,
    required this.takenAt,
    this.width,
    this.height,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['trip_id'] = Variable<String>(tripId);
    map['file_path'] = Variable<String>(filePath);
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['taken_at'] = Variable<DateTime>(takenAt);
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalTripPhotosCompanion toCompanion(bool nullToAbsent) {
    return LocalTripPhotosCompanion(
      id: Value(id),
      tripId: Value(tripId),
      filePath: Value(filePath),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      takenAt: Value(takenAt),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      createdAt: Value(createdAt),
    );
  }

  factory LocalTripPhoto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalTripPhoto(
      id: serializer.fromJson<String>(json['id']),
      tripId: serializer.fromJson<String>(json['tripId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      takenAt: serializer.fromJson<DateTime>(json['takenAt']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tripId': serializer.toJson<String>(tripId),
      'filePath': serializer.toJson<String>(filePath),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'takenAt': serializer.toJson<DateTime>(takenAt),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalTripPhoto copyWith({
    String? id,
    String? tripId,
    String? filePath,
    Value<String?> thumbnailPath = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    DateTime? takenAt,
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    DateTime? createdAt,
  }) => LocalTripPhoto(
    id: id ?? this.id,
    tripId: tripId ?? this.tripId,
    filePath: filePath ?? this.filePath,
    thumbnailPath: thumbnailPath.present
        ? thumbnailPath.value
        : this.thumbnailPath,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    takenAt: takenAt ?? this.takenAt,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalTripPhoto copyWithCompanion(LocalTripPhotosCompanion data) {
    return LocalTripPhoto(
      id: data.id.present ? data.id.value : this.id,
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      takenAt: data.takenAt.present ? data.takenAt.value : this.takenAt,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalTripPhoto(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('takenAt: $takenAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tripId,
    filePath,
    thumbnailPath,
    latitude,
    longitude,
    takenAt,
    width,
    height,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalTripPhoto &&
          other.id == this.id &&
          other.tripId == this.tripId &&
          other.filePath == this.filePath &&
          other.thumbnailPath == this.thumbnailPath &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.takenAt == this.takenAt &&
          other.width == this.width &&
          other.height == this.height &&
          other.createdAt == this.createdAt);
}

class LocalTripPhotosCompanion extends UpdateCompanion<LocalTripPhoto> {
  final Value<String> id;
  final Value<String> tripId;
  final Value<String> filePath;
  final Value<String?> thumbnailPath;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime> takenAt;
  final Value<int?> width;
  final Value<int?> height;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalTripPhotosCompanion({
    this.id = const Value.absent(),
    this.tripId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.takenAt = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalTripPhotosCompanion.insert({
    required String id,
    required String tripId,
    required String filePath,
    this.thumbnailPath = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required DateTime takenAt,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tripId = Value(tripId),
       filePath = Value(filePath),
       takenAt = Value(takenAt),
       createdAt = Value(createdAt);
  static Insertable<LocalTripPhoto> custom({
    Expression<String>? id,
    Expression<String>? tripId,
    Expression<String>? filePath,
    Expression<String>? thumbnailPath,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? takenAt,
    Expression<int>? width,
    Expression<int>? height,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tripId != null) 'trip_id': tripId,
      if (filePath != null) 'file_path': filePath,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (takenAt != null) 'taken_at': takenAt,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalTripPhotosCompanion copyWith({
    Value<String>? id,
    Value<String>? tripId,
    Value<String>? filePath,
    Value<String?>? thumbnailPath,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<DateTime>? takenAt,
    Value<int?>? width,
    Value<int?>? height,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalTripPhotosCompanion(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      takenAt: takenAt ?? this.takenAt,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (takenAt.present) {
      map['taken_at'] = Variable<DateTime>(takenAt.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalTripPhotosCompanion(')
          ..write('id: $id, ')
          ..write('tripId: $tripId, ')
          ..write('filePath: $filePath, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('takenAt: $takenAt, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSpotCacheTable extends LocalSpotCache
    with TableInfo<$LocalSpotCacheTable, LocalSpotCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSpotCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _spotIdMeta = const VerificationMeta('spotId');
  @override
  late final GeneratedColumn<String> spotId = GeneratedColumn<String>(
    'spot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _coverUrlMeta = const VerificationMeta(
    'coverUrl',
  );
  @override
  late final GeneratedColumn<String> coverUrl = GeneratedColumn<String>(
    'cover_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bestTimeMeta = const VerificationMeta(
    'bestTime',
  );
  @override
  late final GeneratedColumn<String> bestTime = GeneratedColumn<String>(
    'best_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    spotId,
    name,
    description,
    latitude,
    longitude,
    coverUrl,
    bestTime,
    tagsJson,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_spot_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSpotCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('spot_id')) {
      context.handle(
        _spotIdMeta,
        spotId.isAcceptableOrUnknown(data['spot_id']!, _spotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_spotIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('cover_url')) {
      context.handle(
        _coverUrlMeta,
        coverUrl.isAcceptableOrUnknown(data['cover_url']!, _coverUrlMeta),
      );
    }
    if (data.containsKey('best_time')) {
      context.handle(
        _bestTimeMeta,
        bestTime.isAcceptableOrUnknown(data['best_time']!, _bestTimeMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {spotId};
  @override
  LocalSpotCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSpotCacheData(
      spotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}spot_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      coverUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_url'],
      ),
      bestTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}best_time'],
      ),
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalSpotCacheTable createAlias(String alias) {
    return $LocalSpotCacheTable(attachedDatabase, alias);
  }
}

class LocalSpotCacheData extends DataClass
    implements Insertable<LocalSpotCacheData> {
  final String spotId;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final String? coverUrl;
  final String? bestTime;
  final String tagsJson;
  final DateTime updatedAt;
  const LocalSpotCacheData({
    required this.spotId,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.coverUrl,
    this.bestTime,
    required this.tagsJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['spot_id'] = Variable<String>(spotId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || coverUrl != null) {
      map['cover_url'] = Variable<String>(coverUrl);
    }
    if (!nullToAbsent || bestTime != null) {
      map['best_time'] = Variable<String>(bestTime);
    }
    map['tags_json'] = Variable<String>(tagsJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalSpotCacheCompanion toCompanion(bool nullToAbsent) {
    return LocalSpotCacheCompanion(
      spotId: Value(spotId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      latitude: Value(latitude),
      longitude: Value(longitude),
      coverUrl: coverUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(coverUrl),
      bestTime: bestTime == null && nullToAbsent
          ? const Value.absent()
          : Value(bestTime),
      tagsJson: Value(tagsJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalSpotCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSpotCacheData(
      spotId: serializer.fromJson<String>(json['spotId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      coverUrl: serializer.fromJson<String?>(json['coverUrl']),
      bestTime: serializer.fromJson<String?>(json['bestTime']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'spotId': serializer.toJson<String>(spotId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'coverUrl': serializer.toJson<String?>(coverUrl),
      'bestTime': serializer.toJson<String?>(bestTime),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalSpotCacheData copyWith({
    String? spotId,
    String? name,
    Value<String?> description = const Value.absent(),
    double? latitude,
    double? longitude,
    Value<String?> coverUrl = const Value.absent(),
    Value<String?> bestTime = const Value.absent(),
    String? tagsJson,
    DateTime? updatedAt,
  }) => LocalSpotCacheData(
    spotId: spotId ?? this.spotId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    coverUrl: coverUrl.present ? coverUrl.value : this.coverUrl,
    bestTime: bestTime.present ? bestTime.value : this.bestTime,
    tagsJson: tagsJson ?? this.tagsJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalSpotCacheData copyWithCompanion(LocalSpotCacheCompanion data) {
    return LocalSpotCacheData(
      spotId: data.spotId.present ? data.spotId.value : this.spotId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      coverUrl: data.coverUrl.present ? data.coverUrl.value : this.coverUrl,
      bestTime: data.bestTime.present ? data.bestTime.value : this.bestTime,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSpotCacheData(')
          ..write('spotId: $spotId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('bestTime: $bestTime, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    spotId,
    name,
    description,
    latitude,
    longitude,
    coverUrl,
    bestTime,
    tagsJson,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSpotCacheData &&
          other.spotId == this.spotId &&
          other.name == this.name &&
          other.description == this.description &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.coverUrl == this.coverUrl &&
          other.bestTime == this.bestTime &&
          other.tagsJson == this.tagsJson &&
          other.updatedAt == this.updatedAt);
}

class LocalSpotCacheCompanion extends UpdateCompanion<LocalSpotCacheData> {
  final Value<String> spotId;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String?> coverUrl;
  final Value<String?> bestTime;
  final Value<String> tagsJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalSpotCacheCompanion({
    this.spotId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.coverUrl = const Value.absent(),
    this.bestTime = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSpotCacheCompanion.insert({
    required String spotId,
    required String name,
    this.description = const Value.absent(),
    required double latitude,
    required double longitude,
    this.coverUrl = const Value.absent(),
    this.bestTime = const Value.absent(),
    this.tagsJson = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : spotId = Value(spotId),
       name = Value(name),
       latitude = Value(latitude),
       longitude = Value(longitude),
       updatedAt = Value(updatedAt);
  static Insertable<LocalSpotCacheData> custom({
    Expression<String>? spotId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? coverUrl,
    Expression<String>? bestTime,
    Expression<String>? tagsJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (spotId != null) 'spot_id': spotId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (coverUrl != null) 'cover_url': coverUrl,
      if (bestTime != null) 'best_time': bestTime,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSpotCacheCompanion copyWith({
    Value<String>? spotId,
    Value<String>? name,
    Value<String?>? description,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<String?>? coverUrl,
    Value<String?>? bestTime,
    Value<String>? tagsJson,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalSpotCacheCompanion(
      spotId: spotId ?? this.spotId,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      coverUrl: coverUrl ?? this.coverUrl,
      bestTime: bestTime ?? this.bestTime,
      tagsJson: tagsJson ?? this.tagsJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (spotId.present) {
      map['spot_id'] = Variable<String>(spotId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (coverUrl.present) {
      map['cover_url'] = Variable<String>(coverUrl.value);
    }
    if (bestTime.present) {
      map['best_time'] = Variable<String>(bestTime.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSpotCacheCompanion(')
          ..write('spotId: $spotId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('coverUrl: $coverUrl, ')
          ..write('bestTime: $bestTime, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalTripDatabase extends GeneratedDatabase {
  _$LocalTripDatabase(QueryExecutor e) : super(e);
  $LocalTripDatabaseManager get managers => $LocalTripDatabaseManager(this);
  late final $LocalTripsTable localTrips = $LocalTripsTable(this);
  late final $LocalTrackPointsTable localTrackPoints = $LocalTrackPointsTable(
    this,
  );
  late final $LocalTripPhotosTable localTripPhotos = $LocalTripPhotosTable(
    this,
  );
  late final $LocalSpotCacheTable localSpotCache = $LocalSpotCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localTrips,
    localTrackPoints,
    localTripPhotos,
    localSpotCache,
  ];
}

typedef $$LocalTripsTableCreateCompanionBuilder =
    LocalTripsCompanion Function({
      required String id,
      required String title,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      required String status,
      Value<double> distanceMeters,
      Value<int> durationSeconds,
      Value<String?> coverPhotoPath,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalTripsTableUpdateCompanionBuilder =
    LocalTripsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<String> status,
      Value<double> distanceMeters,
      Value<int> durationSeconds,
      Value<String?> coverPhotoPath,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LocalTripsTableReferences
    extends BaseReferences<_$LocalTripDatabase, $LocalTripsTable, LocalTrip> {
  $$LocalTripsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalTrackPointsTable, List<LocalTrackPoint>>
  _localTrackPointsRefsTable(_$LocalTripDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localTrackPoints,
        aliasName: 'local_trips__id__local_track_points__trip_id',
      );

  $$LocalTrackPointsTableProcessedTableManager get localTrackPointsRefs {
    final manager = $$LocalTrackPointsTableTableManager(
      $_db,
      $_db.localTrackPoints,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localTrackPointsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocalTripPhotosTable, List<LocalTripPhoto>>
  _localTripPhotosRefsTable(_$LocalTripDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localTripPhotos,
        aliasName: 'local_trips__id__local_trip_photos__trip_id',
      );

  $$LocalTripPhotosTableProcessedTableManager get localTripPhotosRefs {
    final manager = $$LocalTripPhotosTableTableManager(
      $_db,
      $_db.localTripPhotos,
    ).filter((f) => f.tripId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localTripPhotosRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalTripsTableFilterComposer
    extends Composer<_$LocalTripDatabase, $LocalTripsTable> {
  $$LocalTripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverPhotoPath => $composableBuilder(
    column: $table.coverPhotoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localTrackPointsRefs(
    Expression<bool> Function($$LocalTrackPointsTableFilterComposer f) f,
  ) {
    final $$LocalTrackPointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localTrackPoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrackPointsTableFilterComposer(
            $db: $db,
            $table: $db.localTrackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localTripPhotosRefs(
    Expression<bool> Function($$LocalTripPhotosTableFilterComposer f) f,
  ) {
    final $$LocalTripPhotosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localTripPhotos,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripPhotosTableFilterComposer(
            $db: $db,
            $table: $db.localTripPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalTripsTableOrderingComposer
    extends Composer<_$LocalTripDatabase, $LocalTripsTable> {
  $$LocalTripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverPhotoPath => $composableBuilder(
    column: $table.coverPhotoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalTripsTableAnnotationComposer
    extends Composer<_$LocalTripDatabase, $LocalTripsTable> {
  $$LocalTripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coverPhotoPath => $composableBuilder(
    column: $table.coverPhotoPath,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> localTrackPointsRefs<T extends Object>(
    Expression<T> Function($$LocalTrackPointsTableAnnotationComposer a) f,
  ) {
    final $$LocalTrackPointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localTrackPoints,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTrackPointsTableAnnotationComposer(
            $db: $db,
            $table: $db.localTrackPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localTripPhotosRefs<T extends Object>(
    Expression<T> Function($$LocalTripPhotosTableAnnotationComposer a) f,
  ) {
    final $$LocalTripPhotosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localTripPhotos,
      getReferencedColumn: (t) => t.tripId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripPhotosTableAnnotationComposer(
            $db: $db,
            $table: $db.localTripPhotos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalTripsTableTableManager
    extends
        RootTableManager<
          _$LocalTripDatabase,
          $LocalTripsTable,
          LocalTrip,
          $$LocalTripsTableFilterComposer,
          $$LocalTripsTableOrderingComposer,
          $$LocalTripsTableAnnotationComposer,
          $$LocalTripsTableCreateCompanionBuilder,
          $$LocalTripsTableUpdateCompanionBuilder,
          (LocalTrip, $$LocalTripsTableReferences),
          LocalTrip,
          PrefetchHooks Function({
            bool localTrackPointsRefs,
            bool localTripPhotosRefs,
          })
        > {
  $$LocalTripsTableTableManager(_$LocalTripDatabase db, $LocalTripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> distanceMeters = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String?> coverPhotoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTripsCompanion(
                id: id,
                title: title,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                distanceMeters: distanceMeters,
                durationSeconds: durationSeconds,
                coverPhotoPath: coverPhotoPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                required String status,
                Value<double> distanceMeters = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<String?> coverPhotoPath = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalTripsCompanion.insert(
                id: id,
                title: title,
                startedAt: startedAt,
                endedAt: endedAt,
                status: status,
                distanceMeters: distanceMeters,
                durationSeconds: durationSeconds,
                coverPhotoPath: coverPhotoPath,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalTripsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({localTrackPointsRefs = false, localTripPhotosRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (localTrackPointsRefs) db.localTrackPoints,
                    if (localTripPhotosRefs) db.localTripPhotos,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (localTrackPointsRefs)
                        await $_getPrefetchedData<
                          LocalTrip,
                          $LocalTripsTable,
                          LocalTrackPoint
                        >(
                          currentTable: table,
                          referencedTable: $$LocalTripsTableReferences
                              ._localTrackPointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalTripsTableReferences(
                                db,
                                table,
                                p0,
                              ).localTrackPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (localTripPhotosRefs)
                        await $_getPrefetchedData<
                          LocalTrip,
                          $LocalTripsTable,
                          LocalTripPhoto
                        >(
                          currentTable: table,
                          referencedTable: $$LocalTripsTableReferences
                              ._localTripPhotosRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalTripsTableReferences(
                                db,
                                table,
                                p0,
                              ).localTripPhotosRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.tripId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalTripsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTripDatabase,
      $LocalTripsTable,
      LocalTrip,
      $$LocalTripsTableFilterComposer,
      $$LocalTripsTableOrderingComposer,
      $$LocalTripsTableAnnotationComposer,
      $$LocalTripsTableCreateCompanionBuilder,
      $$LocalTripsTableUpdateCompanionBuilder,
      (LocalTrip, $$LocalTripsTableReferences),
      LocalTrip,
      PrefetchHooks Function({
        bool localTrackPointsRefs,
        bool localTripPhotosRefs,
      })
    >;
typedef $$LocalTrackPointsTableCreateCompanionBuilder =
    LocalTrackPointsCompanion Function({
      Value<int> id,
      required String tripId,
      required double latitude,
      required double longitude,
      Value<double?> altitude,
      Value<double?> accuracy,
      Value<double?> speed,
      Value<double?> bearing,
      required DateTime recordedAt,
      required String source,
    });
typedef $$LocalTrackPointsTableUpdateCompanionBuilder =
    LocalTrackPointsCompanion Function({
      Value<int> id,
      Value<String> tripId,
      Value<double> latitude,
      Value<double> longitude,
      Value<double?> altitude,
      Value<double?> accuracy,
      Value<double?> speed,
      Value<double?> bearing,
      Value<DateTime> recordedAt,
      Value<String> source,
    });

final class $$LocalTrackPointsTableReferences
    extends
        BaseReferences<
          _$LocalTripDatabase,
          $LocalTrackPointsTable,
          LocalTrackPoint
        > {
  $$LocalTrackPointsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalTripsTable _tripIdTable(_$LocalTripDatabase db) =>
      db.localTrips.createAlias('local_track_points__trip_id__local_trips__id');

  $$LocalTripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$LocalTripsTableTableManager(
      $_db,
      $_db.localTrips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalTrackPointsTableFilterComposer
    extends Composer<_$LocalTripDatabase, $LocalTrackPointsTable> {
  $$LocalTrackPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bearing => $composableBuilder(
    column: $table.bearing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalTripsTableFilterComposer get tripId {
    final $$LocalTripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.localTrips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripsTableFilterComposer(
            $db: $db,
            $table: $db.localTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalTrackPointsTableOrderingComposer
    extends Composer<_$LocalTripDatabase, $LocalTrackPointsTable> {
  $$LocalTrackPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get speed => $composableBuilder(
    column: $table.speed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bearing => $composableBuilder(
    column: $table.bearing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalTripsTableOrderingComposer get tripId {
    final $$LocalTripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.localTrips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripsTableOrderingComposer(
            $db: $db,
            $table: $db.localTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalTrackPointsTableAnnotationComposer
    extends Composer<_$LocalTripDatabase, $LocalTrackPointsTable> {
  $$LocalTrackPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<double> get speed =>
      $composableBuilder(column: $table.speed, builder: (column) => column);

  GeneratedColumn<double> get bearing =>
      $composableBuilder(column: $table.bearing, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  $$LocalTripsTableAnnotationComposer get tripId {
    final $$LocalTripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.localTrips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripsTableAnnotationComposer(
            $db: $db,
            $table: $db.localTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalTrackPointsTableTableManager
    extends
        RootTableManager<
          _$LocalTripDatabase,
          $LocalTrackPointsTable,
          LocalTrackPoint,
          $$LocalTrackPointsTableFilterComposer,
          $$LocalTrackPointsTableOrderingComposer,
          $$LocalTrackPointsTableAnnotationComposer,
          $$LocalTrackPointsTableCreateCompanionBuilder,
          $$LocalTrackPointsTableUpdateCompanionBuilder,
          (LocalTrackPoint, $$LocalTrackPointsTableReferences),
          LocalTrackPoint,
          PrefetchHooks Function({bool tripId})
        > {
  $$LocalTrackPointsTableTableManager(
    _$LocalTripDatabase db,
    $LocalTrackPointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTrackPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTrackPointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTrackPointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> bearing = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
              }) => LocalTrackPointsCompanion(
                id: id,
                tripId: tripId,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                accuracy: accuracy,
                speed: speed,
                bearing: bearing,
                recordedAt: recordedAt,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String tripId,
                required double latitude,
                required double longitude,
                Value<double?> altitude = const Value.absent(),
                Value<double?> accuracy = const Value.absent(),
                Value<double?> speed = const Value.absent(),
                Value<double?> bearing = const Value.absent(),
                required DateTime recordedAt,
                required String source,
              }) => LocalTrackPointsCompanion.insert(
                id: id,
                tripId: tripId,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                accuracy: accuracy,
                speed: speed,
                bearing: bearing,
                recordedAt: recordedAt,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalTrackPointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tripId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tripId,
                                referencedTable:
                                    $$LocalTrackPointsTableReferences
                                        ._tripIdTable(db),
                                referencedColumn:
                                    $$LocalTrackPointsTableReferences
                                        ._tripIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalTrackPointsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTripDatabase,
      $LocalTrackPointsTable,
      LocalTrackPoint,
      $$LocalTrackPointsTableFilterComposer,
      $$LocalTrackPointsTableOrderingComposer,
      $$LocalTrackPointsTableAnnotationComposer,
      $$LocalTrackPointsTableCreateCompanionBuilder,
      $$LocalTrackPointsTableUpdateCompanionBuilder,
      (LocalTrackPoint, $$LocalTrackPointsTableReferences),
      LocalTrackPoint,
      PrefetchHooks Function({bool tripId})
    >;
typedef $$LocalTripPhotosTableCreateCompanionBuilder =
    LocalTripPhotosCompanion Function({
      required String id,
      required String tripId,
      required String filePath,
      Value<String?> thumbnailPath,
      Value<double?> latitude,
      Value<double?> longitude,
      required DateTime takenAt,
      Value<int?> width,
      Value<int?> height,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalTripPhotosTableUpdateCompanionBuilder =
    LocalTripPhotosCompanion Function({
      Value<String> id,
      Value<String> tripId,
      Value<String> filePath,
      Value<String?> thumbnailPath,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime> takenAt,
      Value<int?> width,
      Value<int?> height,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$LocalTripPhotosTableReferences
    extends
        BaseReferences<
          _$LocalTripDatabase,
          $LocalTripPhotosTable,
          LocalTripPhoto
        > {
  $$LocalTripPhotosTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalTripsTable _tripIdTable(_$LocalTripDatabase db) =>
      db.localTrips.createAlias('local_trip_photos__trip_id__local_trips__id');

  $$LocalTripsTableProcessedTableManager get tripId {
    final $_column = $_itemColumn<String>('trip_id')!;

    final manager = $$LocalTripsTableTableManager(
      $_db,
      $_db.localTrips,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tripIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalTripPhotosTableFilterComposer
    extends Composer<_$LocalTripDatabase, $LocalTripPhotosTable> {
  $$LocalTripPhotosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalTripsTableFilterComposer get tripId {
    final $$LocalTripsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.localTrips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripsTableFilterComposer(
            $db: $db,
            $table: $db.localTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalTripPhotosTableOrderingComposer
    extends Composer<_$LocalTripDatabase, $LocalTripPhotosTable> {
  $$LocalTripPhotosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get takenAt => $composableBuilder(
    column: $table.takenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalTripsTableOrderingComposer get tripId {
    final $$LocalTripsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.localTrips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripsTableOrderingComposer(
            $db: $db,
            $table: $db.localTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalTripPhotosTableAnnotationComposer
    extends Composer<_$LocalTripDatabase, $LocalTripPhotosTable> {
  $$LocalTripPhotosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
    column: $table.thumbnailPath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get takenAt =>
      $composableBuilder(column: $table.takenAt, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LocalTripsTableAnnotationComposer get tripId {
    final $$LocalTripsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tripId,
      referencedTable: $db.localTrips,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalTripsTableAnnotationComposer(
            $db: $db,
            $table: $db.localTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalTripPhotosTableTableManager
    extends
        RootTableManager<
          _$LocalTripDatabase,
          $LocalTripPhotosTable,
          LocalTripPhoto,
          $$LocalTripPhotosTableFilterComposer,
          $$LocalTripPhotosTableOrderingComposer,
          $$LocalTripPhotosTableAnnotationComposer,
          $$LocalTripPhotosTableCreateCompanionBuilder,
          $$LocalTripPhotosTableUpdateCompanionBuilder,
          (LocalTripPhoto, $$LocalTripPhotosTableReferences),
          LocalTripPhoto,
          PrefetchHooks Function({bool tripId})
        > {
  $$LocalTripPhotosTableTableManager(
    _$LocalTripDatabase db,
    $LocalTripPhotosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalTripPhotosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalTripPhotosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalTripPhotosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tripId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<String?> thumbnailPath = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime> takenAt = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalTripPhotosCompanion(
                id: id,
                tripId: tripId,
                filePath: filePath,
                thumbnailPath: thumbnailPath,
                latitude: latitude,
                longitude: longitude,
                takenAt: takenAt,
                width: width,
                height: height,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tripId,
                required String filePath,
                Value<String?> thumbnailPath = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required DateTime takenAt,
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalTripPhotosCompanion.insert(
                id: id,
                tripId: tripId,
                filePath: filePath,
                thumbnailPath: thumbnailPath,
                latitude: latitude,
                longitude: longitude,
                takenAt: takenAt,
                width: width,
                height: height,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LocalTripPhotosTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({tripId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (tripId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tripId,
                                referencedTable:
                                    $$LocalTripPhotosTableReferences
                                        ._tripIdTable(db),
                                referencedColumn:
                                    $$LocalTripPhotosTableReferences
                                        ._tripIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalTripPhotosTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTripDatabase,
      $LocalTripPhotosTable,
      LocalTripPhoto,
      $$LocalTripPhotosTableFilterComposer,
      $$LocalTripPhotosTableOrderingComposer,
      $$LocalTripPhotosTableAnnotationComposer,
      $$LocalTripPhotosTableCreateCompanionBuilder,
      $$LocalTripPhotosTableUpdateCompanionBuilder,
      (LocalTripPhoto, $$LocalTripPhotosTableReferences),
      LocalTripPhoto,
      PrefetchHooks Function({bool tripId})
    >;
typedef $$LocalSpotCacheTableCreateCompanionBuilder =
    LocalSpotCacheCompanion Function({
      required String spotId,
      required String name,
      Value<String?> description,
      required double latitude,
      required double longitude,
      Value<String?> coverUrl,
      Value<String?> bestTime,
      Value<String> tagsJson,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalSpotCacheTableUpdateCompanionBuilder =
    LocalSpotCacheCompanion Function({
      Value<String> spotId,
      Value<String> name,
      Value<String?> description,
      Value<double> latitude,
      Value<double> longitude,
      Value<String?> coverUrl,
      Value<String?> bestTime,
      Value<String> tagsJson,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalSpotCacheTableFilterComposer
    extends Composer<_$LocalTripDatabase, $LocalSpotCacheTable> {
  $$LocalSpotCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get spotId => $composableBuilder(
    column: $table.spotId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bestTime => $composableBuilder(
    column: $table.bestTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSpotCacheTableOrderingComposer
    extends Composer<_$LocalTripDatabase, $LocalSpotCacheTable> {
  $$LocalSpotCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get spotId => $composableBuilder(
    column: $table.spotId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverUrl => $composableBuilder(
    column: $table.coverUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bestTime => $composableBuilder(
    column: $table.bestTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSpotCacheTableAnnotationComposer
    extends Composer<_$LocalTripDatabase, $LocalSpotCacheTable> {
  $$LocalSpotCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get spotId =>
      $composableBuilder(column: $table.spotId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get coverUrl =>
      $composableBuilder(column: $table.coverUrl, builder: (column) => column);

  GeneratedColumn<String> get bestTime =>
      $composableBuilder(column: $table.bestTime, builder: (column) => column);

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalSpotCacheTableTableManager
    extends
        RootTableManager<
          _$LocalTripDatabase,
          $LocalSpotCacheTable,
          LocalSpotCacheData,
          $$LocalSpotCacheTableFilterComposer,
          $$LocalSpotCacheTableOrderingComposer,
          $$LocalSpotCacheTableAnnotationComposer,
          $$LocalSpotCacheTableCreateCompanionBuilder,
          $$LocalSpotCacheTableUpdateCompanionBuilder,
          (
            LocalSpotCacheData,
            BaseReferences<
              _$LocalTripDatabase,
              $LocalSpotCacheTable,
              LocalSpotCacheData
            >,
          ),
          LocalSpotCacheData,
          PrefetchHooks Function()
        > {
  $$LocalSpotCacheTableTableManager(
    _$LocalTripDatabase db,
    $LocalSpotCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSpotCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSpotCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSpotCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> spotId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> bestTime = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSpotCacheCompanion(
                spotId: spotId,
                name: name,
                description: description,
                latitude: latitude,
                longitude: longitude,
                coverUrl: coverUrl,
                bestTime: bestTime,
                tagsJson: tagsJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String spotId,
                required String name,
                Value<String?> description = const Value.absent(),
                required double latitude,
                required double longitude,
                Value<String?> coverUrl = const Value.absent(),
                Value<String?> bestTime = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalSpotCacheCompanion.insert(
                spotId: spotId,
                name: name,
                description: description,
                latitude: latitude,
                longitude: longitude,
                coverUrl: coverUrl,
                bestTime: bestTime,
                tagsJson: tagsJson,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSpotCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalTripDatabase,
      $LocalSpotCacheTable,
      LocalSpotCacheData,
      $$LocalSpotCacheTableFilterComposer,
      $$LocalSpotCacheTableOrderingComposer,
      $$LocalSpotCacheTableAnnotationComposer,
      $$LocalSpotCacheTableCreateCompanionBuilder,
      $$LocalSpotCacheTableUpdateCompanionBuilder,
      (
        LocalSpotCacheData,
        BaseReferences<
          _$LocalTripDatabase,
          $LocalSpotCacheTable,
          LocalSpotCacheData
        >,
      ),
      LocalSpotCacheData,
      PrefetchHooks Function()
    >;

class $LocalTripDatabaseManager {
  final _$LocalTripDatabase _db;
  $LocalTripDatabaseManager(this._db);
  $$LocalTripsTableTableManager get localTrips =>
      $$LocalTripsTableTableManager(_db, _db.localTrips);
  $$LocalTrackPointsTableTableManager get localTrackPoints =>
      $$LocalTrackPointsTableTableManager(_db, _db.localTrackPoints);
  $$LocalTripPhotosTableTableManager get localTripPhotos =>
      $$LocalTripPhotosTableTableManager(_db, _db.localTripPhotos);
  $$LocalSpotCacheTableTableManager get localSpotCache =>
      $$LocalSpotCacheTableTableManager(_db, _db.localSpotCache);
}
