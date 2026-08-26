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
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Créer un compte'),
      ),
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
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(color: AppColors.primaryDark, borderRadius: BorderRadius.circular(28)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Rejoignez le réseau.', style: TextStyle(color: Colors.white, fontSize: 34, height: 1.1, fontWeight: FontWeight.w800)),
          SizedBox(height: 16),
          Text('Créez votre compte passager et retrouvez les bus près de vous.', style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
          SizedBox(height: 32),
          Text('Une mobilité plus simple, au quotidien.', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
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
            const Text('SOTRACO', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, letterSpacing: 2.2)),
            const SizedBox(height: 28),
            Text('Créer un compte', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Votre compte passager en quelques secondes.', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 28),
                const Text('Créer un compte passager', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: state._nameController,
                  decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: state._emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
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
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: state._confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => (v != state._passwordController.text) ? 'Les mots de passe ne correspondent pas' : null,
                ),
                if (state._erreur != null) ...[
                  const SizedBox(height: 12),
                  Text(state._erreur!, style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: state._chargement ? null : state._sInscrire,
                  child: state._chargement
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("S'inscrire"),
                ),
                const SizedBox(height: 10),
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
