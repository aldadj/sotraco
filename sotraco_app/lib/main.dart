import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/bus_provider.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TEMPORAIRE : permet de repartir systématiquement
  // sur l'écran de connexion pendant les tests.
  await ApiService.clearToken();

  runApp(const SotracoApp());
}

class SotracoApp extends StatelessWidget {
  const SotracoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialiser(),
        ),
        ChangeNotifierProvider(
          create: (_) => BusProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'SOTRACO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}