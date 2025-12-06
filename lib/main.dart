import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rate_my_bowl/backend/backend_provider.dart';
import 'package:rate_my_bowl/controllers/location_controller.dart';
import 'package:rate_my_bowl/screens/home_screen.dart';
import 'package:rate_my_bowl/services/attribute_service.dart';
import 'package:rate_my_bowl/services/auth_service.dart';
import 'package:rate_my_bowl/theme.dart';
import 'package:rate_my_bowl/widgets/app_splash_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const start = String.fromEnvironment('START_PAGE', defaultValue: 'splash');
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await initializeBackend();

  await AttributeService.instance.initialize();

  Widget startPage;
  switch (start) {
    case 'home':
      startPage = HomeScreen();
      break;
    default:
      startPage = AppSplashWrapper();
  }

  runApp(MyApp(startPage: startPage));
}

class MyApp extends StatelessWidget {
  final Widget startPage;

  const MyApp({super.key, required this.startPage});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthService()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (context) => LocationController()),
      ],
      child: MaterialApp(
        title: 'Rate My Bowl',

        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // TODO switch to ThemeMode.system when the color scheme is all set up

        home: startPage,
      ),
    );
  }
}
