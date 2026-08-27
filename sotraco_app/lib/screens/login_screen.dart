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
      await context.read<AuthProvider>().connecter(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) {
        setState(() => _chargement = false);
      }
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

      // Permet au contenu de passer derrière l'AppBar
      extendBodyBehindAppBar: true,

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 800;

            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: desktop ? 1120 : 480,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(desktop ? 48 : 24),
                    child: desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: _LoginWelcomePanel(),
                              ),
                              const SizedBox(width: 72),
                              Expanded(
                                child: _LoginForm(state: this),
                              ),
                            ],
                          )
                        : _LoginForm(state: this),
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

class _LoginWelcomePanel extends StatelessWidget {
  const _LoginWelcomePanel();

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
          Icon(
            Icons.directions_bus_filled_rounded,
            color: Colors.white,
            size: 40,
          ),
          SizedBox(height: 24),
          Text(
            'Bon retour parmi nous.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Connectez-vous pour suivre vos bus SOTRACO en temps réel, où que vous soyez.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final _LoginScreenState state;

  const _LoginForm({
    required this.state,
  });

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
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Se connecter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Accédez à votre espace SOTRACO.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),

            TextFormField(
              controller: state._emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@'))
                      ? 'Email invalide'
                      : null,
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: state._passwordController,
              obscureText: !state._voirMotDePasse,
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    state._voirMotDePasse
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: () {
                    state.setState(() {
                      state._voirMotDePasse =
                          !state._voirMotDePasse;
                    });
                  },
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6)
                      ? '6 caractères minimum'
                      : null,
            ),

            if (state._erreur != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state._erreur!,
                  style: const TextStyle(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 28),

            ElevatedButton(
              onPressed:
                  state._chargement
                      ? null
                      : state._seConnecter,
              child: state._chargement
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Se connecter'),
            ),

            const SizedBox(height: 18),

            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Pas encore de compte ? Créer un compte',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}