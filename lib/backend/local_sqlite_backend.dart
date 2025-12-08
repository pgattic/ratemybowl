import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/models/app_user.dart';
import 'package:rate_my_bowl/models/attribute.dart';
import 'package:rate_my_bowl/models/restroom.dart';
import 'package:rate_my_bowl/models/review.dart';
import 'package:rate_my_bowl/models/review_attribute.dart';
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
    _db = await openDatabase(fullPath, version: 1, onCreate: _onCreate);

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
    required minRatingEnabled,
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
      final a =
          sin(dLat / 2) * sin(dLat / 2) +
          cos(degToRad(lat1)) *
              cos(degToRad(lat2)) *
              sin(dLng / 2) *
              sin(dLng / 2);
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
        final genderMatches =
            (filterFemale == true && gender == Gender.female) ||
            (filterMale == true && gender == Gender.male) ||
            (filterUnisex == true && gender == Gender.unisex);
        if (!genderMatches) {
          continue;
        }
      }

      if (minRatingEnabled && minRating != null && rating < minRating) {
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
    final avgRating = stats.isNotEmpty
        ? stats.first['avg_rating'] as num?
        : null;
    final reviewCount = stats.isNotEmpty
        ? stats.first['review_count'] as num?
        : null;

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

    final reviewIds = rows
        .map((row) => row['review_id'])
        .whereType<int>()
        .toList(growable: false);
    final Map<int, List<ReviewAttribute>> attributesByReview = {};

    if (reviewIds.isNotEmpty) {
      final placeholders = List.filled(reviewIds.length, '?').join(',');
      final attrRows = await _database.rawQuery('''
        SELECT review_id, attribute_id, rating
        FROM review_attribute
        WHERE review_id IN ($placeholders)
        ''', reviewIds);

      for (final attrRow in attrRows) {
        final reviewId = attrRow['review_id'] as int;
        attributesByReview
            .putIfAbsent(reviewId, () => [])
            .add(
              ReviewAttribute(
                reviewId: reviewId,
                attributeId: attrRow['attribute_id'] as int,
                rating: attrRow['rating'] as int,
              ),
            );
      }
    }

    return rows.map((row) {
      final reviewId = row['review_id'] as int;
      return Review(
        reviewId: reviewId,
        restroomId: row['restroom_id'] as int,
        userId: row['user_id'] as String,
        stars: row['stars'] as int,
        reviewDt: DateTime.parse(row['review_dt'] as String),
        notes: row['notes'] as String?,
        displayName: row['display_name'] as String?,
        attributes: List<ReviewAttribute>.unmodifiable(
          attributesByReview[reviewId] ?? const <ReviewAttribute>[],
        ),
      );
    }).toList();
  }

  @override
  Future<void> addReview(Review review) async {
    final reviewId = await _database.insert('review', {
      'restroom_id': review.restroomId,
      'user_id': review.userId,
      'stars': review.stars,
      'review_dt': review.reviewDt.toIso8601String(),
      'notes': review.notes,
    });

    if (review.attributes.isNotEmpty) {
      for (final attr in review.attributes) {
        await _database.insert('review_attribute', {
          'review_id': reviewId,
          'attribute_id': attr.attributeId,
          'rating': attr.rating,
        });
      }
    }
  }

  @override
  Future<Map<int, double>> getAttributeAveragesByRestroomId(
    int restroomId,
  ) async {
    final reviewRows = await _database.query(
      'review',
      columns: ['review_id'],
      where: 'restroom_id = ?',
      whereArgs: [restroomId],
    );

    final reviewIds = reviewRows
        .where((row) => row['review_id'] != null)
        .map((row) => row['review_id'] as int)
        .toList();

    if (reviewIds.isEmpty) {
      return {};
    }

    final attrRows = await _database.rawQuery('''
      SELECT attribute_id, rating
      FROM review_attribute
      WHERE review_id IN (${reviewIds.map((_) => '?').join(',')})
    ''', reviewIds);

    if (attrRows.isEmpty) {
      return {};
    }

    final Map<int, List<int>> attributeRatings = {};
    for (final row in attrRows) {
      final attrId = row['attribute_id'] as int;
      final rating = row['rating'] as int;
      attributeRatings.putIfAbsent(attrId, () => []).add(rating);
    }

    final Map<int, double> averages = {};
    attributeRatings.forEach((attrId, ratings) {
      final sum = ratings.fold<int>(0, (a, b) => a + b);
      averages[attrId] = sum / ratings.length;
    });

    return averages;
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
      CREATE TABLE review_attribute(
        review_id INTEGER NOT NULL,
        attribute_id INTEGER NOT NULL,
        rating INTEGER NOT NULL,
        PRIMARY KEY(review_id, attribute_id),
        FOREIGN KEY(review_id) REFERENCES review(review_id) ON DELETE CASCADE
      )
    ''');

    final seededUsers = await _seedDemoUsers(db);
    await _seedRestrooms(db, seededUsers);
  }

  Future<Map<String, String>> _seedDemoUsers(Database db) async {
    final seedUsers = [
      {
        'key': 'demo',
        'email': 'demo@ratemybowl.app',
        'username': 'demo',
        'password': 'Password123',
      },
      {
        'key': 'taylor',
        'email': 'taylor@ratemybowl.app',
        'username': 'taylorrivers',
        'password': 'Password123',
      },
      {
        'key': 'casey',
        'email': 'casey@ratemybowl.app',
        'username': 'caseyblue',
        'password': 'Password123',
      },
    ];

    final Map<String, String> userIds = {};
    for (final user in seedUsers) {
      final userId = _uuid.v4();
      await db.insert('users', {
        'id': userId,
        'email': user['email'],
        'username': user['username'],
        'password_hash': _hashPassword(user['password'] as String),
      });
      userIds[user['key'] as String] = userId;
    }

    return userIds;
  }

  Future<void> _seedRestrooms(Database db, Map<String, String> userIds) async {
    final defaultUserId = userIds['demo'] ?? userIds.values.first;
    final now = DateTime.now();
    var reviewCounter = 0;

    final seedRestrooms = [
      {
        'name': 'Library Level 1 Commons',
        'gender': Gender.unisex,
        'lat': 40.24865,
        'lng': -111.6512,
        'reviews': [
          {
            'user': 'demo',
            'stars': 5,
            'notes': 'Pristine porcelain and calming vibes.',
            'attributes': [
              {'attribute': Attribute.toiletPaperQuality, 'rating': 5},
              {'attribute': Attribute.handDryingOptions, 'rating': 4},
              {'attribute': Attribute.smell, 'rating': 5},
            ],
          },
          {
            'user': 'taylor',
            'stars': 4,
            'notes': 'Quiet even during finals week and stocked with soap.',
            'attributes': [
              {'attribute': Attribute.easeOfAccess, 'rating': 4},
              {'attribute': Attribute.wheelchairAccessibility, 'rating': 5},
            ],
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
            'user': 'casey',
            'stars': 3,
            'notes': 'Gets busy during lunch but stays tidy.',
            'attributes': [
              {'attribute': Attribute.smell, 'rating': 3},
              {'attribute': Attribute.toiletPaperQuality, 'rating': 2},
              {'attribute': Attribute.handDryingOptions, 'rating': 3},
            ],
          },
          {
            'user': 'demo',
            'stars': 4,
            'notes': 'Crew wipes things down every hour on the hour.',
            'attributes': [
              {'attribute': Attribute.babyChangingStation, 'rating': 2},
              {'attribute': Attribute.handDryingOptions, 'rating': 4},
            ],
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
            'user': 'taylor',
            'stars': 4,
            'notes': 'Bright lighting and endless paper towels.',
            'attributes': [
              {'attribute': Attribute.easeOfAccess, 'rating': 5},
              {'attribute': Attribute.toiletPaperQuality, 'rating': 4},
            ],
          },
          {
            'user': 'casey',
            'stars': 5,
            'notes': 'Plants, music, and spotless counters.',
            'attributes': [
              {'attribute': Attribute.feminineHygieneProducts, 'rating': 5},
              {'attribute': Attribute.smell, 'rating': 5},
              {'attribute': Attribute.handDryingOptions, 'rating': 4},
            ],
          },
        ],
      },
      {
        'name': 'Student Life Center South Entrance',
        'gender': Gender.unisex,
        'lat': 40.2474,
        'lng': -111.6521,
        'reviews': [
          {
            'user': 'demo',
            'stars': 4,
            'notes': 'Locker room cleanup crew deserves a medal.',
            'attributes': [
              {'attribute': Attribute.smell, 'rating': 4},
              {'attribute': Attribute.handDryingOptions, 'rating': 5},
            ],
          },
          {
            'user': 'taylor',
            'stars': 3,
            'notes': 'Good mirrors, but the hallway gets cramped.',
            'attributes': [
              {'attribute': Attribute.easeOfAccess, 'rating': 3},
              {'attribute': Attribute.wheelchairAccessibility, 'rating': 4},
            ],
          },
        ],
      },
      {
        'name': 'Science Center Basement Labs',
        'gender': Gender.male,
        'lat': 40.2468,
        'lng': -111.6488,
        'reviews': [
          {
            'user': 'casey',
            'stars': 2,
            'notes': 'Functional but could use a deeper clean.',
            'attributes': [
              {'attribute': Attribute.smell, 'rating': 2},
              {'attribute': Attribute.toiletPaperQuality, 'rating': 3},
              {'attribute': Attribute.easeOfAccess, 'rating': 2},
            ],
          },
          {
            'user': 'demo',
            'stars': 3,
            'notes': 'Appreciate the hooks and sturdy stalls.',
            'attributes': [
              {'attribute': Attribute.handDryingOptions, 'rating': 2},
              {'attribute': Attribute.bidet, 'rating': 1},
              {'attribute': Attribute.easeOfAccess, 'rating': 3},
            ],
          },
        ],
      },
      {
        'name': 'Fine Arts Pavilion Lobby',
        'gender': Gender.female,
        'lat': 40.2495,
        'lng': -111.6525,
        'reviews': [
          {
            'user': 'taylor',
            'stars': 5,
            'notes': 'Feels like a boutique hotel powder room.',
            'attributes': [
              {'attribute': Attribute.toiletPaperQuality, 'rating': 4},
              {'attribute': Attribute.feminineHygieneProducts, 'rating': 5},
              {'attribute': Attribute.smell, 'rating': 4},
            ],
          },
          {
            'user': 'casey',
            'stars': 4,
            'notes': 'Huge countertops and automatic doors.',
            'attributes': [
              {'attribute': Attribute.handDryingOptions, 'rating': 4},
              {'attribute': Attribute.easeOfAccess, 'rating': 4},
            ],
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

      final reviews = (restroom['reviews'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final review in reviews) {
        final userKey = review['user'] as String?;
        final userId = userKey != null
            ? (userIds[userKey] ?? defaultUserId)
            : defaultUserId;

        final stars = review['stars'] as int;
        final notes = review['notes'] as String?;

        final reviewId = await db.insert('review', {
          'restroom_id': restroomId,
          'user_id': userId,
          'stars': stars,
          'review_dt': now
              .subtract(Duration(days: reviewCounter++))
              .toIso8601String(),
          'notes': notes,
        });

        final attributesData =
            (review['attributes'] as List<dynamic>? ?? const []);
        for (final attr in attributesData.cast<Map<String, dynamic>>()) {
          final attributeValue = attr['attribute'];
          final attributeId = attributeValue is Attribute
              ? attributeValue.id
              : attr['attribute_id'] as int;
          final rating = attr['rating'] as int;
          await db.insert('review_attribute', {
            'review_id': reviewId,
            'attribute_id': attributeId,
            'rating': rating,
          });
        }
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
