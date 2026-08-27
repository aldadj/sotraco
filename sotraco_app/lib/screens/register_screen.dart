import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _chargement = false;
  String? _erreur;
  bool _voirMotDePasse = false;

  Future<void> _sInscrire() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await context.read<AuthProvider>().inscrire(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            passwordConfirmation: _confirmController.text,
            telephone: _phoneController.text.trim(),
            role: 'passager',
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
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
                              const Expanded(child: _RegisterWelcomePanel()),
                              const SizedBox(width: 72),
                              Expanded(child: _RegisterForm(state: this)),
                            ],
                          )
                        : _RegisterForm(state: this),
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

class _RegisterWelcomePanel extends StatelessWidget {
  const _RegisterWelcomePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.brandGlow,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.route_rounded, color: Colors.white, size: 40),
          SizedBox(height: 24),
          Text('Rejoignez le réseau.', style: TextStyle(color: Colors.white, fontSize: 32, height: 1.15, fontWeight: FontWeight.w800)),
          SizedBox(height: 14),
          Text(
            'Créez votre compte passager et retrouvez tous vos bus SOTRACO, en direct, au même endroit.',
            style: TextStyle(color: Colors.white70, fontSize: 15.5, height: 1.55),
          ),
          SizedBox(height: 28),
          Text('Une mobilité plus simple, au quotidien.', style: TextStyle(color: AppColors.accentLight, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RegisterForm extends StatelessWidget {
  final _RegisterScreenState state;
  const _RegisterForm({required this.state});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Form(
        key: state._formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 24),
            Text('Créer un compte', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Votre compte passager en quelques secondes.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 28),
            TextFormField(
              controller: state._nameController,
              decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline_rounded)),
              validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: state._emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
              validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: state._phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone (optionnel)', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: state._passwordController,
              obscureText: !state._voirMotDePasse,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(state._voirMotDePasse ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                  onPressed: () => state.setState(() => state._voirMotDePasse = !state._voirMotDePasse),
                ),
              ),
              validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: state._confirmController,
              obscureText: !state._voirMotDePasse,
              decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outline_rounded)),
              validator: (v) => (v != state._passwordController.text) ? 'Les mots de passe ne correspondent pas' : null,
            ),
            if (state._erreur != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Text(state._erreur!, style: const TextStyle(color: AppColors.danger)),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: state._chargement ? null : state._sInscrire,
              child: state._chargement
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("S'inscrire"),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Vous avez déjà un compte ? Se connecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
