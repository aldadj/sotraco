import 'package:flutter/material.dart';
import '../../models/ligne.dart';
import '../../services/admin_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Formulaire d'ajout OU de modification d'une ligne (départ/destination
/// obligatoires, comme demandé). Si [ligne] est fourni, on est en mode édition.
class LigneFormScreen extends StatefulWidget {
  final Ligne? ligne;
  const LigneFormScreen({super.key, this.ligne});

  @override
  State<LigneFormScreen> createState() => _LigneFormScreenState();
}

class _LigneFormScreenState extends State<LigneFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nomController;
  late final TextEditingController _departController;
  late final TextEditingController _destinationController;
  late final TextEditingController _descriptionController;
  String _couleur = '#0F7A45';
  bool _chargement = false;
  String? _erreur;

  bool get _estEdition => widget.ligne != null;

  final List<String> _palette = ['#0F7A45', '#F2A104', '#E1425A', '#2F7DE1', '#7A4EAB'];

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.ligne?.code ?? '');
    _nomController = TextEditingController(text: widget.ligne?.nom ?? '');
    _departController = TextEditingController(text: widget.ligne?.depart ?? '');
    _destinationController = TextEditingController(text: widget.ligne?.destination ?? '');
    _descriptionController = TextEditingController(text: widget.ligne?.description ?? '');
    if (widget.ligne != null) _couleur = widget.ligne!.couleur;
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      if (_estEdition) {
        await AdminService.modifierLigne(
          widget.ligne!.id,
          code: _codeController.text.trim(),
          nom: _nomController.text.trim(),
          depart: _departController.text.trim(),
          destination: _destinationController.text.trim(),
          couleur: _couleur,
          description: _descriptionController.text.trim(),
        );
      } else {
        await AdminService.creerLigne(
          code: _codeController.text.trim(),
          nom: _nomController.text.trim(),
          depart: _departController.text.trim(),
          destination: _destinationController.text.trim(),
          couleur: _couleur,
          description: _descriptionController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(_estEdition ? 'Modifier la ligne' : 'Nouvelle ligne', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              background: Container(decoration: const BoxDecoration(gradient: AppColors.heroGradient)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Informations générales', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.4)),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _codeController,
                            decoration: const InputDecoration(labelText: 'Code (ex: L1)', prefixIcon: Icon(Icons.tag_rounded)),
                            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _nomController,
                            decoration: const InputDecoration(labelText: 'Nom de la ligne', prefixIcon: Icon(Icons.alt_route_rounded)),
                            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(labelText: 'Description (optionnel)', prefixIcon: Icon(Icons.notes_rounded)),
                            maxLines: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Itinéraire', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.4)),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _departController,
                            decoration: const InputDecoration(labelText: 'Point de départ', prefixIcon: Icon(Icons.trip_origin_rounded)),
                            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _destinationController,
                            decoration: const InputDecoration(labelText: 'Destination', prefixIcon: Icon(Icons.flag_rounded)),
                            validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Couleur de la ligne', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.4)),
                          const SizedBox(height: 14),
                          Row(
                            children: _palette.map((hex) {
                              final couleur = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                              final selectionnee = _couleur == hex;
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: GestureDetector(
                                  onTap: () => setState(() => _couleur = hex),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: selectionnee ? 42 : 36,
                                    height: selectionnee ? 42 : 36,
                                    decoration: BoxDecoration(
                                      color: couleur,
                                      shape: BoxShape.circle,
                                      border: selectionnee ? Border.all(color: Colors.black87, width: 2.5) : null,
                                      boxShadow: selectionnee ? [BoxShadow(color: couleur.withOpacity(0.4), blurRadius: 10)] : null,
                                    ),
                                    child: selectionnee ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    if (_erreur != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                        child: Text(_erreur!, style: const TextStyle(color: AppColors.danger)),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _chargement ? null : _enregistrer,
                        child: _chargement
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_estEdition ? 'Enregistrer les modifications' : 'Créer la ligne'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
