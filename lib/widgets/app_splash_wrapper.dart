import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/screens/splash_screen.dart';
import 'package:rate_my_bowl/widgets/auth_wrapper.dart';
import 'package:rate_my_bowl/services/auth_service.dart';

class AppSplashWrapper extends StatefulWidget {
  const AppSplashWrapper({super.key});

  @override
  State<AppSplashWrapper> createState() => _AppSplashWrapperState();
}

class _AppSplashWrapperState extends State<AppSplashWrapper> {
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        if (authService.isAuthenticated && _showSplash) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _showSplash = false;
            });
          });
        }

        if (_showSplash) {
          return SplashScreen(
            onAnimationComplete: () {
              setState(() {
                _showSplash = false;
              });
            },
          );
        }
        
        return const AuthWrapper();
      },
    );
  }
}
