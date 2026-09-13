import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ChauffeurProfileScreen extends StatefulWidget {
  const ChauffeurProfileScreen({super.key});

  @override
  State<ChauffeurProfileScreen> createState() => _ChauffeurProfileScreenState();
}

class _ChauffeurProfileScreenState extends State<ChauffeurProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _telephone;
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _chargement = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _name = TextEditingController(text: user.name);
    _email = TextEditingController(text: user.email);
    _telephone = TextEditingController(text: user.telephone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _telephone.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      await context.read<AuthProvider>().modifierProfil(
            name: _name.text.trim(),
            email: _email.text.trim(),
            telephone:
                _telephone.text.trim().isEmpty ? null : _telephone.text.trim(),
            password: _password.text.isEmpty ? null : _password.text,
            passwordConfirmation:
                _password.text.isEmpty ? null : _confirmation.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identifiants mis à jour.')),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _erreur = error.message);
    } catch (error) {
      if (mounted) setState(() => _erreur = error.toString());
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes identifiants'),
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.manage_accounts_rounded,
                  size: 56, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text('Modifiez vos informations de connexion.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Email invalide'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _telephone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe (optionnel)',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
                validator: (value) =>
                    value != null && value.isNotEmpty && value.length < 6
                        ? '6 caractères minimum'
                        : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmation,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: Icon(Icons.lock_reset_rounded),
                ),
                validator: (value) =>
                    _password.text.isNotEmpty && value != _password.text
                        ? 'Les mots de passe ne correspondent pas'
                        : null,
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 14),
                Text(_erreur!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _chargement ? null : _enregistrer,
                  icon: _chargement
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
