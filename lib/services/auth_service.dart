import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _username;

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;

  Future<bool> login(String username, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Replace once we have a backend
    if (username.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      _username = username;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String email, String username, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (email.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      _username = username;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    _username = null;
    notifyListeners();
  }

  void checkAuthStatus() {
    // Once we have a backend, this will check the server for the user's authentication status. For now, we'll start with unauthenticated state.
    _isAuthenticated = false;
    _username = null;
    notifyListeners();
  }
}
