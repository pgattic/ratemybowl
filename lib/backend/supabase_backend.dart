import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/models/app_user.dart';
import 'package:rate_my_bowl/models/restroom.dart';
import 'package:rate_my_bowl/models/review.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBackend implements BackendAdapter {
  SupabaseBackend._();
  static final SupabaseBackend instance = SupabaseBackend._();

  bool _initialized = false;
  Stream<AppUser?>? _authStream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseKey = dotenv.env['SUPABASE_KEY'];

    if (supabaseUrl == null || supabaseKey == null) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_KEY must be provided in the .env file.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    _initialized = true;
  }

  SupabaseClient get _client {
    if (!_initialized) {
      throw StateError('SupabaseBackend.initialize must be called first.');
    }
    return Supabase.instance.client;
  }

  @override
  Stream<AppUser?> get authStateChanges {
    _ensureInitialized();
    return _authStream ??= _client.auth.onAuthStateChange.map(
      (event) => _mapUser(event.session?.user),
    );
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    _ensureInitialized();
    return _mapUser(_client.auth.currentUser);
  }

  @override
  Future<AppUser?> signIn(String email, String password) async {
    _ensureInitialized();
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return _mapUser(response.user);
  }

  @override
  Future<void> signOut() async {
    _ensureInitialized();
    await _client.auth.signOut();
  }

  @override
  Future<AppUser?> signUp(
    String email,
    String username,
    String password,
  ) async {
    _ensureInitialized();
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    return _mapUser(response.user);
  }

  @override
  Future<List<Restroom>> getRestroomLocations({
    required double lat,
    required double lng,
    required double radius,
  }) async {
    _ensureInitialized();

    final response = await _client.rpc(
      'get_restrooms_within_radius',
      params: {
        'center_lat': lat,
        'center_lng': lng,
        'radius_meters': radius,
      },
    );

    final List<Restroom> restrooms = [];

    if (response != null) {
      for (final dynamic row in (response as List)) {
        final restroom = _restroomFromRpcRow(
          Map<String, dynamic>.from(row as Map),
        );
        if (restroom != null) {
          restrooms.add(restroom);
        }
      }
    }

    return restrooms;
  }

  @override
  Future<Restroom?> getRestroomById(int id) async {
    _ensureInitialized();
    try {
      final response = await _client
          .from('restroom')
          .select('*')
          .eq('restroom_id', id)
          .single();
      return Restroom.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      debugPrint('Supabase getRestroomById error: $e');
      return null;
    }
  }

  @override
  Future<Restroom> addRestroom(Restroom restroom) async {
    _ensureInitialized();
    final response = await _client
        .from('restroom')
        .insert(restroom.toJson())
        .select()
        .single();

    final restroomId = response['restroom_id'];
    return Restroom(
      id: restroomId is int
          ? restroomId
          : (restroomId is num ? restroomId.toInt() : null),
      name: response['name'] ?? restroom.name,
      coordinates: restroom.coordinates,
      gender: restroom.gender,
      rating: 0.0,
      reviewCount: 0,
      attributes: const [],
    );
  }

  @override
  Future<List<Review>> getReviewsByRestroomId(int restroomId) async {
    _ensureInitialized();
    final response = await _client
        .from('review')
        .select('*')
        .eq('restroom_id', restroomId)
        .order('review_dt', ascending: false);

    final List<Review> reviews = [];

    for (final dynamic row in (response as List)) {
      reviews.add(Review.fromJson(Map<String, dynamic>.from(row as Map)));
    }

    return reviews;
  }

  @override
  Future<void> addReview(Review review) async {
    _ensureInitialized();
    await _client.from('review').insert(review.toJson());
  }

  Restroom? _restroomFromRpcRow(Map<String, dynamic> row) {
    double? latitude;
    double? longitude;

    if (row['lat'] != null && row['lng'] != null) {
      latitude = (row['lat'] as num).toDouble();
      longitude = (row['lng'] as num).toDouble();
    } else {
      final coordinates = row['coordinates'];
      if (coordinates != null) {
        if (coordinates is Map) {
          latitude = (coordinates['lat'] ?? coordinates['latitude'])
              ?.toDouble();
          longitude = (coordinates['lng'] ??
                  coordinates['longitude'] ??
                  coordinates['lon'])
              ?.toDouble();
        } else if (coordinates is String) {
          final match =
              RegExp(r'POINT\(([-\d.]+)\s+([-\d.]+)\)').firstMatch(coordinates);
          if (match != null) {
            longitude = double.tryParse(match.group(1)!);
            latitude = double.tryParse(match.group(2)!);
          }
        }
      }
    }

    if (latitude == null || longitude == null) {
      return null;
    }

    final avgRating = row['avg_rating'];
    final rating = avgRating != null ? (avgRating as num).toDouble() : 0.0;

    final reviewCount = row['review_count'];
    final count = reviewCount != null ? (reviewCount as num).toInt() : 0;

    final genderValue = row['gender'] ?? 0;
    final gender = Restroom.getGender(
      genderValue is int ? genderValue : int.tryParse('$genderValue') ?? 0,
    );

    final attributesData = row['attributes'];
    final List<String> attributes = [];
    if (attributesData != null) {
      if (attributesData is List) {
        attributes.addAll(attributesData.map((e) => e.toString()));
      } else if (attributesData is String) {
        attributes.addAll(attributesData.split(',').map((e) => e.trim()));
      }
    }

    final restroomId = row['restroom_id'];

    return Restroom(
      id: restroomId is int
          ? restroomId
          : (restroomId is num ? restroomId.toInt() : null),
      name: row['name'] ?? 'Unnamed Restroom',
      coordinates: LatLng(latitude, longitude),
      gender: gender,
      rating: rating,
      reviewCount: count,
      attributes: attributes,
    );
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata;
    String? username;
    if (metadata is Map<String, dynamic>) {
      final value = metadata['username'];
      if (value != null) {
        username = value.toString();
      }
    }
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      username: username ?? '',
    );
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('SupabaseBackend.initialize must be awaited before use');
    }
  }
}
