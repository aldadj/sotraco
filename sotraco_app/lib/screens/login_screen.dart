import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _chargement = false;
  String? _erreur;
  bool _voirMotDePasse = false;

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await context.read<AuthProvider>().connecter(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _basculerMotDePasse() {
    setState(() => _voirMotDePasse = !_voirMotDePasse);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 800;
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: desktop ? 1120 : 520),
                  child: Padding(
                    padding: EdgeInsets.all(desktop ? 48 : 24),
                    child: desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(child: _WelcomePanel()),
                              const SizedBox(width: 72),
                              Expanded(child: _LoginFormContent(state: this)),
                            ],
                          )
                        : _LoginFormContent(state: this),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x241E824C), blurRadius: 30, offset: Offset(0, 16))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BrandMark(inverse: true),
          const SizedBox(height: 72),
          const Text('Vos trajets en bus,\nsimplifiés.', style: TextStyle(color: Colors.white, fontSize: 36, height: 1.08, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Text('Suivez les bus SOTRACO en temps réel et voyagez avec plus de sérénité.', style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 16, height: 1.5)),
          const SizedBox(height: 32),
          Wrap(spacing: 10, runSpacing: 10, children: const [
            _FeaturePill(icon: Icons.gps_fixed_rounded, label: 'Suivi en direct'),
            _FeaturePill(icon: Icons.route_rounded, label: 'Itinéraires utiles'),
          ]),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 7), Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))]),
      );
}

class _BrandMark extends StatelessWidget {
  final bool inverse;
  const _BrandMark({this.inverse = false});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: inverse ? Colors.white : AppColors.primary, borderRadius: BorderRadius.circular(12)), child: Icon(Icons.directions_bus_filled_rounded, color: inverse ? AppColors.primary : Colors.white, size: 22)),
        const SizedBox(width: 10),
        Text('SOTRACO', style: TextStyle(color: inverse ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.w800, letterSpacing: 2.2)),
      ]);
}

class _LoginFormContent extends StatelessWidget {
  final _LoginScreenState state;
  const _LoginFormContent({required this.state});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: state._formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _BrandMark(),
            const SizedBox(height: 42),
            Text('Bon retour !', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Connectez-vous pour retrouver vos bus.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
            const SizedBox(height: 32),
            TextFormField(controller: state._emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null),
            const SizedBox(height: 16),
            TextFormField(controller: state._passwordController, obscureText: !state._voirMotDePasse, decoration: InputDecoration(labelText: 'Mot de passe', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(state._voirMotDePasse ? Icons.visibility_off : Icons.visibility), onPressed: state._basculerMotDePasse)), validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null),
            if (state._erreur != null) ...[const SizedBox(height: 12), Text(state._erreur!, style: const TextStyle(color: AppColors.danger))],
            const SizedBox(height: 28),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: state._chargement ? null : state._seConnecter, child: state._chargement ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Se connecter'))),
            const SizedBox(height: 14),
            Center(child: TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())), child: const Text("Pas encore de compte ? S'inscrire"))),
          ]),
        ),
      );
}
