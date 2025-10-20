import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/services/auth_service.dart';
import 'package:rate_my_bowl/widgets/app_splash_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async {

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_PUBLISHABLE_KEY',
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService()..checkAuthStatus(),
      child: MaterialApp(
        title: 'Rate My Bowl',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
        ),
        home: const AppSplashWrapper(),
      ),
    );
  }
}
