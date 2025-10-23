import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _email;

  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;

  Future<bool> login(String email, String password) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Replace once we have a backend
    if (email.isNotEmpty && password.isNotEmpty) {
      _isAuthenticated = true;
      _email = email;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _isAuthenticated = false;
    _email = null;
    notifyListeners();
  }

  void checkAuthStatus() {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      _isAuthenticated = true;
      _email = session.user.email;
      notifyListeners();
    }
    else {
      _isAuthenticated = false;
      _email = null;
      notifyListeners();
    }
  }

  Future<AuthResponse> signup(String email, String password) async {
    return await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }
}
