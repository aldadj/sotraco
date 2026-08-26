import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'public_home_screen.dart';
import 'passager/home_screen.dart';
import 'chauffeur/driver_home_screen.dart';
import 'admin/admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rediriger());
  }

  Future<void> _rediriger() async {
    final auth = context.read<AuthProvider>();
    // Laisse le temps à initialiser() de se terminer
    while (auth.chargement) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    if (!auth.estConnecte) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PublicHomeScreen()));
      return;
    }

    Widget destination;
    if (auth.user!.isAdmin) {
      destination = const AdminHomeScreen();
    } else if (auth.user!.isChauffeur) {
      destination = const DriverHomeScreen();
    } else {
      destination = const PassengerHomeScreen();
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 72),
            const SizedBox(height: 16),
            Text(
              'SOTRACO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vos bus, en direct.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
