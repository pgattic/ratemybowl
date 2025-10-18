import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _username;

  bool get isAuthenticated => _isAuthenticated;
  String? get username => _username;

  // Simulate login process
  Future<bool> login(String username, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple validation - in a real app, this would call your backend
    if (username.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      _username = username;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Logout function
  void logout() {
    _isAuthenticated = false;
    _username = null;
    notifyListeners();
  }

  // Check if user is already authenticated (useful for app startup)
  void checkAuthStatus() {
    // In a real app, you might check stored tokens or credentials here
    // For now, we'll start with unauthenticated state
    _isAuthenticated = false;
    _username = null;
    notifyListeners();
  }
}
