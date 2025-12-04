import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/models/app_user.dart';
import 'package:rate_my_bowl/models/restroom.dart';
import 'package:rate_my_bowl/models/review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class LocalSqliteBackend implements BackendAdapter {
  LocalSqliteBackend._();
  static final LocalSqliteBackend instance = LocalSqliteBackend._();

  static const _prefsKey = 'rmb_current_user_id';

  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();
  final Uuid _uuid = const Uuid();

  Database? _db;
  SharedPreferences? _prefs;
  AppUser? _currentUser;

  @override
  Future<void> initialize() async {
    if (_db != null) return;

    final dbPath = await getDatabasesPath();
    final fullPath = p.join(dbPath, 'ratemybowl_offline.db');
    _db = await openDatabase(
      fullPath,
      version: 1,
      onCreate: _onCreate,
    );

    _prefs = await SharedPreferences.getInstance();
    await _restoreSession();
  }

  @override
  Stream<AppUser?> get authStateChanges => _authController.stream;

  @override
  Future<AppUser?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    final storedId = _prefs?.getString(_prefsKey);
    if (storedId == null) {
      return null;
    }

    final user = await _getUserById(storedId);
    if (user != null) {
      await _setCurrentUser(user, persist: false);
    }
    return user;
  }

  @override
  Future<AppUser?> signIn(String email, String password) async {
    final hashed = _hashPassword(password);
    final result = await _database.query(
      'users',
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    final row = result.first;
    if (row['password_hash'] != hashed) {
      return null;
    }

    final user = AppUser(
      id: row['id'] as String,
      email: row['email'] as String,
      username: row['username'] as String,
    );

    await _setCurrentUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _setCurrentUser(null);
  }

  @override
  Future<AppUser?> signUp(
    String email,
    String username,
    String password,
  ) async {
    final existing = await _database.query(
      'users',
      where: 'LOWER(email) = LOWER(?)',
      whereArgs: [email],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return null;
    }

    final id = _uuid.v4();

    await _database.insert('users', {
      'id': id,
      'email': email,
      'username': username,
      'password_hash': _hashPassword(password),
    });

    final user = AppUser(id: id, email: email, username: username);
    await _setCurrentUser(user);
    return user;
  }

  @override
  Future<List<Restroom>> getRestroomLocations({
    required double lat,
    required double lng,
    required double radius,
    bool? filterFemale,
    bool? filterMale,
    bool? filterUnisex,
    double? minRating,
  }) async {
    final restroomsData = await _database.query('restroom');
    final statsRows = await _database.rawQuery('''
      SELECT restroom_id, AVG(stars) AS avg_rating, COUNT(*) AS review_count
      FROM review
      GROUP BY restroom_id
    ''');

    final stats = <int, Map<String, num>>{};
    for (final row in statsRows) {
      final restroomId = (row['restroom_id'] as int?) ?? 0;
      stats[restroomId] = {
        'avg_rating': (row['avg_rating'] as num?) ?? 0,
        'review_count': (row['review_count'] as num?) ?? 0,
      };
    }

    final List<Restroom> restrooms = [];
    final earthRadius = 6371000.0;

    double degToRad(double deg) => deg * pi / 180.0;

    double haversineDistance(
      double lat1,
      double lng1,
      double lat2,
      double lng2,
    ) {
      final dLat = degToRad(lat2 - lat1);
      final dLng = degToRad(lng2 - lng1);
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(degToRad(lat1)) * cos(degToRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
      final c = 2 * atan2(sqrt(a), sqrt(1 - a));
      return earthRadius * c;
    }

    for (final row in restroomsData) {
      final restroomLat = (row['latitude'] as num).toDouble();
      final restroomLng = (row['longitude'] as num).toDouble();
      final distance = haversineDistance(lat, lng, restroomLat, restroomLng);

      if (distance > radius) {
        continue;
      }

      final restroomId = row['restroom_id'] as int;
      final stat = stats[restroomId];
      final gender = Restroom.getGender(row['gender'] as int);
      final rating = stat?['avg_rating']?.toDouble() ?? 0.0;

      if (filterFemale != null || filterMale != null || filterUnisex != null) {
        final genderMatches = (filterFemale == true && gender == Gender.female) ||
            (filterMale == true && gender == Gender.male) ||
            (filterUnisex == true && gender == Gender.unisex);
        if (!genderMatches) {
          continue;
        }
      }

      if (minRating != null && rating < minRating) {
        continue;
      }

      restrooms.add(
        Restroom(
          id: restroomId,
          name: row['name'] as String,
          coordinates: LatLng(restroomLat, restroomLng),
          gender: gender,
          rating: rating,
          reviewCount: stat?['review_count']?.toInt() ?? 0,
          attributes: const [],
        ),
      );
    }

    return restrooms;
  }

  @override
  Future<Restroom?> getRestroomById(int id) async {
    final rows = await _database.query(
      'restroom',
      where: 'restroom_id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final stats = await _database.rawQuery(
      '''
      SELECT AVG(stars) AS avg_rating, COUNT(*) AS review_count
      FROM review
      WHERE restroom_id = ?
      ''',
      [id],
    );
    final avgRating = stats.isNotEmpty ? stats.first['avg_rating'] as num? : null;
    final reviewCount =
        stats.isNotEmpty ? stats.first['review_count'] as num? : null;

    return Restroom(
      id: row['restroom_id'] as int,
      name: row['name'] as String,
      coordinates: LatLng(
        (row['latitude'] as num).toDouble(),
        (row['longitude'] as num).toDouble(),
      ),
      gender: Restroom.getGender(row['gender'] as int),
      rating: avgRating?.toDouble() ?? 0.0,
      reviewCount: reviewCount?.toInt() ?? 0,
      attributes: const [],
    );
  }

  @override
  Future<Restroom> addRestroom(Restroom restroom) async {
    final restroomId = await _database.insert('restroom', {
      'name': restroom.name,
      'gender': restroom.genderInt,
      'latitude': restroom.coordinates.latitude,
      'longitude': restroom.coordinates.longitude,
    });

    return Restroom(
      id: restroomId,
      name: restroom.name,
      coordinates: restroom.coordinates,
      gender: restroom.gender,
      rating: 0.0,
      reviewCount: 0,
      attributes: const [],
    );
  }

  @override
  Future<List<Review>> getReviewsByRestroomId(int restroomId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT 
        r.review_id,
        r.restroom_id,
        r.user_id,
        r.stars,
        r.review_dt,
        r.notes,
        u.username AS display_name
      FROM review r
      LEFT JOIN users u ON r.user_id = u.id
      WHERE r.restroom_id = ?
      ORDER BY datetime(r.review_dt) DESC
      ''',
      [restroomId],
    );

    return rows
        .map(
          (row) => Review(
            reviewId: row['review_id'] as int,
            restroomId: row['restroom_id'] as int,
            userId: row['user_id'] as String,
            stars: row['stars'] as int,
            reviewDt: DateTime.parse(row['review_dt'] as String),
            notes: row['notes'] as String?,
            displayName: row['display_name'] as String?,
          ),
        )
        .toList();
  }

  @override
  Future<void> addReview(Review review) async {
    await _database.insert('review', {
      'restroom_id': review.restroomId,
      'user_id': review.userId,
      'stars': review.stars,
      'review_dt': review.reviewDt.toIso8601String(),
      'notes': review.notes,
    });
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        username TEXT NOT NULL,
        password_hash TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE restroom(
        restroom_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gender INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE review(
        review_id INTEGER PRIMARY KEY AUTOINCREMENT,
        restroom_id INTEGER NOT NULL,
        user_id TEXT NOT NULL,
        stars INTEGER NOT NULL,
        review_dt TEXT NOT NULL,
        notes TEXT,
        FOREIGN KEY(restroom_id) REFERENCES restroom(restroom_id) ON DELETE CASCADE,
        FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE attribute(
        attr_id INTEGER PRIMARY KEY AUTOINCREMENT,
        attr_key TEXT NOT NULL,
        display_name TEXT NOT NULL,
        data_type TEXT NOT NULL,
        unit TEXT,
        min_value INTEGER,
        max_value INTEGER,
        applies_to TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attribute_option(
        option_id INTEGER PRIMARY KEY AUTOINCREMENT,
        attr_id INTEGER NOT NULL,
        value_key TEXT NOT NULL,
        display_name TEXT NOT NULL,
        FOREIGN KEY(attr_id) REFERENCES attribute(attr_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE attribute_value(
        restroom_id INTEGER NOT NULL,
        attr_id INTEGER NOT NULL,
        value_bool INTEGER,
        value_int INTEGER,
        value_decimal REAL,
        value_text TEXT,
        value_option_id INTEGER,
        review_id INTEGER,
        PRIMARY KEY(restroom_id, attr_id),
        FOREIGN KEY(restroom_id) REFERENCES restroom(restroom_id),
        FOREIGN KEY(attr_id) REFERENCES attribute(attr_id),
        FOREIGN KEY(value_option_id) REFERENCES attribute_option(option_id),
        FOREIGN KEY(review_id) REFERENCES review(review_id)
      )
    ''');

    final demoUserId = await _seedDemoUser(db);
    await _seedRestrooms(db, demoUserId);
  }

  Future<String> _seedDemoUser(Database db) async {
    final demoId = _uuid.v4();
    await db.insert('users', {
      'id': demoId,
      'email': 'demo@ratemybowl.app',
      'username': 'demo',
      'password_hash': _hashPassword('Password123'),
    });
    return demoId;
  }

  Future<void> _seedRestrooms(Database db, String demoUserId) async {
    final seedRestrooms = [
      {
        'name': 'Library Level 1 Commons',
        'gender': Gender.unisex,
        'lat': 40.24865,
        'lng': -111.6512,
        'reviews': [
          {
            'stars': 5,
            'notes': 'Pristine porcelain and calming vibes.'
          },
        ],
      },
      {
        'name': 'Cougar Eat Hallway',
        'gender': Gender.male,
        'lat': 40.2489,
        'lng': -111.6509,
        'reviews': [
          {
            'stars': 3,
            'notes': 'Gets busy during lunch but stays tidy.'
          },
        ],
      },
      {
        'name': 'Engineering Building Atrium',
        'gender': Gender.female,
        'lat': 40.2479,
        'lng': -111.6499,
        'reviews': [
          {
            'stars': 4,
            'notes': 'Bright lighting and endless paper towels.'
          },
        ],
      },
    ];

    for (final restroom in seedRestrooms) {
      final restroomId = await db.insert('restroom', {
        'name': restroom['name'],
        'gender': _genderToInt(restroom['gender'] as Gender),
        'latitude': restroom['lat'],
        'longitude': restroom['lng'],
      });

      final reviews = (restroom['reviews'] as List)
          .map((review) => Map<String, Object>.from(review as Map))
          .toList();
      for (final review in reviews) {
        await db.insert('review', {
          'restroom_id': restroomId,
          'user_id': demoUserId,
          'stars': review['stars'],
          'review_dt': DateTime.now().toIso8601String(),
          'notes': review['notes'],
        });
      }
    }
  }

  Future<void> _restoreSession() async {
    final storedId = _prefs?.getString(_prefsKey);
    if (storedId == null) {
      return;
    }
    final user = await _getUserById(storedId);
    if (user != null) {
      await _setCurrentUser(user, persist: false);
    }
  }

  Future<void> _setCurrentUser(AppUser? user, {bool persist = true}) async {
    _currentUser = user;
    if (persist) {
      if (user == null) {
        await _prefs?.remove(_prefsKey);
      } else {
        await _prefs?.setString(_prefsKey, user.id);
      }
    }
    _authController.add(user);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<AppUser?> _getUserById(String id) async {
    final rows = await _database.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    return AppUser(
      id: row['id'] as String,
      email: row['email'] as String,
      username: row['username'] as String,
    );
  }

  Database get _database {
    final db = _db;
    if (db == null) {
      throw StateError('LocalSqliteBackend.initialize must be called first.');
    }
    return db;
  }

  int _genderToInt(Gender gender) {
    switch (gender) {
      case Gender.unisex:
        return 0;
      case Gender.male:
        return 1;
      case Gender.female:
        return 2;
    }
  }
}
