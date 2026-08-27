import 'package:flutter/material.dart';
import '../../models/bus.dart';
import '../../models/ligne.dart';
import '../../services/admin_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Formulaire d'ajout OU de modification d'un bus. Permet d'assigner
/// une ligne et un chauffeur via des menus déroulants.
class BusFormScreen extends StatefulWidget {
  final Bus? bus;
  final List<Ligne> lignes;
  const BusFormScreen({super.key, this.bus, required this.lignes});

  @override
  State<BusFormScreen> createState() => _BusFormScreenState();
}

class _BusFormScreenState extends State<BusFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _numeroController;
  late final TextEditingController _immatController;
  late final TextEditingController _capaciteController;
  int? _ligneId;
  String _statut = 'actif';
  bool _chargement = false;
  String? _erreur;

  bool get _estEdition => widget.bus != null;

  @override
  void initState() {
    super.initState();
    _numeroController = TextEditingController(text: widget.bus?.numero ?? '');
    _immatController = TextEditingController(text: widget.bus?.immatriculation ?? '');
    _capaciteController = TextEditingController(text: '60');
    _ligneId = widget.bus?.ligneId;
    if (widget.bus != null) _statut = widget.bus!.statut;
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      if (_estEdition) {
        await AdminService.modifierBus(
          widget.bus!.id,
          numero: _numeroController.text.trim(),
          immatriculation: _immatController.text.trim(),
          capacite: int.tryParse(_capaciteController.text),
          ligneId: _ligneId,
          statut: _statut,
        );
      } else {
        await AdminService.creerBus(
          numero: _numeroController.text.trim(),
          immatriculation: _immatController.text.trim(),
          capacite: int.tryParse(_capaciteController.text),
          ligneId: _ligneId,
          statut: _statut,
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
              title: Text(_estEdition ? 'Modifier le bus' : 'Nouveau bus', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                    _FormSection(
                      titre: 'Identité du véhicule',
                      children: [
                        TextFormField(
                          controller: _numeroController,
                          decoration: const InputDecoration(labelText: 'Numéro (ex: BUS-004)', prefixIcon: Icon(Icons.confirmation_number_outlined)),
                          validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _immatController,
                          decoration: const InputDecoration(labelText: 'Immatriculation', prefixIcon: Icon(Icons.badge_outlined)),
                          validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _capaciteController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Capacité (places)', prefixIcon: Icon(Icons.event_seat_outlined)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _FormSection(
                      titre: 'Affectation',
                      children: [
                        DropdownButtonFormField<int?>(
                          value: _ligneId,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Ligne assignée', prefixIcon: Icon(Icons.alt_route_rounded)),
                          items: [
                            const DropdownMenuItem<int?>(value: null, child: Text('Aucune')),
                            ...widget.lignes.map((l) => DropdownMenuItem<int?>(value: l.id, child: Text('${l.code} - ${l.nom}', maxLines: 1, overflow: TextOverflow.ellipsis))),
                          ],
                          onChanged: (v) => setState(() => _ligneId = v),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: _statut,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Statut', prefixIcon: Icon(Icons.info_outline_rounded)),
                          items: const [
                            DropdownMenuItem(value: 'actif', child: Text('Actif')),
                            DropdownMenuItem(value: 'inactif', child: Text('Inactif')),
                            DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
                          ],
                          onChanged: (v) => setState(() => _statut = v ?? 'actif'),
                        ),
                      ],
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
                            : Text(_estEdition ? 'Enregistrer les modifications' : 'Créer le bus', maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _FormSection extends StatelessWidget {
  final String titre;
  final List<Widget> children;
  const _FormSection({required this.titre, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg), boxShadow: AppShadows.soft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.4)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
