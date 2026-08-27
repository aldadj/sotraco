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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rediriger());
  }

  Future<void> _rediriger() async {
    final auth = context.read<AuthProvider>();
    while (auth.chargement) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    await Future.delayed(const Duration(milliseconds: 500));
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            Positioned(top: -60, right: -40, child: _Blob(size: 220, opacity: 0.10)),
            Positioned(bottom: -80, left: -60, child: _Blob(size: 260, opacity: 0.08)),
            Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
                        ),
                        child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 52),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'SOTRACO',
                        style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 4),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Vos bus, en direct.',
                        style: TextStyle(color: Colors.white70, fontSize: 14.5, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 36),
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final double opacity;
  const _Blob({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(opacity)),
    );
  }
}
