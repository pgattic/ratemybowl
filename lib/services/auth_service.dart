import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rate_my_bowl/backend/backend_adapter.dart';
import 'package:rate_my_bowl/backend/backend_provider.dart';
import 'package:rate_my_bowl/models/app_user.dart';

class AuthService extends ChangeNotifier {
  final BackendAdapter _backend = backendAdapter;

  StreamSubscription<AppUser?>? _authSubscription;
  bool _isAuthenticated = false;
  String? _email;
  AppUser? _user;

  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;
  String? get currentUserId => _user?.id;

  AuthService() {
    _authSubscription = _backend.authStateChanges.listen((user) {
      _setUser(user);
    });
  }

  Future<void> checkAuthStatus() async {
    final user = await _backend.getCurrentUser();
    _setUser(user);
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await _backend.signIn(email, password);
      final success = user != null;
      if (success) {
        _setUser(user);
      }
      return success;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _backend.signOut();
    _setUser(null);
  }

  Future<bool> register(String email, String username, String password) async {
    try {
      final user = await _backend.signUp(email, username, password);
      final success = user != null;
      if (success) {
        _setUser(user);
      }
      return success;
    } catch (e) {
      debugPrint('Signup error: $e');
      return false;
    }
  }

  void _setUser(AppUser? user) {
    _user = user;
    _isAuthenticated = user != null;
    _email = user?.email;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
