import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/services/auth_service.dart';
import 'package:rate_my_bowl/login_screen.dart';
import 'package:rate_my_bowl/screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Show login screen if not authenticated
        if (!authService.isAuthenticated) {
          return const LoginScreen();
        }
        
        // Show home screen if authenticated
        return const HomeScreen();
      },
    );
  }
}
