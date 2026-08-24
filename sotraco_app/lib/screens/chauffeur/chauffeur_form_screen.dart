import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ChauffeurFormScreen extends StatefulWidget {
	const ChauffeurFormScreen({super.key});

	@override
	State<ChauffeurFormScreen> createState() => _ChauffeurFormScreenState();
}

class _ChauffeurFormScreenState extends State<ChauffeurFormScreen> {
	final _formKey = GlobalKey<FormState>();
	final _nameController = TextEditingController();
	final _emailController = TextEditingController();
	final _phoneController = TextEditingController();
	final _passwordController = TextEditingController();
	final _confirmController = TextEditingController();
	bool _chargement = false;
	String? _erreur;

	@override
	void dispose() {
		_nameController.dispose();
		_emailController.dispose();
		_phoneController.dispose();
		_passwordController.dispose();
		_confirmController.dispose();
		super.dispose();
	}

	Future<void> _enregistrer() async {
		if (!_formKey.currentState!.validate()) return;
		setState(() {
			_chargement = true;
			_erreur = null;
		});
		try {
			await AdminService.creerChauffeur(
				name: _nameController.text.trim(),
				email: _emailController.text.trim(),
				telephone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
				password: _passwordController.text,
				passwordConfirmation: _confirmController.text,
			);
			if (mounted) Navigator.of(context).pop(true);
		} on ApiException catch (e) {
			if (mounted) setState(() => _erreur = e.message);
		} finally {
			if (mounted) setState(() => _chargement = false);
		}
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: const Text('Enregistrer un chauffeur')),
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.all(24),
					child: Form(
						key: _formKey,
						child: Column(
							children: [
								TextFormField(
									controller: _nameController,
									decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline)),
									validator: (value) => value == null || value.trim().isEmpty ? 'Champ requis' : null,
								),
								const SizedBox(height: 14),
								TextFormField(
									controller: _emailController,
									keyboardType: TextInputType.emailAddress,
									decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
									validator: (value) => value == null || !value.contains('@') ? 'Email invalide' : null,
								),
								const SizedBox(height: 14),
								TextFormField(
									controller: _phoneController,
									keyboardType: TextInputType.phone,
									decoration: const InputDecoration(labelText: 'Téléphone (optionnel)', prefixIcon: Icon(Icons.phone_outlined)),
								),
								const SizedBox(height: 14),
								TextFormField(
									controller: _passwordController,
									obscureText: true,
									decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(Icons.lock_outline)),
									validator: (value) => value == null || value.length < 6 ? '6 caractères minimum' : null,
								),
								const SizedBox(height: 14),
								TextFormField(
									controller: _confirmController,
									obscureText: true,
									decoration: const InputDecoration(labelText: 'Confirmer le mot de passe', prefixIcon: Icon(Icons.lock_outline)),
									validator: (value) => value != _passwordController.text ? 'Les mots de passe ne correspondent pas' : null,
								),
								if (_erreur != null) ...[
									const SizedBox(height: 12),
									Text(_erreur!, style: const TextStyle(color: AppColors.danger)),
								],
								const SizedBox(height: 24),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton(
										onPressed: _chargement ? null : _enregistrer,
										child: _chargement
												? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
												: const Text('Enregistrer le chauffeur'),
									),
								),
							],
						),
					),
				),
			),
		);
	}
}
