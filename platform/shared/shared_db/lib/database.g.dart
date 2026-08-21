// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid(),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    email,
    passwordHash,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
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
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String username;
  final String email;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime updatedAt;
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['username'] = Variable<String>(username);
    map['email'] = Variable<String>(email);
    map['password_hash'] = Variable<String>(passwordHash);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      email: Value(email),
      passwordHash: Value(passwordHash),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      email: serializer.fromJson<String>(json['email']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'username': serializer.toJson<String>(username),
      'email': serializer.toJson<String>(email),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? passwordHash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    username: username ?? this.username,
    email: email ?? this.email,
    passwordHash: passwordHash ?? this.passwordHash,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      email: data.email.present ? data.email.value : this.email,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, username, email, passwordHash, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.username == this.username &&
          other.email == this.email &&
          other.passwordHash == this.passwordHash &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> username;
  final Value<String> email;
  final Value<String> passwordHash;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.email = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    required String email,
    required String passwordHash,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : username = Value(username),
       email = Value(email),
       passwordHash = Value(passwordHash);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? username,
    Expression<String>? email,
    Expression<String>? passwordHash,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? username,
    Value<String>? email,
    Value<String>? passwordHash,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
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
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
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
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FavoritesTable extends Favorites
    with TableInfo<$FavoritesTable, Favorite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavoritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentTextMeta = const VerificationMeta(
    'contentText',
  );
  @override
  late final GeneratedColumn<String> contentText = GeneratedColumn<String>(
    'content_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contextMeta = const VerificationMeta(
    'context',
  );
  @override
  late final GeneratedColumn<String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cefrLevelMeta = const VerificationMeta(
    'cefrLevel',
  );
  @override
  late final GeneratedColumn<String> cefrLevel = GeneratedColumn<String>(
    'cefr_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTimeMeta = const VerificationMeta(
    'mediaTime',
  );
  @override
  late final GeneratedColumn<double> mediaTime = GeneratedColumn<double>(
    'media_time',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cueIdMeta = const VerificationMeta('cueId');
  @override
  late final GeneratedColumn<String> cueId = GeneratedColumn<String>(
    'cue_id',
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    type,
    contentText,
    context,
    cefrLevel,
    mediaTime,
    cueId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorites';
  @override
  VerificationContext validateIntegrity(
    Insertable<Favorite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content_text')) {
      context.handle(
        _contentTextMeta,
        contentText.isAcceptableOrUnknown(
          data['content_text']!,
          _contentTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentTextMeta);
    }
    if (data.containsKey('context')) {
      context.handle(
        _contextMeta,
        this.context.isAcceptableOrUnknown(data['context']!, _contextMeta),
      );
    }
    if (data.containsKey('cefr_level')) {
      context.handle(
        _cefrLevelMeta,
        cefrLevel.isAcceptableOrUnknown(data['cefr_level']!, _cefrLevelMeta),
      );
    }
    if (data.containsKey('media_time')) {
      context.handle(
        _mediaTimeMeta,
        mediaTime.isAcceptableOrUnknown(data['media_time']!, _mediaTimeMeta),
      );
    }
    if (data.containsKey('cue_id')) {
      context.handle(
        _cueIdMeta,
        cueId.isAcceptableOrUnknown(data['cue_id']!, _cueIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Favorite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Favorite(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      contentText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_text'],
      )!,
      context: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}context'],
      ),
      cefrLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cefr_level'],
      ),
      mediaTime: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}media_time'],
      ),
      cueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cue_id'],
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
  $FavoritesTable createAlias(String alias) {
    return $FavoritesTable(attachedDatabase, alias);
  }
}

class Favorite extends DataClass implements Insertable<Favorite> {
  final String id;
  final String userId;
  final String type;
  final String contentText;
  final String? context;
  final String? cefrLevel;
  final double? mediaTime;
  final String? cueId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Favorite({
    required this.id,
    required this.userId,
    required this.type,
    required this.contentText,
    this.context,
    this.cefrLevel,
    this.mediaTime,
    this.cueId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    map['content_text'] = Variable<String>(contentText);
    if (!nullToAbsent || context != null) {
      map['context'] = Variable<String>(context);
    }
    if (!nullToAbsent || cefrLevel != null) {
      map['cefr_level'] = Variable<String>(cefrLevel);
    }
    if (!nullToAbsent || mediaTime != null) {
      map['media_time'] = Variable<double>(mediaTime);
    }
    if (!nullToAbsent || cueId != null) {
      map['cue_id'] = Variable<String>(cueId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FavoritesCompanion toCompanion(bool nullToAbsent) {
    return FavoritesCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      contentText: Value(contentText),
      context: context == null && nullToAbsent
          ? const Value.absent()
          : Value(context),
      cefrLevel: cefrLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(cefrLevel),
      mediaTime: mediaTime == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaTime),
      cueId: cueId == null && nullToAbsent
          ? const Value.absent()
          : Value(cueId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Favorite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Favorite(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      contentText: serializer.fromJson<String>(json['contentText']),
      context: serializer.fromJson<String?>(json['context']),
      cefrLevel: serializer.fromJson<String?>(json['cefrLevel']),
      mediaTime: serializer.fromJson<double?>(json['mediaTime']),
      cueId: serializer.fromJson<String?>(json['cueId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'contentText': serializer.toJson<String>(contentText),
      'context': serializer.toJson<String?>(context),
      'cefrLevel': serializer.toJson<String?>(cefrLevel),
      'mediaTime': serializer.toJson<double?>(mediaTime),
      'cueId': serializer.toJson<String?>(cueId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Favorite copyWith({
    String? id,
    String? userId,
    String? type,
    String? contentText,
    Value<String?> context = const Value.absent(),
    Value<String?> cefrLevel = const Value.absent(),
    Value<double?> mediaTime = const Value.absent(),
    Value<String?> cueId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Favorite(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    contentText: contentText ?? this.contentText,
    context: context.present ? context.value : this.context,
    cefrLevel: cefrLevel.present ? cefrLevel.value : this.cefrLevel,
    mediaTime: mediaTime.present ? mediaTime.value : this.mediaTime,
    cueId: cueId.present ? cueId.value : this.cueId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Favorite copyWithCompanion(FavoritesCompanion data) {
    return Favorite(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      contentText: data.contentText.present
          ? data.contentText.value
          : this.contentText,
      context: data.context.present ? data.context.value : this.context,
      cefrLevel: data.cefrLevel.present ? data.cefrLevel.value : this.cefrLevel,
      mediaTime: data.mediaTime.present ? data.mediaTime.value : this.mediaTime,
      cueId: data.cueId.present ? data.cueId.value : this.cueId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Favorite(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('contentText: $contentText, ')
          ..write('context: $context, ')
          ..write('cefrLevel: $cefrLevel, ')
          ..write('mediaTime: $mediaTime, ')
          ..write('cueId: $cueId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    type,
    contentText,
    context,
    cefrLevel,
    mediaTime,
    cueId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Favorite &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.contentText == this.contentText &&
          other.context == this.context &&
          other.cefrLevel == this.cefrLevel &&
          other.mediaTime == this.mediaTime &&
          other.cueId == this.cueId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FavoritesCompanion extends UpdateCompanion<Favorite> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<String> contentText;
  final Value<String?> context;
  final Value<String?> cefrLevel;
  final Value<double?> mediaTime;
  final Value<String?> cueId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FavoritesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.contentText = const Value.absent(),
    this.context = const Value.absent(),
    this.cefrLevel = const Value.absent(),
    this.mediaTime = const Value.absent(),
    this.cueId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavoritesCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String type,
    required String contentText,
    this.context = const Value.absent(),
    this.cefrLevel = const Value.absent(),
    this.mediaTime = const Value.absent(),
    this.cueId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       type = Value(type),
       contentText = Value(contentText);
  static Insertable<Favorite> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? contentText,
    Expression<String>? context,
    Expression<String>? cefrLevel,
    Expression<double>? mediaTime,
    Expression<String>? cueId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (contentText != null) 'content_text': contentText,
      if (context != null) 'context': context,
      if (cefrLevel != null) 'cefr_level': cefrLevel,
      if (mediaTime != null) 'media_time': mediaTime,
      if (cueId != null) 'cue_id': cueId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavoritesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? type,
    Value<String>? contentText,
    Value<String?>? context,
    Value<String?>? cefrLevel,
    Value<double?>? mediaTime,
    Value<String?>? cueId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FavoritesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      contentText: contentText ?? this.contentText,
      context: context ?? this.context,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      mediaTime: mediaTime ?? this.mediaTime,
      cueId: cueId ?? this.cueId,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (contentText.present) {
      map['content_text'] = Variable<String>(contentText.value);
    }
    if (context.present) {
      map['context'] = Variable<String>(context.value);
    }
    if (cefrLevel.present) {
      map['cefr_level'] = Variable<String>(cefrLevel.value);
    }
    if (mediaTime.present) {
      map['media_time'] = Variable<double>(mediaTime.value);
    }
    if (cueId.present) {
      map['cue_id'] = Variable<String>(cueId.value);
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
    return (StringBuffer('FavoritesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('contentText: $contentText, ')
          ..write('context: $context, ')
          ..write('cefrLevel: $cefrLevel, ')
          ..write('mediaTime: $mediaTime, ')
          ..write('cueId: $cueId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollocationsTable extends Collocations
    with TableInfo<$CollocationsTable, Collocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collocationTextMeta = const VerificationMeta(
    'collocationText',
  );
  @override
  late final GeneratedColumn<String> collocationText = GeneratedColumn<String>(
    'collocation_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _meaningMeta = const VerificationMeta(
    'meaning',
  );
  @override
  late final GeneratedColumn<String> meaning = GeneratedColumn<String>(
    'meaning',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceCueIdMeta = const VerificationMeta(
    'sourceCueId',
  );
  @override
  late final GeneratedColumn<String> sourceCueId = GeneratedColumn<String>(
    'source_cue_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTextMeta = const VerificationMeta(
    'sourceText',
  );
  @override
  late final GeneratedColumn<String> sourceText = GeneratedColumn<String>(
    'source_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _aiDetectedMeta = const VerificationMeta(
    'aiDetected',
  );
  @override
  late final GeneratedColumn<bool> aiDetected = GeneratedColumn<bool>(
    'ai_detected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ai_detected" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    type,
    collocationText,
    meaning,
    sourceCueId,
    sourceText,
    aiDetected,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collocations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Collocation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('collocation_text')) {
      context.handle(
        _collocationTextMeta,
        collocationText.isAcceptableOrUnknown(
          data['collocation_text']!,
          _collocationTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collocationTextMeta);
    }
    if (data.containsKey('meaning')) {
      context.handle(
        _meaningMeta,
        meaning.isAcceptableOrUnknown(data['meaning']!, _meaningMeta),
      );
    }
    if (data.containsKey('source_cue_id')) {
      context.handle(
        _sourceCueIdMeta,
        sourceCueId.isAcceptableOrUnknown(
          data['source_cue_id']!,
          _sourceCueIdMeta,
        ),
      );
    }
    if (data.containsKey('source_text')) {
      context.handle(
        _sourceTextMeta,
        sourceText.isAcceptableOrUnknown(data['source_text']!, _sourceTextMeta),
      );
    }
    if (data.containsKey('ai_detected')) {
      context.handle(
        _aiDetectedMeta,
        aiDetected.isAcceptableOrUnknown(data['ai_detected']!, _aiDetectedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Collocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Collocation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      collocationText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collocation_text'],
      )!,
      meaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}meaning'],
      ),
      sourceCueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_cue_id'],
      ),
      sourceText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_text'],
      ),
      aiDetected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ai_detected'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CollocationsTable createAlias(String alias) {
    return $CollocationsTable(attachedDatabase, alias);
  }
}

class Collocation extends DataClass implements Insertable<Collocation> {
  final String id;
  final String userId;
  final String type;
  final String collocationText;
  final String? meaning;
  final String? sourceCueId;
  final String? sourceText;
  final bool aiDetected;
  final DateTime createdAt;
  const Collocation({
    required this.id,
    required this.userId,
    required this.type,
    required this.collocationText,
    this.meaning,
    this.sourceCueId,
    this.sourceText,
    required this.aiDetected,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    map['collocation_text'] = Variable<String>(collocationText);
    if (!nullToAbsent || meaning != null) {
      map['meaning'] = Variable<String>(meaning);
    }
    if (!nullToAbsent || sourceCueId != null) {
      map['source_cue_id'] = Variable<String>(sourceCueId);
    }
    if (!nullToAbsent || sourceText != null) {
      map['source_text'] = Variable<String>(sourceText);
    }
    map['ai_detected'] = Variable<bool>(aiDetected);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CollocationsCompanion toCompanion(bool nullToAbsent) {
    return CollocationsCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      collocationText: Value(collocationText),
      meaning: meaning == null && nullToAbsent
          ? const Value.absent()
          : Value(meaning),
      sourceCueId: sourceCueId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceCueId),
      sourceText: sourceText == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceText),
      aiDetected: Value(aiDetected),
      createdAt: Value(createdAt),
    );
  }

  factory Collocation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Collocation(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      collocationText: serializer.fromJson<String>(json['collocationText']),
      meaning: serializer.fromJson<String?>(json['meaning']),
      sourceCueId: serializer.fromJson<String?>(json['sourceCueId']),
      sourceText: serializer.fromJson<String?>(json['sourceText']),
      aiDetected: serializer.fromJson<bool>(json['aiDetected']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'collocationText': serializer.toJson<String>(collocationText),
      'meaning': serializer.toJson<String?>(meaning),
      'sourceCueId': serializer.toJson<String?>(sourceCueId),
      'sourceText': serializer.toJson<String?>(sourceText),
      'aiDetected': serializer.toJson<bool>(aiDetected),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Collocation copyWith({
    String? id,
    String? userId,
    String? type,
    String? collocationText,
    Value<String?> meaning = const Value.absent(),
    Value<String?> sourceCueId = const Value.absent(),
    Value<String?> sourceText = const Value.absent(),
    bool? aiDetected,
    DateTime? createdAt,
  }) => Collocation(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    collocationText: collocationText ?? this.collocationText,
    meaning: meaning.present ? meaning.value : this.meaning,
    sourceCueId: sourceCueId.present ? sourceCueId.value : this.sourceCueId,
    sourceText: sourceText.present ? sourceText.value : this.sourceText,
    aiDetected: aiDetected ?? this.aiDetected,
    createdAt: createdAt ?? this.createdAt,
  );
  Collocation copyWithCompanion(CollocationsCompanion data) {
    return Collocation(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      collocationText: data.collocationText.present
          ? data.collocationText.value
          : this.collocationText,
      meaning: data.meaning.present ? data.meaning.value : this.meaning,
      sourceCueId: data.sourceCueId.present
          ? data.sourceCueId.value
          : this.sourceCueId,
      sourceText: data.sourceText.present
          ? data.sourceText.value
          : this.sourceText,
      aiDetected: data.aiDetected.present
          ? data.aiDetected.value
          : this.aiDetected,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Collocation(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('collocationText: $collocationText, ')
          ..write('meaning: $meaning, ')
          ..write('sourceCueId: $sourceCueId, ')
          ..write('sourceText: $sourceText, ')
          ..write('aiDetected: $aiDetected, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    type,
    collocationText,
    meaning,
    sourceCueId,
    sourceText,
    aiDetected,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Collocation &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.collocationText == this.collocationText &&
          other.meaning == this.meaning &&
          other.sourceCueId == this.sourceCueId &&
          other.sourceText == this.sourceText &&
          other.aiDetected == this.aiDetected &&
          other.createdAt == this.createdAt);
}

class CollocationsCompanion extends UpdateCompanion<Collocation> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<String> collocationText;
  final Value<String?> meaning;
  final Value<String?> sourceCueId;
  final Value<String?> sourceText;
  final Value<bool> aiDetected;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CollocationsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.collocationText = const Value.absent(),
    this.meaning = const Value.absent(),
    this.sourceCueId = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.aiDetected = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollocationsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String type,
    required String collocationText,
    this.meaning = const Value.absent(),
    this.sourceCueId = const Value.absent(),
    this.sourceText = const Value.absent(),
    this.aiDetected = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       type = Value(type),
       collocationText = Value(collocationText);
  static Insertable<Collocation> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? collocationText,
    Expression<String>? meaning,
    Expression<String>? sourceCueId,
    Expression<String>? sourceText,
    Expression<bool>? aiDetected,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (collocationText != null) 'collocation_text': collocationText,
      if (meaning != null) 'meaning': meaning,
      if (sourceCueId != null) 'source_cue_id': sourceCueId,
      if (sourceText != null) 'source_text': sourceText,
      if (aiDetected != null) 'ai_detected': aiDetected,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollocationsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? type,
    Value<String>? collocationText,
    Value<String?>? meaning,
    Value<String?>? sourceCueId,
    Value<String?>? sourceText,
    Value<bool>? aiDetected,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CollocationsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      collocationText: collocationText ?? this.collocationText,
      meaning: meaning ?? this.meaning,
      sourceCueId: sourceCueId ?? this.sourceCueId,
      sourceText: sourceText ?? this.sourceText,
      aiDetected: aiDetected ?? this.aiDetected,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (collocationText.present) {
      map['collocation_text'] = Variable<String>(collocationText.value);
    }
    if (meaning.present) {
      map['meaning'] = Variable<String>(meaning.value);
    }
    if (sourceCueId.present) {
      map['source_cue_id'] = Variable<String>(sourceCueId.value);
    }
    if (sourceText.present) {
      map['source_text'] = Variable<String>(sourceText.value);
    }
    if (aiDetected.present) {
      map['ai_detected'] = Variable<bool>(aiDetected.value);
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
    return (StringBuffer('CollocationsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('collocationText: $collocationText, ')
          ..write('meaning: $meaning, ')
          ..write('sourceCueId: $sourceCueId, ')
          ..write('sourceText: $sourceText, ')
          ..write('aiDetected: $aiDetected, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlashcardsTable extends Flashcards
    with TableInfo<$FlashcardsTable, Flashcard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frontTextMeta = const VerificationMeta(
    'frontText',
  );
  @override
  late final GeneratedColumn<String> frontText = GeneratedColumn<String>(
    'front_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frontHintMeta = const VerificationMeta(
    'frontHint',
  );
  @override
  late final GeneratedColumn<String> frontHint = GeneratedColumn<String>(
    'front_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backAnswerMeta = const VerificationMeta(
    'backAnswer',
  );
  @override
  late final GeneratedColumn<String> backAnswer = GeneratedColumn<String>(
    'back_answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeaningMeta = const VerificationMeta(
    'backMeaning',
  );
  @override
  late final GeneratedColumn<String> backMeaning = GeneratedColumn<String>(
    'back_meaning',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backOriginalMeta = const VerificationMeta(
    'backOriginal',
  );
  @override
  late final GeneratedColumn<String> backOriginal = GeneratedColumn<String>(
    'back_original',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaFilePathMeta = const VerificationMeta(
    'mediaFilePath',
  );
  @override
  late final GeneratedColumn<String> mediaFilePath = GeneratedColumn<String>(
    'media_file_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaFileIdMeta = const VerificationMeta(
    'mediaFileId',
  );
  @override
  late final GeneratedColumn<String> mediaFileId = GeneratedColumn<String>(
    'media_file_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mediaTimeMeta = const VerificationMeta(
    'mediaTime',
  );
  @override
  late final GeneratedColumn<double> mediaTime = GeneratedColumn<double>(
    'media_time',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cueIdMeta = const VerificationMeta('cueId');
  @override
  late final GeneratedColumn<String> cueId = GeneratedColumn<String>(
    'cue_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTitleMeta = const VerificationMeta(
    'sourceTitle',
  );
  @override
  late final GeneratedColumn<String> sourceTitle = GeneratedColumn<String>(
    'source_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextReviewAtMeta = const VerificationMeta(
    'nextReviewAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextReviewAt = GeneratedColumn<DateTime>(
    'next_review_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now().add(const Duration(days: 1)),
  );
  static const VerificationMeta _easeFactorMeta = const VerificationMeta(
    'easeFactor',
  );
  @override
  late final GeneratedColumn<double> easeFactor = GeneratedColumn<double>(
    'ease_factor',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2.5),
  );
  static const VerificationMeta _intervalMeta = const VerificationMeta(
    'interval',
  );
  @override
  late final GeneratedColumn<double> interval = GeneratedColumn<double>(
    'interval',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _aiGeneratedMeta = const VerificationMeta(
    'aiGenerated',
  );
  @override
  late final GeneratedColumn<bool> aiGenerated = GeneratedColumn<bool>(
    'ai_generated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ai_generated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _examplesMeta = const VerificationMeta(
    'examples',
  );
  @override
  late final GeneratedColumn<String> examples = GeneratedColumn<String>(
    'examples',
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    frontText,
    frontHint,
    backAnswer,
    backMeaning,
    backOriginal,
    mediaFilePath,
    mediaFileId,
    mediaTime,
    cueId,
    sourceTitle,
    tags,
    reviewCount,
    nextReviewAt,
    easeFactor,
    interval,
    aiGenerated,
    examples,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcards';
  @override
  VerificationContext validateIntegrity(
    Insertable<Flashcard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('front_text')) {
      context.handle(
        _frontTextMeta,
        frontText.isAcceptableOrUnknown(data['front_text']!, _frontTextMeta),
      );
    } else if (isInserting) {
      context.missing(_frontTextMeta);
    }
    if (data.containsKey('front_hint')) {
      context.handle(
        _frontHintMeta,
        frontHint.isAcceptableOrUnknown(data['front_hint']!, _frontHintMeta),
      );
    }
    if (data.containsKey('back_answer')) {
      context.handle(
        _backAnswerMeta,
        backAnswer.isAcceptableOrUnknown(data['back_answer']!, _backAnswerMeta),
      );
    } else if (isInserting) {
      context.missing(_backAnswerMeta);
    }
    if (data.containsKey('back_meaning')) {
      context.handle(
        _backMeaningMeta,
        backMeaning.isAcceptableOrUnknown(
          data['back_meaning']!,
          _backMeaningMeta,
        ),
      );
    }
    if (data.containsKey('back_original')) {
      context.handle(
        _backOriginalMeta,
        backOriginal.isAcceptableOrUnknown(
          data['back_original']!,
          _backOriginalMeta,
        ),
      );
    }
    if (data.containsKey('media_file_path')) {
      context.handle(
        _mediaFilePathMeta,
        mediaFilePath.isAcceptableOrUnknown(
          data['media_file_path']!,
          _mediaFilePathMeta,
        ),
      );
    }
    if (data.containsKey('media_file_id')) {
      context.handle(
        _mediaFileIdMeta,
        mediaFileId.isAcceptableOrUnknown(
          data['media_file_id']!,
          _mediaFileIdMeta,
        ),
      );
    }
    if (data.containsKey('media_time')) {
      context.handle(
        _mediaTimeMeta,
        mediaTime.isAcceptableOrUnknown(data['media_time']!, _mediaTimeMeta),
      );
    }
    if (data.containsKey('cue_id')) {
      context.handle(
        _cueIdMeta,
        cueId.isAcceptableOrUnknown(data['cue_id']!, _cueIdMeta),
      );
    }
    if (data.containsKey('source_title')) {
      context.handle(
        _sourceTitleMeta,
        sourceTitle.isAcceptableOrUnknown(
          data['source_title']!,
          _sourceTitleMeta,
        ),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    if (data.containsKey('next_review_at')) {
      context.handle(
        _nextReviewAtMeta,
        nextReviewAt.isAcceptableOrUnknown(
          data['next_review_at']!,
          _nextReviewAtMeta,
        ),
      );
    }
    if (data.containsKey('ease_factor')) {
      context.handle(
        _easeFactorMeta,
        easeFactor.isAcceptableOrUnknown(data['ease_factor']!, _easeFactorMeta),
      );
    }
    if (data.containsKey('interval')) {
      context.handle(
        _intervalMeta,
        interval.isAcceptableOrUnknown(data['interval']!, _intervalMeta),
      );
    }
    if (data.containsKey('ai_generated')) {
      context.handle(
        _aiGeneratedMeta,
        aiGenerated.isAcceptableOrUnknown(
          data['ai_generated']!,
          _aiGeneratedMeta,
        ),
      );
    }
    if (data.containsKey('examples')) {
      context.handle(
        _examplesMeta,
        examples.isAcceptableOrUnknown(data['examples']!, _examplesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Flashcard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Flashcard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      frontText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front_text'],
      )!,
      frontHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front_hint'],
      ),
      backAnswer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back_answer'],
      )!,
      backMeaning: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back_meaning'],
      ),
      backOriginal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back_original'],
      ),
      mediaFilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_file_path'],
      ),
      mediaFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_file_id'],
      ),
      mediaTime: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}media_time'],
      ),
      cueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cue_id'],
      ),
      sourceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_title'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
      nextReviewAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_review_at'],
      )!,
      easeFactor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ease_factor'],
      )!,
      interval: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interval'],
      )!,
      aiGenerated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ai_generated'],
      )!,
      examples: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}examples'],
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
  $FlashcardsTable createAlias(String alias) {
    return $FlashcardsTable(attachedDatabase, alias);
  }
}

class Flashcard extends DataClass implements Insertable<Flashcard> {
  final String id;
  final String userId;
  final String frontText;
  final String? frontHint;
  final String backAnswer;
  final String? backMeaning;
  final String? backOriginal;
  final String? mediaFilePath;
  final String? mediaFileId;
  final double? mediaTime;
  final String? cueId;
  final String? sourceTitle;
  final String? tags;
  final int reviewCount;
  final DateTime nextReviewAt;
  final double easeFactor;
  final double interval;
  final bool aiGenerated;
  final String? examples;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Flashcard({
    required this.id,
    required this.userId,
    required this.frontText,
    this.frontHint,
    required this.backAnswer,
    this.backMeaning,
    this.backOriginal,
    this.mediaFilePath,
    this.mediaFileId,
    this.mediaTime,
    this.cueId,
    this.sourceTitle,
    this.tags,
    required this.reviewCount,
    required this.nextReviewAt,
    required this.easeFactor,
    required this.interval,
    required this.aiGenerated,
    this.examples,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['front_text'] = Variable<String>(frontText);
    if (!nullToAbsent || frontHint != null) {
      map['front_hint'] = Variable<String>(frontHint);
    }
    map['back_answer'] = Variable<String>(backAnswer);
    if (!nullToAbsent || backMeaning != null) {
      map['back_meaning'] = Variable<String>(backMeaning);
    }
    if (!nullToAbsent || backOriginal != null) {
      map['back_original'] = Variable<String>(backOriginal);
    }
    if (!nullToAbsent || mediaFilePath != null) {
      map['media_file_path'] = Variable<String>(mediaFilePath);
    }
    if (!nullToAbsent || mediaFileId != null) {
      map['media_file_id'] = Variable<String>(mediaFileId);
    }
    if (!nullToAbsent || mediaTime != null) {
      map['media_time'] = Variable<double>(mediaTime);
    }
    if (!nullToAbsent || cueId != null) {
      map['cue_id'] = Variable<String>(cueId);
    }
    if (!nullToAbsent || sourceTitle != null) {
      map['source_title'] = Variable<String>(sourceTitle);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    map['review_count'] = Variable<int>(reviewCount);
    map['next_review_at'] = Variable<DateTime>(nextReviewAt);
    map['ease_factor'] = Variable<double>(easeFactor);
    map['interval'] = Variable<double>(interval);
    map['ai_generated'] = Variable<bool>(aiGenerated);
    if (!nullToAbsent || examples != null) {
      map['examples'] = Variable<String>(examples);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  FlashcardsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardsCompanion(
      id: Value(id),
      userId: Value(userId),
      frontText: Value(frontText),
      frontHint: frontHint == null && nullToAbsent
          ? const Value.absent()
          : Value(frontHint),
      backAnswer: Value(backAnswer),
      backMeaning: backMeaning == null && nullToAbsent
          ? const Value.absent()
          : Value(backMeaning),
      backOriginal: backOriginal == null && nullToAbsent
          ? const Value.absent()
          : Value(backOriginal),
      mediaFilePath: mediaFilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaFilePath),
      mediaFileId: mediaFileId == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaFileId),
      mediaTime: mediaTime == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaTime),
      cueId: cueId == null && nullToAbsent
          ? const Value.absent()
          : Value(cueId),
      sourceTitle: sourceTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceTitle),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      reviewCount: Value(reviewCount),
      nextReviewAt: Value(nextReviewAt),
      easeFactor: Value(easeFactor),
      interval: Value(interval),
      aiGenerated: Value(aiGenerated),
      examples: examples == null && nullToAbsent
          ? const Value.absent()
          : Value(examples),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Flashcard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Flashcard(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      frontText: serializer.fromJson<String>(json['frontText']),
      frontHint: serializer.fromJson<String?>(json['frontHint']),
      backAnswer: serializer.fromJson<String>(json['backAnswer']),
      backMeaning: serializer.fromJson<String?>(json['backMeaning']),
      backOriginal: serializer.fromJson<String?>(json['backOriginal']),
      mediaFilePath: serializer.fromJson<String?>(json['mediaFilePath']),
      mediaFileId: serializer.fromJson<String?>(json['mediaFileId']),
      mediaTime: serializer.fromJson<double?>(json['mediaTime']),
      cueId: serializer.fromJson<String?>(json['cueId']),
      sourceTitle: serializer.fromJson<String?>(json['sourceTitle']),
      tags: serializer.fromJson<String?>(json['tags']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
      nextReviewAt: serializer.fromJson<DateTime>(json['nextReviewAt']),
      easeFactor: serializer.fromJson<double>(json['easeFactor']),
      interval: serializer.fromJson<double>(json['interval']),
      aiGenerated: serializer.fromJson<bool>(json['aiGenerated']),
      examples: serializer.fromJson<String?>(json['examples']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'frontText': serializer.toJson<String>(frontText),
      'frontHint': serializer.toJson<String?>(frontHint),
      'backAnswer': serializer.toJson<String>(backAnswer),
      'backMeaning': serializer.toJson<String?>(backMeaning),
      'backOriginal': serializer.toJson<String?>(backOriginal),
      'mediaFilePath': serializer.toJson<String?>(mediaFilePath),
      'mediaFileId': serializer.toJson<String?>(mediaFileId),
      'mediaTime': serializer.toJson<double?>(mediaTime),
      'cueId': serializer.toJson<String?>(cueId),
      'sourceTitle': serializer.toJson<String?>(sourceTitle),
      'tags': serializer.toJson<String?>(tags),
      'reviewCount': serializer.toJson<int>(reviewCount),
      'nextReviewAt': serializer.toJson<DateTime>(nextReviewAt),
      'easeFactor': serializer.toJson<double>(easeFactor),
      'interval': serializer.toJson<double>(interval),
      'aiGenerated': serializer.toJson<bool>(aiGenerated),
      'examples': serializer.toJson<String?>(examples),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Flashcard copyWith({
    String? id,
    String? userId,
    String? frontText,
    Value<String?> frontHint = const Value.absent(),
    String? backAnswer,
    Value<String?> backMeaning = const Value.absent(),
    Value<String?> backOriginal = const Value.absent(),
    Value<String?> mediaFilePath = const Value.absent(),
    Value<String?> mediaFileId = const Value.absent(),
    Value<double?> mediaTime = const Value.absent(),
    Value<String?> cueId = const Value.absent(),
    Value<String?> sourceTitle = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    int? reviewCount,
    DateTime? nextReviewAt,
    double? easeFactor,
    double? interval,
    bool? aiGenerated,
    Value<String?> examples = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Flashcard(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    frontText: frontText ?? this.frontText,
    frontHint: frontHint.present ? frontHint.value : this.frontHint,
    backAnswer: backAnswer ?? this.backAnswer,
    backMeaning: backMeaning.present ? backMeaning.value : this.backMeaning,
    backOriginal: backOriginal.present ? backOriginal.value : this.backOriginal,
    mediaFilePath: mediaFilePath.present
        ? mediaFilePath.value
        : this.mediaFilePath,
    mediaFileId: mediaFileId.present ? mediaFileId.value : this.mediaFileId,
    mediaTime: mediaTime.present ? mediaTime.value : this.mediaTime,
    cueId: cueId.present ? cueId.value : this.cueId,
    sourceTitle: sourceTitle.present ? sourceTitle.value : this.sourceTitle,
    tags: tags.present ? tags.value : this.tags,
    reviewCount: reviewCount ?? this.reviewCount,
    nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    easeFactor: easeFactor ?? this.easeFactor,
    interval: interval ?? this.interval,
    aiGenerated: aiGenerated ?? this.aiGenerated,
    examples: examples.present ? examples.value : this.examples,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Flashcard copyWithCompanion(FlashcardsCompanion data) {
    return Flashcard(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      frontText: data.frontText.present ? data.frontText.value : this.frontText,
      frontHint: data.frontHint.present ? data.frontHint.value : this.frontHint,
      backAnswer: data.backAnswer.present
          ? data.backAnswer.value
          : this.backAnswer,
      backMeaning: data.backMeaning.present
          ? data.backMeaning.value
          : this.backMeaning,
      backOriginal: data.backOriginal.present
          ? data.backOriginal.value
          : this.backOriginal,
      mediaFilePath: data.mediaFilePath.present
          ? data.mediaFilePath.value
          : this.mediaFilePath,
      mediaFileId: data.mediaFileId.present
          ? data.mediaFileId.value
          : this.mediaFileId,
      mediaTime: data.mediaTime.present ? data.mediaTime.value : this.mediaTime,
      cueId: data.cueId.present ? data.cueId.value : this.cueId,
      sourceTitle: data.sourceTitle.present
          ? data.sourceTitle.value
          : this.sourceTitle,
      tags: data.tags.present ? data.tags.value : this.tags,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
      nextReviewAt: data.nextReviewAt.present
          ? data.nextReviewAt.value
          : this.nextReviewAt,
      easeFactor: data.easeFactor.present
          ? data.easeFactor.value
          : this.easeFactor,
      interval: data.interval.present ? data.interval.value : this.interval,
      aiGenerated: data.aiGenerated.present
          ? data.aiGenerated.value
          : this.aiGenerated,
      examples: data.examples.present ? data.examples.value : this.examples,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Flashcard(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('frontText: $frontText, ')
          ..write('frontHint: $frontHint, ')
          ..write('backAnswer: $backAnswer, ')
          ..write('backMeaning: $backMeaning, ')
          ..write('backOriginal: $backOriginal, ')
          ..write('mediaFilePath: $mediaFilePath, ')
          ..write('mediaFileId: $mediaFileId, ')
          ..write('mediaTime: $mediaTime, ')
          ..write('cueId: $cueId, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('tags: $tags, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('interval: $interval, ')
          ..write('aiGenerated: $aiGenerated, ')
          ..write('examples: $examples, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    frontText,
    frontHint,
    backAnswer,
    backMeaning,
    backOriginal,
    mediaFilePath,
    mediaFileId,
    mediaTime,
    cueId,
    sourceTitle,
    tags,
    reviewCount,
    nextReviewAt,
    easeFactor,
    interval,
    aiGenerated,
    examples,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Flashcard &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.frontText == this.frontText &&
          other.frontHint == this.frontHint &&
          other.backAnswer == this.backAnswer &&
          other.backMeaning == this.backMeaning &&
          other.backOriginal == this.backOriginal &&
          other.mediaFilePath == this.mediaFilePath &&
          other.mediaFileId == this.mediaFileId &&
          other.mediaTime == this.mediaTime &&
          other.cueId == this.cueId &&
          other.sourceTitle == this.sourceTitle &&
          other.tags == this.tags &&
          other.reviewCount == this.reviewCount &&
          other.nextReviewAt == this.nextReviewAt &&
          other.easeFactor == this.easeFactor &&
          other.interval == this.interval &&
          other.aiGenerated == this.aiGenerated &&
          other.examples == this.examples &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class FlashcardsCompanion extends UpdateCompanion<Flashcard> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> frontText;
  final Value<String?> frontHint;
  final Value<String> backAnswer;
  final Value<String?> backMeaning;
  final Value<String?> backOriginal;
  final Value<String?> mediaFilePath;
  final Value<String?> mediaFileId;
  final Value<double?> mediaTime;
  final Value<String?> cueId;
  final Value<String?> sourceTitle;
  final Value<String?> tags;
  final Value<int> reviewCount;
  final Value<DateTime> nextReviewAt;
  final Value<double> easeFactor;
  final Value<double> interval;
  final Value<bool> aiGenerated;
  final Value<String?> examples;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const FlashcardsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.frontText = const Value.absent(),
    this.frontHint = const Value.absent(),
    this.backAnswer = const Value.absent(),
    this.backMeaning = const Value.absent(),
    this.backOriginal = const Value.absent(),
    this.mediaFilePath = const Value.absent(),
    this.mediaFileId = const Value.absent(),
    this.mediaTime = const Value.absent(),
    this.cueId = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.tags = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.interval = const Value.absent(),
    this.aiGenerated = const Value.absent(),
    this.examples = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlashcardsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String frontText,
    this.frontHint = const Value.absent(),
    required String backAnswer,
    this.backMeaning = const Value.absent(),
    this.backOriginal = const Value.absent(),
    this.mediaFilePath = const Value.absent(),
    this.mediaFileId = const Value.absent(),
    this.mediaTime = const Value.absent(),
    this.cueId = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.tags = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.nextReviewAt = const Value.absent(),
    this.easeFactor = const Value.absent(),
    this.interval = const Value.absent(),
    this.aiGenerated = const Value.absent(),
    this.examples = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       frontText = Value(frontText),
       backAnswer = Value(backAnswer);
  static Insertable<Flashcard> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? frontText,
    Expression<String>? frontHint,
    Expression<String>? backAnswer,
    Expression<String>? backMeaning,
    Expression<String>? backOriginal,
    Expression<String>? mediaFilePath,
    Expression<String>? mediaFileId,
    Expression<double>? mediaTime,
    Expression<String>? cueId,
    Expression<String>? sourceTitle,
    Expression<String>? tags,
    Expression<int>? reviewCount,
    Expression<DateTime>? nextReviewAt,
    Expression<double>? easeFactor,
    Expression<double>? interval,
    Expression<bool>? aiGenerated,
    Expression<String>? examples,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (frontText != null) 'front_text': frontText,
      if (frontHint != null) 'front_hint': frontHint,
      if (backAnswer != null) 'back_answer': backAnswer,
      if (backMeaning != null) 'back_meaning': backMeaning,
      if (backOriginal != null) 'back_original': backOriginal,
      if (mediaFilePath != null) 'media_file_path': mediaFilePath,
      if (mediaFileId != null) 'media_file_id': mediaFileId,
      if (mediaTime != null) 'media_time': mediaTime,
      if (cueId != null) 'cue_id': cueId,
      if (sourceTitle != null) 'source_title': sourceTitle,
      if (tags != null) 'tags': tags,
      if (reviewCount != null) 'review_count': reviewCount,
      if (nextReviewAt != null) 'next_review_at': nextReviewAt,
      if (easeFactor != null) 'ease_factor': easeFactor,
      if (interval != null) 'interval': interval,
      if (aiGenerated != null) 'ai_generated': aiGenerated,
      if (examples != null) 'examples': examples,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlashcardsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? frontText,
    Value<String?>? frontHint,
    Value<String>? backAnswer,
    Value<String?>? backMeaning,
    Value<String?>? backOriginal,
    Value<String?>? mediaFilePath,
    Value<String?>? mediaFileId,
    Value<double?>? mediaTime,
    Value<String?>? cueId,
    Value<String?>? sourceTitle,
    Value<String?>? tags,
    Value<int>? reviewCount,
    Value<DateTime>? nextReviewAt,
    Value<double>? easeFactor,
    Value<double>? interval,
    Value<bool>? aiGenerated,
    Value<String?>? examples,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return FlashcardsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      frontText: frontText ?? this.frontText,
      frontHint: frontHint ?? this.frontHint,
      backAnswer: backAnswer ?? this.backAnswer,
      backMeaning: backMeaning ?? this.backMeaning,
      backOriginal: backOriginal ?? this.backOriginal,
      mediaFilePath: mediaFilePath ?? this.mediaFilePath,
      mediaFileId: mediaFileId ?? this.mediaFileId,
      mediaTime: mediaTime ?? this.mediaTime,
      cueId: cueId ?? this.cueId,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      tags: tags ?? this.tags,
      reviewCount: reviewCount ?? this.reviewCount,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      examples: examples ?? this.examples,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (frontText.present) {
      map['front_text'] = Variable<String>(frontText.value);
    }
    if (frontHint.present) {
      map['front_hint'] = Variable<String>(frontHint.value);
    }
    if (backAnswer.present) {
      map['back_answer'] = Variable<String>(backAnswer.value);
    }
    if (backMeaning.present) {
      map['back_meaning'] = Variable<String>(backMeaning.value);
    }
    if (backOriginal.present) {
      map['back_original'] = Variable<String>(backOriginal.value);
    }
    if (mediaFilePath.present) {
      map['media_file_path'] = Variable<String>(mediaFilePath.value);
    }
    if (mediaFileId.present) {
      map['media_file_id'] = Variable<String>(mediaFileId.value);
    }
    if (mediaTime.present) {
      map['media_time'] = Variable<double>(mediaTime.value);
    }
    if (cueId.present) {
      map['cue_id'] = Variable<String>(cueId.value);
    }
    if (sourceTitle.present) {
      map['source_title'] = Variable<String>(sourceTitle.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (nextReviewAt.present) {
      map['next_review_at'] = Variable<DateTime>(nextReviewAt.value);
    }
    if (easeFactor.present) {
      map['ease_factor'] = Variable<double>(easeFactor.value);
    }
    if (interval.present) {
      map['interval'] = Variable<double>(interval.value);
    }
    if (aiGenerated.present) {
      map['ai_generated'] = Variable<bool>(aiGenerated.value);
    }
    if (examples.present) {
      map['examples'] = Variable<String>(examples.value);
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
    return (StringBuffer('FlashcardsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('frontText: $frontText, ')
          ..write('frontHint: $frontHint, ')
          ..write('backAnswer: $backAnswer, ')
          ..write('backMeaning: $backMeaning, ')
          ..write('backOriginal: $backOriginal, ')
          ..write('mediaFilePath: $mediaFilePath, ')
          ..write('mediaFileId: $mediaFileId, ')
          ..write('mediaTime: $mediaTime, ')
          ..write('cueId: $cueId, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('tags: $tags, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('nextReviewAt: $nextReviewAt, ')
          ..write('easeFactor: $easeFactor, ')
          ..write('interval: $interval, ')
          ..write('aiGenerated: $aiGenerated, ')
          ..write('examples: $examples, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FlashcardReviewsTable extends FlashcardReviews
    with TableInfo<$FlashcardReviewsTable, FlashcardReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlashcardReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid(),
  );
  static const VerificationMeta _flashcardIdMeta = const VerificationMeta(
    'flashcardId',
  );
  @override
  late final GeneratedColumn<String> flashcardId = GeneratedColumn<String>(
    'flashcard_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [id, flashcardId, rating, reviewedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flashcard_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<FlashcardReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('flashcard_id')) {
      context.handle(
        _flashcardIdMeta,
        flashcardId.isAcceptableOrUnknown(
          data['flashcard_id']!,
          _flashcardIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_flashcardIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FlashcardReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FlashcardReview(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      flashcardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flashcard_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
    );
  }

  @override
  $FlashcardReviewsTable createAlias(String alias) {
    return $FlashcardReviewsTable(attachedDatabase, alias);
  }
}

class FlashcardReview extends DataClass implements Insertable<FlashcardReview> {
  final String id;
  final String flashcardId;
  final int rating;
  final DateTime reviewedAt;
  const FlashcardReview({
    required this.id,
    required this.flashcardId,
    required this.rating,
    required this.reviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['flashcard_id'] = Variable<String>(flashcardId);
    map['rating'] = Variable<int>(rating);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    return map;
  }

  FlashcardReviewsCompanion toCompanion(bool nullToAbsent) {
    return FlashcardReviewsCompanion(
      id: Value(id),
      flashcardId: Value(flashcardId),
      rating: Value(rating),
      reviewedAt: Value(reviewedAt),
    );
  }

  factory FlashcardReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FlashcardReview(
      id: serializer.fromJson<String>(json['id']),
      flashcardId: serializer.fromJson<String>(json['flashcardId']),
      rating: serializer.fromJson<int>(json['rating']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'flashcardId': serializer.toJson<String>(flashcardId),
      'rating': serializer.toJson<int>(rating),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
    };
  }

  FlashcardReview copyWith({
    String? id,
    String? flashcardId,
    int? rating,
    DateTime? reviewedAt,
  }) => FlashcardReview(
    id: id ?? this.id,
    flashcardId: flashcardId ?? this.flashcardId,
    rating: rating ?? this.rating,
    reviewedAt: reviewedAt ?? this.reviewedAt,
  );
  FlashcardReview copyWithCompanion(FlashcardReviewsCompanion data) {
    return FlashcardReview(
      id: data.id.present ? data.id.value : this.id,
      flashcardId: data.flashcardId.present
          ? data.flashcardId.value
          : this.flashcardId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardReview(')
          ..write('id: $id, ')
          ..write('flashcardId: $flashcardId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, flashcardId, rating, reviewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlashcardReview &&
          other.id == this.id &&
          other.flashcardId == this.flashcardId &&
          other.rating == this.rating &&
          other.reviewedAt == this.reviewedAt);
}

class FlashcardReviewsCompanion extends UpdateCompanion<FlashcardReview> {
  final Value<String> id;
  final Value<String> flashcardId;
  final Value<int> rating;
  final Value<DateTime> reviewedAt;
  final Value<int> rowid;
  const FlashcardReviewsCompanion({
    this.id = const Value.absent(),
    this.flashcardId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FlashcardReviewsCompanion.insert({
    this.id = const Value.absent(),
    required String flashcardId,
    required int rating,
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : flashcardId = Value(flashcardId),
       rating = Value(rating);
  static Insertable<FlashcardReview> custom({
    Expression<String>? id,
    Expression<String>? flashcardId,
    Expression<int>? rating,
    Expression<DateTime>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (flashcardId != null) 'flashcard_id': flashcardId,
      if (rating != null) 'rating': rating,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FlashcardReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? flashcardId,
    Value<int>? rating,
    Value<DateTime>? reviewedAt,
    Value<int>? rowid,
  }) {
    return FlashcardReviewsCompanion(
      id: id ?? this.id,
      flashcardId: flashcardId ?? this.flashcardId,
      rating: rating ?? this.rating,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (flashcardId.present) {
      map['flashcard_id'] = Variable<String>(flashcardId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlashcardReviewsCompanion(')
          ..write('id: $id, ')
          ..write('flashcardId: $flashcardId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStatusTable extends SyncStatus
    with TableInfo<$SyncStatusTable, SyncStatusData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStatusTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncedAtMeta = const VerificationMeta(
    'lastSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncedAt = GeneratedColumn<DateTime>(
    'last_synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverGenerationMeta = const VerificationMeta(
    'serverGeneration',
  );
  @override
  late final GeneratedColumn<int> serverGeneration = GeneratedColumn<int>(
    'server_generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    lastSyncedAt,
    serverGeneration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_status';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStatusData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('last_synced_at')) {
      context.handle(
        _lastSyncedAtMeta,
        lastSyncedAt.isAcceptableOrUnknown(
          data['last_synced_at']!,
          _lastSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('server_generation')) {
      context.handle(
        _serverGenerationMeta,
        serverGeneration.isAcceptableOrUnknown(
          data['server_generation']!,
          _serverGenerationMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  SyncStatusData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStatusData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      lastSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_synced_at'],
      ),
      serverGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_generation'],
      )!,
    );
  }

  @override
  $SyncStatusTable createAlias(String alias) {
    return $SyncStatusTable(attachedDatabase, alias);
  }
}

class SyncStatusData extends DataClass implements Insertable<SyncStatusData> {
  final String userId;
  final DateTime? lastSyncedAt;
  final int serverGeneration;
  const SyncStatusData({
    required this.userId,
    this.lastSyncedAt,
    required this.serverGeneration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || lastSyncedAt != null) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt);
    }
    map['server_generation'] = Variable<int>(serverGeneration);
    return map;
  }

  SyncStatusCompanion toCompanion(bool nullToAbsent) {
    return SyncStatusCompanion(
      userId: Value(userId),
      lastSyncedAt: lastSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncedAt),
      serverGeneration: Value(serverGeneration),
    );
  }

  factory SyncStatusData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStatusData(
      userId: serializer.fromJson<String>(json['userId']),
      lastSyncedAt: serializer.fromJson<DateTime?>(json['lastSyncedAt']),
      serverGeneration: serializer.fromJson<int>(json['serverGeneration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'lastSyncedAt': serializer.toJson<DateTime?>(lastSyncedAt),
      'serverGeneration': serializer.toJson<int>(serverGeneration),
    };
  }

  SyncStatusData copyWith({
    String? userId,
    Value<DateTime?> lastSyncedAt = const Value.absent(),
    int? serverGeneration,
  }) => SyncStatusData(
    userId: userId ?? this.userId,
    lastSyncedAt: lastSyncedAt.present ? lastSyncedAt.value : this.lastSyncedAt,
    serverGeneration: serverGeneration ?? this.serverGeneration,
  );
  SyncStatusData copyWithCompanion(SyncStatusCompanion data) {
    return SyncStatusData(
      userId: data.userId.present ? data.userId.value : this.userId,
      lastSyncedAt: data.lastSyncedAt.present
          ? data.lastSyncedAt.value
          : this.lastSyncedAt,
      serverGeneration: data.serverGeneration.present
          ? data.serverGeneration.value
          : this.serverGeneration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatusData(')
          ..write('userId: $userId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('serverGeneration: $serverGeneration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, lastSyncedAt, serverGeneration);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStatusData &&
          other.userId == this.userId &&
          other.lastSyncedAt == this.lastSyncedAt &&
          other.serverGeneration == this.serverGeneration);
}

class SyncStatusCompanion extends UpdateCompanion<SyncStatusData> {
  final Value<String> userId;
  final Value<DateTime?> lastSyncedAt;
  final Value<int> serverGeneration;
  final Value<int> rowid;
  const SyncStatusCompanion({
    this.userId = const Value.absent(),
    this.lastSyncedAt = const Value.absent(),
    this.serverGeneration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStatusCompanion.insert({
    required String userId,
    this.lastSyncedAt = const Value.absent(),
    this.serverGeneration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<SyncStatusData> custom({
    Expression<String>? userId,
    Expression<DateTime>? lastSyncedAt,
    Expression<int>? serverGeneration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (lastSyncedAt != null) 'last_synced_at': lastSyncedAt,
      if (serverGeneration != null) 'server_generation': serverGeneration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStatusCompanion copyWith({
    Value<String>? userId,
    Value<DateTime?>? lastSyncedAt,
    Value<int>? serverGeneration,
    Value<int>? rowid,
  }) {
    return SyncStatusCompanion(
      userId: userId ?? this.userId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      serverGeneration: serverGeneration ?? this.serverGeneration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (lastSyncedAt.present) {
      map['last_synced_at'] = Variable<DateTime>(lastSyncedAt.value);
    }
    if (serverGeneration.present) {
      map['server_generation'] = Variable<int>(serverGeneration.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStatusCompanion(')
          ..write('userId: $userId, ')
          ..write('lastSyncedAt: $lastSyncedAt, ')
          ..write('serverGeneration: $serverGeneration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ListeningHistoryTable extends ListeningHistory
    with TableInfo<$ListeningHistoryTable, ListeningHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ListeningHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaPathMeta = const VerificationMeta(
    'mediaPath',
  );
  @override
  late final GeneratedColumn<String> mediaPath = GeneratedColumn<String>(
    'media_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mediaNameMeta = const VerificationMeta(
    'mediaName',
  );
  @override
  late final GeneratedColumn<String> mediaName = GeneratedColumn<String>(
    'media_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitlePathMeta = const VerificationMeta(
    'subtitlePath',
  );
  @override
  late final GeneratedColumn<String> subtitlePath = GeneratedColumn<String>(
    'subtitle_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtitleContentMeta = const VerificationMeta(
    'subtitleContent',
  );
  @override
  late final GeneratedColumn<String> subtitleContent = GeneratedColumn<String>(
    'subtitle_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeIndexMeta = const VerificationMeta(
    'episodeIndex',
  );
  @override
  late final GeneratedColumn<String> episodeIndex = GeneratedColumn<String>(
    'episode_index',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeTitleMeta = const VerificationMeta(
    'episodeTitle',
  );
  @override
  late final GeneratedColumn<String> episodeTitle = GeneratedColumn<String>(
    'episode_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    mediaPath,
    mediaName,
    subtitlePath,
    subtitleContent,
    progress,
    duration,
    episodeIndex,
    episodeTitle,
    lastPlayedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'listening_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ListeningHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('media_path')) {
      context.handle(
        _mediaPathMeta,
        mediaPath.isAcceptableOrUnknown(data['media_path']!, _mediaPathMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaPathMeta);
    }
    if (data.containsKey('media_name')) {
      context.handle(
        _mediaNameMeta,
        mediaName.isAcceptableOrUnknown(data['media_name']!, _mediaNameMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaNameMeta);
    }
    if (data.containsKey('subtitle_path')) {
      context.handle(
        _subtitlePathMeta,
        subtitlePath.isAcceptableOrUnknown(
          data['subtitle_path']!,
          _subtitlePathMeta,
        ),
      );
    }
    if (data.containsKey('subtitle_content')) {
      context.handle(
        _subtitleContentMeta,
        subtitleContent.isAcceptableOrUnknown(
          data['subtitle_content']!,
          _subtitleContentMeta,
        ),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('episode_index')) {
      context.handle(
        _episodeIndexMeta,
        episodeIndex.isAcceptableOrUnknown(
          data['episode_index']!,
          _episodeIndexMeta,
        ),
      );
    }
    if (data.containsKey('episode_title')) {
      context.handle(
        _episodeTitleMeta,
        episodeTitle.isAcceptableOrUnknown(
          data['episode_title']!,
          _episodeTitleMeta,
        ),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ListeningHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ListeningHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      mediaPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_path'],
      )!,
      mediaName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_name'],
      )!,
      subtitlePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle_path'],
      ),
      subtitleContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle_content'],
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration'],
      ),
      episodeIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_index'],
      ),
      episodeTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_title'],
      ),
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ListeningHistoryTable createAlias(String alias) {
    return $ListeningHistoryTable(attachedDatabase, alias);
  }
}

class ListeningHistoryData extends DataClass
    implements Insertable<ListeningHistoryData> {
  final String id;
  final String userId;
  final String mediaPath;
  final String mediaName;
  final String? subtitlePath;
  final String? subtitleContent;
  final double progress;
  final double? duration;
  final String? episodeIndex;
  final String? episodeTitle;
  final DateTime lastPlayedAt;
  final DateTime createdAt;
  const ListeningHistoryData({
    required this.id,
    required this.userId,
    required this.mediaPath,
    required this.mediaName,
    this.subtitlePath,
    this.subtitleContent,
    required this.progress,
    this.duration,
    this.episodeIndex,
    this.episodeTitle,
    required this.lastPlayedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['media_path'] = Variable<String>(mediaPath);
    map['media_name'] = Variable<String>(mediaName);
    if (!nullToAbsent || subtitlePath != null) {
      map['subtitle_path'] = Variable<String>(subtitlePath);
    }
    if (!nullToAbsent || subtitleContent != null) {
      map['subtitle_content'] = Variable<String>(subtitleContent);
    }
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<double>(duration);
    }
    if (!nullToAbsent || episodeIndex != null) {
      map['episode_index'] = Variable<String>(episodeIndex);
    }
    if (!nullToAbsent || episodeTitle != null) {
      map['episode_title'] = Variable<String>(episodeTitle);
    }
    map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ListeningHistoryCompanion toCompanion(bool nullToAbsent) {
    return ListeningHistoryCompanion(
      id: Value(id),
      userId: Value(userId),
      mediaPath: Value(mediaPath),
      mediaName: Value(mediaName),
      subtitlePath: subtitlePath == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitlePath),
      subtitleContent: subtitleContent == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitleContent),
      progress: Value(progress),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      episodeIndex: episodeIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeIndex),
      episodeTitle: episodeTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeTitle),
      lastPlayedAt: Value(lastPlayedAt),
      createdAt: Value(createdAt),
    );
  }

  factory ListeningHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ListeningHistoryData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      mediaPath: serializer.fromJson<String>(json['mediaPath']),
      mediaName: serializer.fromJson<String>(json['mediaName']),
      subtitlePath: serializer.fromJson<String?>(json['subtitlePath']),
      subtitleContent: serializer.fromJson<String?>(json['subtitleContent']),
      progress: serializer.fromJson<double>(json['progress']),
      duration: serializer.fromJson<double?>(json['duration']),
      episodeIndex: serializer.fromJson<String?>(json['episodeIndex']),
      episodeTitle: serializer.fromJson<String?>(json['episodeTitle']),
      lastPlayedAt: serializer.fromJson<DateTime>(json['lastPlayedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'mediaPath': serializer.toJson<String>(mediaPath),
      'mediaName': serializer.toJson<String>(mediaName),
      'subtitlePath': serializer.toJson<String?>(subtitlePath),
      'subtitleContent': serializer.toJson<String?>(subtitleContent),
      'progress': serializer.toJson<double>(progress),
      'duration': serializer.toJson<double?>(duration),
      'episodeIndex': serializer.toJson<String?>(episodeIndex),
      'episodeTitle': serializer.toJson<String?>(episodeTitle),
      'lastPlayedAt': serializer.toJson<DateTime>(lastPlayedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ListeningHistoryData copyWith({
    String? id,
    String? userId,
    String? mediaPath,
    String? mediaName,
    Value<String?> subtitlePath = const Value.absent(),
    Value<String?> subtitleContent = const Value.absent(),
    double? progress,
    Value<double?> duration = const Value.absent(),
    Value<String?> episodeIndex = const Value.absent(),
    Value<String?> episodeTitle = const Value.absent(),
    DateTime? lastPlayedAt,
    DateTime? createdAt,
  }) => ListeningHistoryData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    mediaPath: mediaPath ?? this.mediaPath,
    mediaName: mediaName ?? this.mediaName,
    subtitlePath: subtitlePath.present ? subtitlePath.value : this.subtitlePath,
    subtitleContent: subtitleContent.present
        ? subtitleContent.value
        : this.subtitleContent,
    progress: progress ?? this.progress,
    duration: duration.present ? duration.value : this.duration,
    episodeIndex: episodeIndex.present ? episodeIndex.value : this.episodeIndex,
    episodeTitle: episodeTitle.present ? episodeTitle.value : this.episodeTitle,
    lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  ListeningHistoryData copyWithCompanion(ListeningHistoryCompanion data) {
    return ListeningHistoryData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      mediaPath: data.mediaPath.present ? data.mediaPath.value : this.mediaPath,
      mediaName: data.mediaName.present ? data.mediaName.value : this.mediaName,
      subtitlePath: data.subtitlePath.present
          ? data.subtitlePath.value
          : this.subtitlePath,
      subtitleContent: data.subtitleContent.present
          ? data.subtitleContent.value
          : this.subtitleContent,
      progress: data.progress.present ? data.progress.value : this.progress,
      duration: data.duration.present ? data.duration.value : this.duration,
      episodeIndex: data.episodeIndex.present
          ? data.episodeIndex.value
          : this.episodeIndex,
      episodeTitle: data.episodeTitle.present
          ? data.episodeTitle.value
          : this.episodeTitle,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ListeningHistoryData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('mediaName: $mediaName, ')
          ..write('subtitlePath: $subtitlePath, ')
          ..write('subtitleContent: $subtitleContent, ')
          ..write('progress: $progress, ')
          ..write('duration: $duration, ')
          ..write('episodeIndex: $episodeIndex, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    mediaPath,
    mediaName,
    subtitlePath,
    subtitleContent,
    progress,
    duration,
    episodeIndex,
    episodeTitle,
    lastPlayedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListeningHistoryData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.mediaPath == this.mediaPath &&
          other.mediaName == this.mediaName &&
          other.subtitlePath == this.subtitlePath &&
          other.subtitleContent == this.subtitleContent &&
          other.progress == this.progress &&
          other.duration == this.duration &&
          other.episodeIndex == this.episodeIndex &&
          other.episodeTitle == this.episodeTitle &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.createdAt == this.createdAt);
}

class ListeningHistoryCompanion extends UpdateCompanion<ListeningHistoryData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> mediaPath;
  final Value<String> mediaName;
  final Value<String?> subtitlePath;
  final Value<String?> subtitleContent;
  final Value<double> progress;
  final Value<double?> duration;
  final Value<String?> episodeIndex;
  final Value<String?> episodeTitle;
  final Value<DateTime> lastPlayedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const ListeningHistoryCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.mediaPath = const Value.absent(),
    this.mediaName = const Value.absent(),
    this.subtitlePath = const Value.absent(),
    this.subtitleContent = const Value.absent(),
    this.progress = const Value.absent(),
    this.duration = const Value.absent(),
    this.episodeIndex = const Value.absent(),
    this.episodeTitle = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ListeningHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String mediaPath,
    required String mediaName,
    this.subtitlePath = const Value.absent(),
    this.subtitleContent = const Value.absent(),
    this.progress = const Value.absent(),
    this.duration = const Value.absent(),
    this.episodeIndex = const Value.absent(),
    this.episodeTitle = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       mediaPath = Value(mediaPath),
       mediaName = Value(mediaName);
  static Insertable<ListeningHistoryData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? mediaPath,
    Expression<String>? mediaName,
    Expression<String>? subtitlePath,
    Expression<String>? subtitleContent,
    Expression<double>? progress,
    Expression<double>? duration,
    Expression<String>? episodeIndex,
    Expression<String>? episodeTitle,
    Expression<DateTime>? lastPlayedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (mediaPath != null) 'media_path': mediaPath,
      if (mediaName != null) 'media_name': mediaName,
      if (subtitlePath != null) 'subtitle_path': subtitlePath,
      if (subtitleContent != null) 'subtitle_content': subtitleContent,
      if (progress != null) 'progress': progress,
      if (duration != null) 'duration': duration,
      if (episodeIndex != null) 'episode_index': episodeIndex,
      if (episodeTitle != null) 'episode_title': episodeTitle,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ListeningHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? mediaPath,
    Value<String>? mediaName,
    Value<String?>? subtitlePath,
    Value<String?>? subtitleContent,
    Value<double>? progress,
    Value<double?>? duration,
    Value<String?>? episodeIndex,
    Value<String?>? episodeTitle,
    Value<DateTime>? lastPlayedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return ListeningHistoryCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaName: mediaName ?? this.mediaName,
      subtitlePath: subtitlePath ?? this.subtitlePath,
      subtitleContent: subtitleContent ?? this.subtitleContent,
      progress: progress ?? this.progress,
      duration: duration ?? this.duration,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (mediaPath.present) {
      map['media_path'] = Variable<String>(mediaPath.value);
    }
    if (mediaName.present) {
      map['media_name'] = Variable<String>(mediaName.value);
    }
    if (subtitlePath.present) {
      map['subtitle_path'] = Variable<String>(subtitlePath.value);
    }
    if (subtitleContent.present) {
      map['subtitle_content'] = Variable<String>(subtitleContent.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (duration.present) {
      map['duration'] = Variable<double>(duration.value);
    }
    if (episodeIndex.present) {
      map['episode_index'] = Variable<String>(episodeIndex.value);
    }
    if (episodeTitle.present) {
      map['episode_title'] = Variable<String>(episodeTitle.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
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
    return (StringBuffer('ListeningHistoryCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('mediaPath: $mediaPath, ')
          ..write('mediaName: $mediaName, ')
          ..write('subtitlePath: $subtitlePath, ')
          ..write('subtitleContent: $subtitleContent, ')
          ..write('progress: $progress, ')
          ..write('duration: $duration, ')
          ..write('episodeIndex: $episodeIndex, ')
          ..write('episodeTitle: $episodeTitle, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiCacheTable extends AiCache with TableInfo<$AiCacheTable, AiCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta = const VerificationMeta(
    'cacheKey',
  );
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
    'cache_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskTypeMeta = const VerificationMeta(
    'taskType',
  );
  @override
  late final GeneratedColumn<String> taskType = GeneratedColumn<String>(
    'task_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inputHashMeta = const VerificationMeta(
    'inputHash',
  );
  @override
  late final GeneratedColumn<String> inputHash = GeneratedColumn<String>(
    'input_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _responseMeta = const VerificationMeta(
    'response',
  );
  @override
  late final GeneratedColumn<String> response = GeneratedColumn<String>(
    'response',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _expiresAtMeta = const VerificationMeta(
    'expiresAt',
  );
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
    'expires_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    cacheKey,
    taskType,
    inputHash,
    response,
    createdAt,
    expiresAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(
        _cacheKeyMeta,
        cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('task_type')) {
      context.handle(
        _taskTypeMeta,
        taskType.isAcceptableOrUnknown(data['task_type']!, _taskTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_taskTypeMeta);
    }
    if (data.containsKey('input_hash')) {
      context.handle(
        _inputHashMeta,
        inputHash.isAcceptableOrUnknown(data['input_hash']!, _inputHashMeta),
      );
    } else if (isInserting) {
      context.missing(_inputHashMeta);
    }
    if (data.containsKey('response')) {
      context.handle(
        _responseMeta,
        response.isAcceptableOrUnknown(data['response']!, _responseMeta),
      );
    } else if (isInserting) {
      context.missing(_responseMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('expires_at')) {
      context.handle(
        _expiresAtMeta,
        expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta),
      );
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  AiCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiCacheData(
      cacheKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cache_key'],
      )!,
      taskType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_type'],
      )!,
      inputHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_hash'],
      )!,
      response: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      expiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expires_at'],
      )!,
    );
  }

  @override
  $AiCacheTable createAlias(String alias) {
    return $AiCacheTable(attachedDatabase, alias);
  }
}

class AiCacheData extends DataClass implements Insertable<AiCacheData> {
  final String cacheKey;
  final String taskType;
  final String inputHash;
  final String response;
  final DateTime createdAt;
  final DateTime expiresAt;
  const AiCacheData({
    required this.cacheKey,
    required this.taskType,
    required this.inputHash,
    required this.response,
    required this.createdAt,
    required this.expiresAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['task_type'] = Variable<String>(taskType);
    map['input_hash'] = Variable<String>(inputHash);
    map['response'] = Variable<String>(response);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  AiCacheCompanion toCompanion(bool nullToAbsent) {
    return AiCacheCompanion(
      cacheKey: Value(cacheKey),
      taskType: Value(taskType),
      inputHash: Value(inputHash),
      response: Value(response),
      createdAt: Value(createdAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory AiCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiCacheData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      taskType: serializer.fromJson<String>(json['taskType']),
      inputHash: serializer.fromJson<String>(json['inputHash']),
      response: serializer.fromJson<String>(json['response']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'taskType': serializer.toJson<String>(taskType),
      'inputHash': serializer.toJson<String>(inputHash),
      'response': serializer.toJson<String>(response),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  AiCacheData copyWith({
    String? cacheKey,
    String? taskType,
    String? inputHash,
    String? response,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) => AiCacheData(
    cacheKey: cacheKey ?? this.cacheKey,
    taskType: taskType ?? this.taskType,
    inputHash: inputHash ?? this.inputHash,
    response: response ?? this.response,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
  );
  AiCacheData copyWithCompanion(AiCacheCompanion data) {
    return AiCacheData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      taskType: data.taskType.present ? data.taskType.value : this.taskType,
      inputHash: data.inputHash.present ? data.inputHash.value : this.inputHash,
      response: data.response.present ? data.response.value : this.response,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiCacheData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('taskType: $taskType, ')
          ..write('inputHash: $inputHash, ')
          ..write('response: $response, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    cacheKey,
    taskType,
    inputHash,
    response,
    createdAt,
    expiresAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiCacheData &&
          other.cacheKey == this.cacheKey &&
          other.taskType == this.taskType &&
          other.inputHash == this.inputHash &&
          other.response == this.response &&
          other.createdAt == this.createdAt &&
          other.expiresAt == this.expiresAt);
}

class AiCacheCompanion extends UpdateCompanion<AiCacheData> {
  final Value<String> cacheKey;
  final Value<String> taskType;
  final Value<String> inputHash;
  final Value<String> response;
  final Value<DateTime> createdAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const AiCacheCompanion({
    this.cacheKey = const Value.absent(),
    this.taskType = const Value.absent(),
    this.inputHash = const Value.absent(),
    this.response = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiCacheCompanion.insert({
    required String cacheKey,
    required String taskType,
    required String inputHash,
    required String response,
    this.createdAt = const Value.absent(),
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  }) : cacheKey = Value(cacheKey),
       taskType = Value(taskType),
       inputHash = Value(inputHash),
       response = Value(response),
       expiresAt = Value(expiresAt);
  static Insertable<AiCacheData> custom({
    Expression<String>? cacheKey,
    Expression<String>? taskType,
    Expression<String>? inputHash,
    Expression<String>? response,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (taskType != null) 'task_type': taskType,
      if (inputHash != null) 'input_hash': inputHash,
      if (response != null) 'response': response,
      if (createdAt != null) 'created_at': createdAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiCacheCompanion copyWith({
    Value<String>? cacheKey,
    Value<String>? taskType,
    Value<String>? inputHash,
    Value<String>? response,
    Value<DateTime>? createdAt,
    Value<DateTime>? expiresAt,
    Value<int>? rowid,
  }) {
    return AiCacheCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      taskType: taskType ?? this.taskType,
      inputHash: inputHash ?? this.inputHash,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (taskType.present) {
      map['task_type'] = Variable<String>(taskType.value);
    }
    if (inputHash.present) {
      map['input_hash'] = Variable<String>(inputHash.value);
    }
    if (response.present) {
      map['response'] = Variable<String>(response.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiCacheCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('taskType: $taskType, ')
          ..write('inputHash: $inputHash, ')
          ..write('response: $response, ')
          ..write('createdAt: $createdAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaCategoriesTable extends MediaCategories
    with TableInfo<$MediaCategoriesTable, MediaCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid(),
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
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _platformMeta = const VerificationMeta(
    'platform',
  );
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
    'platform',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconName,
    type,
    platform,
    sortOrder,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    } else if (isInserting) {
      context.missing(_iconNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(
        _platformMeta,
        platform.isAcceptableOrUnknown(data['platform']!, _platformMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      platform: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}platform'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MediaCategoriesTable createAlias(String alias) {
    return $MediaCategoriesTable(attachedDatabase, alias);
  }
}

class MediaCategory extends DataClass implements Insertable<MediaCategory> {
  final String id;
  final String name;
  final String iconName;
  final String type;
  final String? platform;
  final int sortOrder;
  final DateTime createdAt;
  const MediaCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.type,
    this.platform,
    required this.sortOrder,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon_name'] = Variable<String>(iconName);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || platform != null) {
      map['platform'] = Variable<String>(platform);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MediaCategoriesCompanion toCompanion(bool nullToAbsent) {
    return MediaCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      iconName: Value(iconName),
      type: Value(type),
      platform: platform == null && nullToAbsent
          ? const Value.absent()
          : Value(platform),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
    );
  }

  factory MediaCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconName: serializer.fromJson<String>(json['iconName']),
      type: serializer.fromJson<String>(json['type']),
      platform: serializer.fromJson<String?>(json['platform']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'iconName': serializer.toJson<String>(iconName),
      'type': serializer.toJson<String>(type),
      'platform': serializer.toJson<String?>(platform),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MediaCategory copyWith({
    String? id,
    String? name,
    String? iconName,
    String? type,
    Value<String?> platform = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
  }) => MediaCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    type: type ?? this.type,
    platform: platform.present ? platform.value : this.platform,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
  );
  MediaCategory copyWithCompanion(MediaCategoriesCompanion data) {
    return MediaCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      type: data.type.present ? data.type.value : this.type,
      platform: data.platform.present ? data.platform.value : this.platform,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('type: $type, ')
          ..write('platform: $platform, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, iconName, type, platform, sortOrder, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconName == this.iconName &&
          other.type == this.type &&
          other.platform == this.platform &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt);
}

class MediaCategoriesCompanion extends UpdateCompanion<MediaCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> iconName;
  final Value<String> type;
  final Value<String?> platform;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MediaCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconName = const Value.absent(),
    this.type = const Value.absent(),
    this.platform = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String iconName,
    required String type,
    this.platform = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       iconName = Value(iconName),
       type = Value(type);
  static Insertable<MediaCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? iconName,
    Expression<String>? type,
    Expression<String>? platform,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconName != null) 'icon_name': iconName,
      if (type != null) 'type': type,
      if (platform != null) 'platform': platform,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? iconName,
    Value<String>? type,
    Value<String?>? platform,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MediaCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      type: type ?? this.type,
      platform: platform ?? this.platform,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
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
    return (StringBuffer('MediaCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('type: $type, ')
          ..write('platform: $platform, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MediaRecordsTable extends MediaRecords
    with TableInfo<$MediaRecordsTable, MediaRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid(),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
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
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtitlePathMeta = const VerificationMeta(
    'subtitlePath',
  );
  @override
  late final GeneratedColumn<String> subtitlePath = GeneratedColumn<String>(
    'subtitle_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtitleContentMeta = const VerificationMeta(
    'subtitleContent',
  );
  @override
  late final GeneratedColumn<String> subtitleContent = GeneratedColumn<String>(
    'subtitle_content',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMeta = const VerificationMeta(
    'duration',
  );
  @override
  late final GeneratedColumn<double> duration = GeneratedColumn<double>(
    'duration',
    aliasedName,
    true,
    type: DriftSqlType.double,
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
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
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    categoryId,
    name,
    path,
    subtitlePath,
    subtitleContent,
    thumbnailUrl,
    duration,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<MediaRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('subtitle_path')) {
      context.handle(
        _subtitlePathMeta,
        subtitlePath.isAcceptableOrUnknown(
          data['subtitle_path']!,
          _subtitlePathMeta,
        ),
      );
    }
    if (data.containsKey('subtitle_content')) {
      context.handle(
        _subtitleContentMeta,
        subtitleContent.isAcceptableOrUnknown(
          data['subtitle_content']!,
          _subtitleContentMeta,
        ),
      );
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    if (data.containsKey('duration')) {
      context.handle(
        _durationMeta,
        duration.isAcceptableOrUnknown(data['duration']!, _durationMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      subtitlePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle_path'],
      ),
      subtitleContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subtitle_content'],
      ),
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
      duration: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}duration'],
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
  $MediaRecordsTable createAlias(String alias) {
    return $MediaRecordsTable(attachedDatabase, alias);
  }
}

class MediaRecord extends DataClass implements Insertable<MediaRecord> {
  final String id;
  final String userId;
  final String categoryId;
  final String name;
  final String path;
  final String? subtitlePath;
  final String? subtitleContent;
  final String? thumbnailUrl;
  final double? duration;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MediaRecord({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.name,
    required this.path,
    this.subtitlePath,
    this.subtitleContent,
    this.thumbnailUrl,
    this.duration,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['category_id'] = Variable<String>(categoryId);
    map['name'] = Variable<String>(name);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || subtitlePath != null) {
      map['subtitle_path'] = Variable<String>(subtitlePath);
    }
    if (!nullToAbsent || subtitleContent != null) {
      map['subtitle_content'] = Variable<String>(subtitleContent);
    }
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<double>(duration);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MediaRecordsCompanion toCompanion(bool nullToAbsent) {
    return MediaRecordsCompanion(
      id: Value(id),
      userId: Value(userId),
      categoryId: Value(categoryId),
      name: Value(name),
      path: Value(path),
      subtitlePath: subtitlePath == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitlePath),
      subtitleContent: subtitleContent == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitleContent),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MediaRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaRecord(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      path: serializer.fromJson<String>(json['path']),
      subtitlePath: serializer.fromJson<String?>(json['subtitlePath']),
      subtitleContent: serializer.fromJson<String?>(json['subtitleContent']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
      duration: serializer.fromJson<double?>(json['duration']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'categoryId': serializer.toJson<String>(categoryId),
      'name': serializer.toJson<String>(name),
      'path': serializer.toJson<String>(path),
      'subtitlePath': serializer.toJson<String?>(subtitlePath),
      'subtitleContent': serializer.toJson<String?>(subtitleContent),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
      'duration': serializer.toJson<double?>(duration),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MediaRecord copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? name,
    String? path,
    Value<String?> subtitlePath = const Value.absent(),
    Value<String?> subtitleContent = const Value.absent(),
    Value<String?> thumbnailUrl = const Value.absent(),
    Value<double?> duration = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => MediaRecord(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    path: path ?? this.path,
    subtitlePath: subtitlePath.present ? subtitlePath.value : this.subtitlePath,
    subtitleContent: subtitleContent.present
        ? subtitleContent.value
        : this.subtitleContent,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
    duration: duration.present ? duration.value : this.duration,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  MediaRecord copyWithCompanion(MediaRecordsCompanion data) {
    return MediaRecord(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      path: data.path.present ? data.path.value : this.path,
      subtitlePath: data.subtitlePath.present
          ? data.subtitlePath.value
          : this.subtitlePath,
      subtitleContent: data.subtitleContent.present
          ? data.subtitleContent.value
          : this.subtitleContent,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
      duration: data.duration.present ? data.duration.value : this.duration,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaRecord(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('subtitlePath: $subtitlePath, ')
          ..write('subtitleContent: $subtitleContent, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('duration: $duration, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    categoryId,
    name,
    path,
    subtitlePath,
    subtitleContent,
    thumbnailUrl,
    duration,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaRecord &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.path == this.path &&
          other.subtitlePath == this.subtitlePath &&
          other.subtitleContent == this.subtitleContent &&
          other.thumbnailUrl == this.thumbnailUrl &&
          other.duration == this.duration &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MediaRecordsCompanion extends UpdateCompanion<MediaRecord> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> categoryId;
  final Value<String> name;
  final Value<String> path;
  final Value<String?> subtitlePath;
  final Value<String?> subtitleContent;
  final Value<String?> thumbnailUrl;
  final Value<double?> duration;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const MediaRecordsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.path = const Value.absent(),
    this.subtitlePath = const Value.absent(),
    this.subtitleContent = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.duration = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaRecordsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String categoryId,
    required String name,
    required String path,
    this.subtitlePath = const Value.absent(),
    this.subtitleContent = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.duration = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       categoryId = Value(categoryId),
       name = Value(name),
       path = Value(path);
  static Insertable<MediaRecord> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<String>? path,
    Expression<String>? subtitlePath,
    Expression<String>? subtitleContent,
    Expression<String>? thumbnailUrl,
    Expression<double>? duration,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (path != null) 'path': path,
      if (subtitlePath != null) 'subtitle_path': subtitlePath,
      if (subtitleContent != null) 'subtitle_content': subtitleContent,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (duration != null) 'duration': duration,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? categoryId,
    Value<String>? name,
    Value<String>? path,
    Value<String?>? subtitlePath,
    Value<String?>? subtitleContent,
    Value<String?>? thumbnailUrl,
    Value<double?>? duration,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return MediaRecordsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      path: path ?? this.path,
      subtitlePath: subtitlePath ?? this.subtitlePath,
      subtitleContent: subtitleContent ?? this.subtitleContent,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
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
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (subtitlePath.present) {
      map['subtitle_path'] = Variable<String>(subtitlePath.value);
    }
    if (subtitleContent.present) {
      map['subtitle_content'] = Variable<String>(subtitleContent.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (duration.present) {
      map['duration'] = Variable<double>(duration.value);
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
    return (StringBuffer('MediaRecordsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('path: $path, ')
          ..write('subtitlePath: $subtitlePath, ')
          ..write('subtitleContent: $subtitleContent, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('duration: $duration, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $FavoritesTable favorites = $FavoritesTable(this);
  late final $CollocationsTable collocations = $CollocationsTable(this);
  late final $FlashcardsTable flashcards = $FlashcardsTable(this);
  late final $FlashcardReviewsTable flashcardReviews = $FlashcardReviewsTable(
    this,
  );
  late final $SyncStatusTable syncStatus = $SyncStatusTable(this);
  late final $ListeningHistoryTable listeningHistory = $ListeningHistoryTable(
    this,
  );
  late final $AiCacheTable aiCache = $AiCacheTable(this);
  late final $MediaCategoriesTable mediaCategories = $MediaCategoriesTable(
    this,
  );
  late final $MediaRecordsTable mediaRecords = $MediaRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    favorites,
    collocations,
    flashcards,
    flashcardReviews,
    syncStatus,
    listeningHistory,
    aiCache,
    mediaCategories,
    mediaRecords,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      required String username,
      required String email,
      required String passwordHash,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> username,
      Value<String> email,
      Value<String> passwordHash,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
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

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
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
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
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

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
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

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                username: username,
                email: email,
                passwordHash: passwordHash,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String username,
                required String email,
                required String passwordHash,
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                username: username,
                email: email,
                passwordHash: passwordHash,
                createdAt: createdAt,
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

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$FavoritesTableCreateCompanionBuilder =
    FavoritesCompanion Function({
      Value<String> id,
      required String userId,
      required String type,
      required String contentText,
      Value<String?> context,
      Value<String?> cefrLevel,
      Value<double?> mediaTime,
      Value<String?> cueId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FavoritesTableUpdateCompanionBuilder =
    FavoritesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> type,
      Value<String> contentText,
      Value<String?> context,
      Value<String?> cefrLevel,
      Value<double?> mediaTime,
      Value<String?> cueId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FavoritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentText => $composableBuilder(
    column: $table.contentText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cefrLevel => $composableBuilder(
    column: $table.cefrLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mediaTime => $composableBuilder(
    column: $table.mediaTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cueId => $composableBuilder(
    column: $table.cueId,
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
}

class $$FavoritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentText => $composableBuilder(
    column: $table.contentText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get context => $composableBuilder(
    column: $table.context,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cefrLevel => $composableBuilder(
    column: $table.cefrLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mediaTime => $composableBuilder(
    column: $table.mediaTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cueId => $composableBuilder(
    column: $table.cueId,
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

class $$FavoritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavoritesTable> {
  $$FavoritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get contentText => $composableBuilder(
    column: $table.contentText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumn<String> get cefrLevel =>
      $composableBuilder(column: $table.cefrLevel, builder: (column) => column);

  GeneratedColumn<double> get mediaTime =>
      $composableBuilder(column: $table.mediaTime, builder: (column) => column);

  GeneratedColumn<String> get cueId =>
      $composableBuilder(column: $table.cueId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FavoritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavoritesTable,
          Favorite,
          $$FavoritesTableFilterComposer,
          $$FavoritesTableOrderingComposer,
          $$FavoritesTableAnnotationComposer,
          $$FavoritesTableCreateCompanionBuilder,
          $$FavoritesTableUpdateCompanionBuilder,
          (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
          Favorite,
          PrefetchHooks Function()
        > {
  $$FavoritesTableTableManager(_$AppDatabase db, $FavoritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavoritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavoritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavoritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> contentText = const Value.absent(),
                Value<String?> context = const Value.absent(),
                Value<String?> cefrLevel = const Value.absent(),
                Value<double?> mediaTime = const Value.absent(),
                Value<String?> cueId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion(
                id: id,
                userId: userId,
                type: type,
                contentText: contentText,
                context: context,
                cefrLevel: cefrLevel,
                mediaTime: mediaTime,
                cueId: cueId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String userId,
                required String type,
                required String contentText,
                Value<String?> context = const Value.absent(),
                Value<String?> cefrLevel = const Value.absent(),
                Value<double?> mediaTime = const Value.absent(),
                Value<String?> cueId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavoritesCompanion.insert(
                id: id,
                userId: userId,
                type: type,
                contentText: contentText,
                context: context,
                cefrLevel: cefrLevel,
                mediaTime: mediaTime,
                cueId: cueId,
                createdAt: createdAt,
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

typedef $$FavoritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavoritesTable,
      Favorite,
      $$FavoritesTableFilterComposer,
      $$FavoritesTableOrderingComposer,
      $$FavoritesTableAnnotationComposer,
      $$FavoritesTableCreateCompanionBuilder,
      $$FavoritesTableUpdateCompanionBuilder,
      (Favorite, BaseReferences<_$AppDatabase, $FavoritesTable, Favorite>),
      Favorite,
      PrefetchHooks Function()
    >;
typedef $$CollocationsTableCreateCompanionBuilder =
    CollocationsCompanion Function({
      Value<String> id,
      required String userId,
      required String type,
      required String collocationText,
      Value<String?> meaning,
      Value<String?> sourceCueId,
      Value<String?> sourceText,
      Value<bool> aiDetected,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$CollocationsTableUpdateCompanionBuilder =
    CollocationsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> type,
      Value<String> collocationText,
      Value<String?> meaning,
      Value<String?> sourceCueId,
      Value<String?> sourceText,
      Value<bool> aiDetected,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CollocationsTableFilterComposer
    extends Composer<_$AppDatabase, $CollocationsTable> {
  $$CollocationsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collocationText => $composableBuilder(
    column: $table.collocationText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceCueId => $composableBuilder(
    column: $table.sourceCueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get aiDetected => $composableBuilder(
    column: $table.aiDetected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollocationsTable> {
  $$CollocationsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collocationText => $composableBuilder(
    column: $table.collocationText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get meaning => $composableBuilder(
    column: $table.meaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceCueId => $composableBuilder(
    column: $table.sourceCueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get aiDetected => $composableBuilder(
    column: $table.aiDetected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollocationsTable> {
  $$CollocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get collocationText => $composableBuilder(
    column: $table.collocationText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get meaning =>
      $composableBuilder(column: $table.meaning, builder: (column) => column);

  GeneratedColumn<String> get sourceCueId => $composableBuilder(
    column: $table.sourceCueId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceText => $composableBuilder(
    column: $table.sourceText,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get aiDetected => $composableBuilder(
    column: $table.aiDetected,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CollocationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollocationsTable,
          Collocation,
          $$CollocationsTableFilterComposer,
          $$CollocationsTableOrderingComposer,
          $$CollocationsTableAnnotationComposer,
          $$CollocationsTableCreateCompanionBuilder,
          $$CollocationsTableUpdateCompanionBuilder,
          (
            Collocation,
            BaseReferences<_$AppDatabase, $CollocationsTable, Collocation>,
          ),
          Collocation,
          PrefetchHooks Function()
        > {
  $$CollocationsTableTableManager(_$AppDatabase db, $CollocationsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> collocationText = const Value.absent(),
                Value<String?> meaning = const Value.absent(),
                Value<String?> sourceCueId = const Value.absent(),
                Value<String?> sourceText = const Value.absent(),
                Value<bool> aiDetected = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollocationsCompanion(
                id: id,
                userId: userId,
                type: type,
                collocationText: collocationText,
                meaning: meaning,
                sourceCueId: sourceCueId,
                sourceText: sourceText,
                aiDetected: aiDetected,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String userId,
                required String type,
                required String collocationText,
                Value<String?> meaning = const Value.absent(),
                Value<String?> sourceCueId = const Value.absent(),
                Value<String?> sourceText = const Value.absent(),
                Value<bool> aiDetected = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollocationsCompanion.insert(
                id: id,
                userId: userId,
                type: type,
                collocationText: collocationText,
                meaning: meaning,
                sourceCueId: sourceCueId,
                sourceText: sourceText,
                aiDetected: aiDetected,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollocationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollocationsTable,
      Collocation,
      $$CollocationsTableFilterComposer,
      $$CollocationsTableOrderingComposer,
      $$CollocationsTableAnnotationComposer,
      $$CollocationsTableCreateCompanionBuilder,
      $$CollocationsTableUpdateCompanionBuilder,
      (
        Collocation,
        BaseReferences<_$AppDatabase, $CollocationsTable, Collocation>,
      ),
      Collocation,
      PrefetchHooks Function()
    >;
typedef $$FlashcardsTableCreateCompanionBuilder =
    FlashcardsCompanion Function({
      Value<String> id,
      required String userId,
      required String frontText,
      Value<String?> frontHint,
      required String backAnswer,
      Value<String?> backMeaning,
      Value<String?> backOriginal,
      Value<String?> mediaFilePath,
      Value<String?> mediaFileId,
      Value<double?> mediaTime,
      Value<String?> cueId,
      Value<String?> sourceTitle,
      Value<String?> tags,
      Value<int> reviewCount,
      Value<DateTime> nextReviewAt,
      Value<double> easeFactor,
      Value<double> interval,
      Value<bool> aiGenerated,
      Value<String?> examples,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$FlashcardsTableUpdateCompanionBuilder =
    FlashcardsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> frontText,
      Value<String?> frontHint,
      Value<String> backAnswer,
      Value<String?> backMeaning,
      Value<String?> backOriginal,
      Value<String?> mediaFilePath,
      Value<String?> mediaFileId,
      Value<double?> mediaTime,
      Value<String?> cueId,
      Value<String?> sourceTitle,
      Value<String?> tags,
      Value<int> reviewCount,
      Value<DateTime> nextReviewAt,
      Value<double> easeFactor,
      Value<double> interval,
      Value<bool> aiGenerated,
      Value<String?> examples,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$FlashcardsTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frontText => $composableBuilder(
    column: $table.frontText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frontHint => $composableBuilder(
    column: $table.frontHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backAnswer => $composableBuilder(
    column: $table.backAnswer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backMeaning => $composableBuilder(
    column: $table.backMeaning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backOriginal => $composableBuilder(
    column: $table.backOriginal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaFilePath => $composableBuilder(
    column: $table.mediaFilePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaFileId => $composableBuilder(
    column: $table.mediaFileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get mediaTime => $composableBuilder(
    column: $table.mediaTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cueId => $composableBuilder(
    column: $table.cueId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get aiGenerated => $composableBuilder(
    column: $table.aiGenerated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get examples => $composableBuilder(
    column: $table.examples,
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
}

class $$FlashcardsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frontText => $composableBuilder(
    column: $table.frontText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frontHint => $composableBuilder(
    column: $table.frontHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backAnswer => $composableBuilder(
    column: $table.backAnswer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backMeaning => $composableBuilder(
    column: $table.backMeaning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backOriginal => $composableBuilder(
    column: $table.backOriginal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaFilePath => $composableBuilder(
    column: $table.mediaFilePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaFileId => $composableBuilder(
    column: $table.mediaFileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get mediaTime => $composableBuilder(
    column: $table.mediaTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cueId => $composableBuilder(
    column: $table.cueId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interval => $composableBuilder(
    column: $table.interval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get aiGenerated => $composableBuilder(
    column: $table.aiGenerated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get examples => $composableBuilder(
    column: $table.examples,
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

class $$FlashcardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardsTable> {
  $$FlashcardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get frontText =>
      $composableBuilder(column: $table.frontText, builder: (column) => column);

  GeneratedColumn<String> get frontHint =>
      $composableBuilder(column: $table.frontHint, builder: (column) => column);

  GeneratedColumn<String> get backAnswer => $composableBuilder(
    column: $table.backAnswer,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backMeaning => $composableBuilder(
    column: $table.backMeaning,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backOriginal => $composableBuilder(
    column: $table.backOriginal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaFilePath => $composableBuilder(
    column: $table.mediaFilePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mediaFileId => $composableBuilder(
    column: $table.mediaFileId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get mediaTime =>
      $composableBuilder(column: $table.mediaTime, builder: (column) => column);

  GeneratedColumn<String> get cueId =>
      $composableBuilder(column: $table.cueId, builder: (column) => column);

  GeneratedColumn<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextReviewAt => $composableBuilder(
    column: $table.nextReviewAt,
    builder: (column) => column,
  );

  GeneratedColumn<double> get easeFactor => $composableBuilder(
    column: $table.easeFactor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get interval =>
      $composableBuilder(column: $table.interval, builder: (column) => column);

  GeneratedColumn<bool> get aiGenerated => $composableBuilder(
    column: $table.aiGenerated,
    builder: (column) => column,
  );

  GeneratedColumn<String> get examples =>
      $composableBuilder(column: $table.examples, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$FlashcardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardsTable,
          Flashcard,
          $$FlashcardsTableFilterComposer,
          $$FlashcardsTableOrderingComposer,
          $$FlashcardsTableAnnotationComposer,
          $$FlashcardsTableCreateCompanionBuilder,
          $$FlashcardsTableUpdateCompanionBuilder,
          (
            Flashcard,
            BaseReferences<_$AppDatabase, $FlashcardsTable, Flashcard>,
          ),
          Flashcard,
          PrefetchHooks Function()
        > {
  $$FlashcardsTableTableManager(_$AppDatabase db, $FlashcardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> frontText = const Value.absent(),
                Value<String?> frontHint = const Value.absent(),
                Value<String> backAnswer = const Value.absent(),
                Value<String?> backMeaning = const Value.absent(),
                Value<String?> backOriginal = const Value.absent(),
                Value<String?> mediaFilePath = const Value.absent(),
                Value<String?> mediaFileId = const Value.absent(),
                Value<double?> mediaTime = const Value.absent(),
                Value<String?> cueId = const Value.absent(),
                Value<String?> sourceTitle = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<DateTime> nextReviewAt = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<double> interval = const Value.absent(),
                Value<bool> aiGenerated = const Value.absent(),
                Value<String?> examples = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlashcardsCompanion(
                id: id,
                userId: userId,
                frontText: frontText,
                frontHint: frontHint,
                backAnswer: backAnswer,
                backMeaning: backMeaning,
                backOriginal: backOriginal,
                mediaFilePath: mediaFilePath,
                mediaFileId: mediaFileId,
                mediaTime: mediaTime,
                cueId: cueId,
                sourceTitle: sourceTitle,
                tags: tags,
                reviewCount: reviewCount,
                nextReviewAt: nextReviewAt,
                easeFactor: easeFactor,
                interval: interval,
                aiGenerated: aiGenerated,
                examples: examples,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String userId,
                required String frontText,
                Value<String?> frontHint = const Value.absent(),
                required String backAnswer,
                Value<String?> backMeaning = const Value.absent(),
                Value<String?> backOriginal = const Value.absent(),
                Value<String?> mediaFilePath = const Value.absent(),
                Value<String?> mediaFileId = const Value.absent(),
                Value<double?> mediaTime = const Value.absent(),
                Value<String?> cueId = const Value.absent(),
                Value<String?> sourceTitle = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<DateTime> nextReviewAt = const Value.absent(),
                Value<double> easeFactor = const Value.absent(),
                Value<double> interval = const Value.absent(),
                Value<bool> aiGenerated = const Value.absent(),
                Value<String?> examples = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlashcardsCompanion.insert(
                id: id,
                userId: userId,
                frontText: frontText,
                frontHint: frontHint,
                backAnswer: backAnswer,
                backMeaning: backMeaning,
                backOriginal: backOriginal,
                mediaFilePath: mediaFilePath,
                mediaFileId: mediaFileId,
                mediaTime: mediaTime,
                cueId: cueId,
                sourceTitle: sourceTitle,
                tags: tags,
                reviewCount: reviewCount,
                nextReviewAt: nextReviewAt,
                easeFactor: easeFactor,
                interval: interval,
                aiGenerated: aiGenerated,
                examples: examples,
                createdAt: createdAt,
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

typedef $$FlashcardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardsTable,
      Flashcard,
      $$FlashcardsTableFilterComposer,
      $$FlashcardsTableOrderingComposer,
      $$FlashcardsTableAnnotationComposer,
      $$FlashcardsTableCreateCompanionBuilder,
      $$FlashcardsTableUpdateCompanionBuilder,
      (Flashcard, BaseReferences<_$AppDatabase, $FlashcardsTable, Flashcard>),
      Flashcard,
      PrefetchHooks Function()
    >;
typedef $$FlashcardReviewsTableCreateCompanionBuilder =
    FlashcardReviewsCompanion Function({
      Value<String> id,
      required String flashcardId,
      required int rating,
      Value<DateTime> reviewedAt,
      Value<int> rowid,
    });
typedef $$FlashcardReviewsTableUpdateCompanionBuilder =
    FlashcardReviewsCompanion Function({
      Value<String> id,
      Value<String> flashcardId,
      Value<int> rating,
      Value<DateTime> reviewedAt,
      Value<int> rowid,
    });

class $$FlashcardReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $FlashcardReviewsTable> {
  $$FlashcardReviewsTableFilterComposer({
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

  ColumnFilters<String> get flashcardId => $composableBuilder(
    column: $table.flashcardId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FlashcardReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $FlashcardReviewsTable> {
  $$FlashcardReviewsTableOrderingComposer({
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

  ColumnOrderings<String> get flashcardId => $composableBuilder(
    column: $table.flashcardId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FlashcardReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FlashcardReviewsTable> {
  $$FlashcardReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get flashcardId => $composableBuilder(
    column: $table.flashcardId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );
}

class $$FlashcardReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FlashcardReviewsTable,
          FlashcardReview,
          $$FlashcardReviewsTableFilterComposer,
          $$FlashcardReviewsTableOrderingComposer,
          $$FlashcardReviewsTableAnnotationComposer,
          $$FlashcardReviewsTableCreateCompanionBuilder,
          $$FlashcardReviewsTableUpdateCompanionBuilder,
          (
            FlashcardReview,
            BaseReferences<
              _$AppDatabase,
              $FlashcardReviewsTable,
              FlashcardReview
            >,
          ),
          FlashcardReview,
          PrefetchHooks Function()
        > {
  $$FlashcardReviewsTableTableManager(
    _$AppDatabase db,
    $FlashcardReviewsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlashcardReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlashcardReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlashcardReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> flashcardId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlashcardReviewsCompanion(
                id: id,
                flashcardId: flashcardId,
                rating: rating,
                reviewedAt: reviewedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String flashcardId,
                required int rating,
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FlashcardReviewsCompanion.insert(
                id: id,
                flashcardId: flashcardId,
                rating: rating,
                reviewedAt: reviewedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FlashcardReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FlashcardReviewsTable,
      FlashcardReview,
      $$FlashcardReviewsTableFilterComposer,
      $$FlashcardReviewsTableOrderingComposer,
      $$FlashcardReviewsTableAnnotationComposer,
      $$FlashcardReviewsTableCreateCompanionBuilder,
      $$FlashcardReviewsTableUpdateCompanionBuilder,
      (
        FlashcardReview,
        BaseReferences<_$AppDatabase, $FlashcardReviewsTable, FlashcardReview>,
      ),
      FlashcardReview,
      PrefetchHooks Function()
    >;
typedef $$SyncStatusTableCreateCompanionBuilder =
    SyncStatusCompanion Function({
      required String userId,
      Value<DateTime?> lastSyncedAt,
      Value<int> serverGeneration,
      Value<int> rowid,
    });
typedef $$SyncStatusTableUpdateCompanionBuilder =
    SyncStatusCompanion Function({
      Value<String> userId,
      Value<DateTime?> lastSyncedAt,
      Value<int> serverGeneration,
      Value<int> rowid,
    });

class $$SyncStatusTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStatusTable> {
  $$SyncStatusTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverGeneration => $composableBuilder(
    column: $table.serverGeneration,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStatusTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStatusTable> {
  $$SyncStatusTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverGeneration => $composableBuilder(
    column: $table.serverGeneration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStatusTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStatusTable> {
  $$SyncStatusTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncedAt => $composableBuilder(
    column: $table.lastSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverGeneration => $composableBuilder(
    column: $table.serverGeneration,
    builder: (column) => column,
  );
}

class $$SyncStatusTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStatusTable,
          SyncStatusData,
          $$SyncStatusTableFilterComposer,
          $$SyncStatusTableOrderingComposer,
          $$SyncStatusTableAnnotationComposer,
          $$SyncStatusTableCreateCompanionBuilder,
          $$SyncStatusTableUpdateCompanionBuilder,
          (
            SyncStatusData,
            BaseReferences<_$AppDatabase, $SyncStatusTable, SyncStatusData>,
          ),
          SyncStatusData,
          PrefetchHooks Function()
        > {
  $$SyncStatusTableTableManager(_$AppDatabase db, $SyncStatusTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStatusTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStatusTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStatusTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> serverGeneration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatusCompanion(
                userId: userId,
                lastSyncedAt: lastSyncedAt,
                serverGeneration: serverGeneration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<DateTime?> lastSyncedAt = const Value.absent(),
                Value<int> serverGeneration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStatusCompanion.insert(
                userId: userId,
                lastSyncedAt: lastSyncedAt,
                serverGeneration: serverGeneration,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStatusTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStatusTable,
      SyncStatusData,
      $$SyncStatusTableFilterComposer,
      $$SyncStatusTableOrderingComposer,
      $$SyncStatusTableAnnotationComposer,
      $$SyncStatusTableCreateCompanionBuilder,
      $$SyncStatusTableUpdateCompanionBuilder,
      (
        SyncStatusData,
        BaseReferences<_$AppDatabase, $SyncStatusTable, SyncStatusData>,
      ),
      SyncStatusData,
      PrefetchHooks Function()
    >;
typedef $$ListeningHistoryTableCreateCompanionBuilder =
    ListeningHistoryCompanion Function({
      Value<String> id,
      required String userId,
      required String mediaPath,
      required String mediaName,
      Value<String?> subtitlePath,
      Value<String?> subtitleContent,
      Value<double> progress,
      Value<double?> duration,
      Value<String?> episodeIndex,
      Value<String?> episodeTitle,
      Value<DateTime> lastPlayedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$ListeningHistoryTableUpdateCompanionBuilder =
    ListeningHistoryCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> mediaPath,
      Value<String> mediaName,
      Value<String?> subtitlePath,
      Value<String?> subtitleContent,
      Value<double> progress,
      Value<double?> duration,
      Value<String?> episodeIndex,
      Value<String?> episodeTitle,
      Value<DateTime> lastPlayedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$ListeningHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ListeningHistoryTable> {
  $$ListeningHistoryTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaPath => $composableBuilder(
    column: $table.mediaPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mediaName => $composableBuilder(
    column: $table.mediaName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitlePath => $composableBuilder(
    column: $table.subtitlePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitleContent => $composableBuilder(
    column: $table.subtitleContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ListeningHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ListeningHistoryTable> {
  $$ListeningHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaPath => $composableBuilder(
    column: $table.mediaPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mediaName => $composableBuilder(
    column: $table.mediaName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitlePath => $composableBuilder(
    column: $table.subtitlePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitleContent => $composableBuilder(
    column: $table.subtitleContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get duration => $composableBuilder(
    column: $table.duration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ListeningHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ListeningHistoryTable> {
  $$ListeningHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get mediaPath =>
      $composableBuilder(column: $table.mediaPath, builder: (column) => column);

  GeneratedColumn<String> get mediaName =>
      $composableBuilder(column: $table.mediaName, builder: (column) => column);

  GeneratedColumn<String> get subtitlePath => $composableBuilder(
    column: $table.subtitlePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subtitleContent => $composableBuilder(
    column: $table.subtitleContent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<double> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<String> get episodeIndex => $composableBuilder(
    column: $table.episodeIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get episodeTitle => $composableBuilder(
    column: $table.episodeTitle,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ListeningHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ListeningHistoryTable,
          ListeningHistoryData,
          $$ListeningHistoryTableFilterComposer,
          $$ListeningHistoryTableOrderingComposer,
          $$ListeningHistoryTableAnnotationComposer,
          $$ListeningHistoryTableCreateCompanionBuilder,
          $$ListeningHistoryTableUpdateCompanionBuilder,
          (
            ListeningHistoryData,
            BaseReferences<
              _$AppDatabase,
              $ListeningHistoryTable,
              ListeningHistoryData
            >,
          ),
          ListeningHistoryData,
          PrefetchHooks Function()
        > {
  $$ListeningHistoryTableTableManager(
    _$AppDatabase db,
    $ListeningHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ListeningHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ListeningHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ListeningHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> mediaPath = const Value.absent(),
                Value<String> mediaName = const Value.absent(),
                Value<String?> subtitlePath = const Value.absent(),
                Value<String?> subtitleContent = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<double?> duration = const Value.absent(),
                Value<String?> episodeIndex = const Value.absent(),
                Value<String?> episodeTitle = const Value.absent(),
                Value<DateTime> lastPlayedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListeningHistoryCompanion(
                id: id,
                userId: userId,
                mediaPath: mediaPath,
                mediaName: mediaName,
                subtitlePath: subtitlePath,
                subtitleContent: subtitleContent,
                progress: progress,
                duration: duration,
                episodeIndex: episodeIndex,
                episodeTitle: episodeTitle,
                lastPlayedAt: lastPlayedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String userId,
                required String mediaPath,
                required String mediaName,
                Value<String?> subtitlePath = const Value.absent(),
                Value<String?> subtitleContent = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<double?> duration = const Value.absent(),
                Value<String?> episodeIndex = const Value.absent(),
                Value<String?> episodeTitle = const Value.absent(),
                Value<DateTime> lastPlayedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ListeningHistoryCompanion.insert(
                id: id,
                userId: userId,
                mediaPath: mediaPath,
                mediaName: mediaName,
                subtitlePath: subtitlePath,
                subtitleContent: subtitleContent,
                progress: progress,
                duration: duration,
                episodeIndex: episodeIndex,
                episodeTitle: episodeTitle,
                lastPlayedAt: lastPlayedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ListeningHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ListeningHistoryTable,
      ListeningHistoryData,
      $$ListeningHistoryTableFilterComposer,
      $$ListeningHistoryTableOrderingComposer,
      $$ListeningHistoryTableAnnotationComposer,
      $$ListeningHistoryTableCreateCompanionBuilder,
      $$ListeningHistoryTableUpdateCompanionBuilder,
      (
        ListeningHistoryData,
        BaseReferences<
          _$AppDatabase,
          $ListeningHistoryTable,
          ListeningHistoryData
        >,
      ),
      ListeningHistoryData,
      PrefetchHooks Function()
    >;
typedef $$AiCacheTableCreateCompanionBuilder =
    AiCacheCompanion Function({
      required String cacheKey,
      required String taskType,
      required String inputHash,
      required String response,
      Value<DateTime> createdAt,
      required DateTime expiresAt,
      Value<int> rowid,
    });
typedef $$AiCacheTableUpdateCompanionBuilder =
    AiCacheCompanion Function({
      Value<String> cacheKey,
      Value<String> taskType,
      Value<String> inputHash,
      Value<String> response,
      Value<DateTime> createdAt,
      Value<DateTime> expiresAt,
      Value<int> rowid,
    });

class $$AiCacheTableFilterComposer
    extends Composer<_$AppDatabase, $AiCacheTable> {
  $$AiCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inputHash => $composableBuilder(
    column: $table.inputHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $AiCacheTable> {
  $$AiCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
    column: $table.cacheKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskType => $composableBuilder(
    column: $table.taskType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inputHash => $composableBuilder(
    column: $table.inputHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get response => $composableBuilder(
    column: $table.response,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
    column: $table.expiresAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiCacheTable> {
  $$AiCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get taskType =>
      $composableBuilder(column: $table.taskType, builder: (column) => column);

  GeneratedColumn<String> get inputHash =>
      $composableBuilder(column: $table.inputHash, builder: (column) => column);

  GeneratedColumn<String> get response =>
      $composableBuilder(column: $table.response, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$AiCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiCacheTable,
          AiCacheData,
          $$AiCacheTableFilterComposer,
          $$AiCacheTableOrderingComposer,
          $$AiCacheTableAnnotationComposer,
          $$AiCacheTableCreateCompanionBuilder,
          $$AiCacheTableUpdateCompanionBuilder,
          (
            AiCacheData,
            BaseReferences<_$AppDatabase, $AiCacheTable, AiCacheData>,
          ),
          AiCacheData,
          PrefetchHooks Function()
        > {
  $$AiCacheTableTableManager(_$AppDatabase db, $AiCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> cacheKey = const Value.absent(),
                Value<String> taskType = const Value.absent(),
                Value<String> inputHash = const Value.absent(),
                Value<String> response = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> expiresAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiCacheCompanion(
                cacheKey: cacheKey,
                taskType: taskType,
                inputHash: inputHash,
                response: response,
                createdAt: createdAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String cacheKey,
                required String taskType,
                required String inputHash,
                required String response,
                Value<DateTime> createdAt = const Value.absent(),
                required DateTime expiresAt,
                Value<int> rowid = const Value.absent(),
              }) => AiCacheCompanion.insert(
                cacheKey: cacheKey,
                taskType: taskType,
                inputHash: inputHash,
                response: response,
                createdAt: createdAt,
                expiresAt: expiresAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiCacheTable,
      AiCacheData,
      $$AiCacheTableFilterComposer,
      $$AiCacheTableOrderingComposer,
      $$AiCacheTableAnnotationComposer,
      $$AiCacheTableCreateCompanionBuilder,
      $$AiCacheTableUpdateCompanionBuilder,
      (AiCacheData, BaseReferences<_$AppDatabase, $AiCacheTable, AiCacheData>),
      AiCacheData,
      PrefetchHooks Function()
    >;
typedef $$MediaCategoriesTableCreateCompanionBuilder =
    MediaCategoriesCompanion Function({
      Value<String> id,
      required String name,
      required String iconName,
      required String type,
      Value<String?> platform,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MediaCategoriesTableUpdateCompanionBuilder =
    MediaCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> iconName,
      Value<String> type,
      Value<String?> platform,
      Value<int> sortOrder,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MediaCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $MediaCategoriesTable> {
  $$MediaCategoriesTableFilterComposer({
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

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MediaCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaCategoriesTable> {
  $$MediaCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get platform => $composableBuilder(
    column: $table.platform,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MediaCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaCategoriesTable> {
  $$MediaCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MediaCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaCategoriesTable,
          MediaCategory,
          $$MediaCategoriesTableFilterComposer,
          $$MediaCategoriesTableOrderingComposer,
          $$MediaCategoriesTableAnnotationComposer,
          $$MediaCategoriesTableCreateCompanionBuilder,
          $$MediaCategoriesTableUpdateCompanionBuilder,
          (
            MediaCategory,
            BaseReferences<_$AppDatabase, $MediaCategoriesTable, MediaCategory>,
          ),
          MediaCategory,
          PrefetchHooks Function()
        > {
  $$MediaCategoriesTableTableManager(
    _$AppDatabase db,
    $MediaCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> platform = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaCategoriesCompanion(
                id: id,
                name: name,
                iconName: iconName,
                type: type,
                platform: platform,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String iconName,
                required String type,
                Value<String?> platform = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaCategoriesCompanion.insert(
                id: id,
                name: name,
                iconName: iconName,
                type: type,
                platform: platform,
                sortOrder: sortOrder,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MediaCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaCategoriesTable,
      MediaCategory,
      $$MediaCategoriesTableFilterComposer,
      $$MediaCategoriesTableOrderingComposer,
      $$MediaCategoriesTableAnnotationComposer,
      $$MediaCategoriesTableCreateCompanionBuilder,
      $$MediaCategoriesTableUpdateCompanionBuilder,
      (
        MediaCategory,
        BaseReferences<_$AppDatabase, $MediaCategoriesTable, MediaCategory>,
      ),
      MediaCategory,
      PrefetchHooks Function()
    >;
typedef $$MediaRecordsTableCreateCompanionBuilder =
    MediaRecordsCompanion Function({
      Value<String> id,
      required String userId,
      required String categoryId,
      required String name,
      required String path,
      Value<String?> subtitlePath,
      Value<String?> subtitleContent,
      Value<String?> thumbnailUrl,
      Value<double?> duration,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$MediaRecordsTableUpdateCompanionBuilder =
    MediaRecordsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> categoryId,
      Value<String> name,
      Value<String> path,
      Value<String?> subtitlePath,
      Value<String?> subtitleContent,
      Value<String?> thumbnailUrl,
      Value<double?> duration,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$MediaRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaRecordsTable> {
  $$MediaRecordsTableFilterComposer({
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

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitlePath => $composableBuilder(
    column: $table.subtitlePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subtitleContent => $composableBuilder(
    column: $table.subtitleContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get duration => $composableBuilder(
    column: $table.duration,
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
}

class $$MediaRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaRecordsTable> {
  $$MediaRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitlePath => $composableBuilder(
    column: $table.subtitlePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subtitleContent => $composableBuilder(
    column: $table.subtitleContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get duration => $composableBuilder(
    column: $table.duration,
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

class $$MediaRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaRecordsTable> {
  $$MediaRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get subtitlePath => $composableBuilder(
    column: $table.subtitlePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subtitleContent => $composableBuilder(
    column: $table.subtitleContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );

  GeneratedColumn<double> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MediaRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MediaRecordsTable,
          MediaRecord,
          $$MediaRecordsTableFilterComposer,
          $$MediaRecordsTableOrderingComposer,
          $$MediaRecordsTableAnnotationComposer,
          $$MediaRecordsTableCreateCompanionBuilder,
          $$MediaRecordsTableUpdateCompanionBuilder,
          (
            MediaRecord,
            BaseReferences<_$AppDatabase, $MediaRecordsTable, MediaRecord>,
          ),
          MediaRecord,
          PrefetchHooks Function()
        > {
  $$MediaRecordsTableTableManager(_$AppDatabase db, $MediaRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> subtitlePath = const Value.absent(),
                Value<String?> subtitleContent = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<double?> duration = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaRecordsCompanion(
                id: id,
                userId: userId,
                categoryId: categoryId,
                name: name,
                path: path,
                subtitlePath: subtitlePath,
                subtitleContent: subtitleContent,
                thumbnailUrl: thumbnailUrl,
                duration: duration,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String userId,
                required String categoryId,
                required String name,
                required String path,
                Value<String?> subtitlePath = const Value.absent(),
                Value<String?> subtitleContent = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<double?> duration = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MediaRecordsCompanion.insert(
                id: id,
                userId: userId,
                categoryId: categoryId,
                name: name,
                path: path,
                subtitlePath: subtitlePath,
                subtitleContent: subtitleContent,
                thumbnailUrl: thumbnailUrl,
                duration: duration,
                createdAt: createdAt,
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

typedef $$MediaRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MediaRecordsTable,
      MediaRecord,
      $$MediaRecordsTableFilterComposer,
      $$MediaRecordsTableOrderingComposer,
      $$MediaRecordsTableAnnotationComposer,
      $$MediaRecordsTableCreateCompanionBuilder,
      $$MediaRecordsTableUpdateCompanionBuilder,
      (
        MediaRecord,
        BaseReferences<_$AppDatabase, $MediaRecordsTable, MediaRecord>,
      ),
      MediaRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db, _db.favorites);
  $$CollocationsTableTableManager get collocations =>
      $$CollocationsTableTableManager(_db, _db.collocations);
  $$FlashcardsTableTableManager get flashcards =>
      $$FlashcardsTableTableManager(_db, _db.flashcards);
  $$FlashcardReviewsTableTableManager get flashcardReviews =>
      $$FlashcardReviewsTableTableManager(_db, _db.flashcardReviews);
  $$SyncStatusTableTableManager get syncStatus =>
      $$SyncStatusTableTableManager(_db, _db.syncStatus);
  $$ListeningHistoryTableTableManager get listeningHistory =>
      $$ListeningHistoryTableTableManager(_db, _db.listeningHistory);
  $$AiCacheTableTableManager get aiCache =>
      $$AiCacheTableTableManager(_db, _db.aiCache);
  $$MediaCategoriesTableTableManager get mediaCategories =>
      $$MediaCategoriesTableTableManager(_db, _db.mediaCategories);
  $$MediaRecordsTableTableManager get mediaRecords =>
      $$MediaRecordsTableTableManager(_db, _db.mediaRecords);
}
