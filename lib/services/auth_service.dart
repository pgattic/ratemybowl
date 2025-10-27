import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _email;

  bool get isAuthenticated => _isAuthenticated;
  String? get email => _email;

  AuthService() {
    // Listen to auth state changes for persistent authentication
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _isAuthenticated = true;
        _email = session.user.email;
      } else {
        _isAuthenticated = false;
        _email = null;
      }
      notifyListeners();
    });
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // The auth state listener will automatically update _isAuthenticated and _email
      return response.user != null;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  void logout() {
    Supabase.instance.client.auth.signOut();
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

  Future<bool> signup(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _isAuthenticated = true;
        _email = response.user!.email;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }

    Future<bool> register(String email, String username, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
        }
      );
      
      if (response.user != null) {
        _isAuthenticated = true;
        _email = response.user!.email;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Signup error: $e');
      return false;
    }
  }
}
