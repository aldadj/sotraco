import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../theme/app_theme.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  Future<void> _demanderConnexion(BuildContext context, {String action = 'cette fonctionnalité'}) async {
    final continuer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connexion nécessaire'),
        content: Text('Connectez-vous pour accéder à $action.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Plus tard')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Se connecter')),
        ],
      ),
    );
    if (continuer != true || !context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _ouvrirInscription(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              centerTitle: false,
              titleSpacing: 20,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: _Brand(compact: MediaQuery.sizeOf(context).width < 600),
              actions: [
                if (MediaQuery.sizeOf(context).width >= 600)
                  TextButton(onPressed: () => _demanderConnexion(context, action: 'la carte des bus'), child: const Text('Se connecter'))
                else
                  IconButton(
                    tooltip: 'Se connecter',
                    onPressed: () => _demanderConnexion(context, action: 'la carte des bus'),
                    icon: const Icon(Icons.login_rounded),
                  ),
                if (MediaQuery.sizeOf(context).width >= 600)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilledButton(onPressed: () => _ouvrirInscription(context), child: const Text('Créer un compte')),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      tooltip: 'Créer un compte',
                      onPressed: () => _ouvrirInscription(context),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                    ),
                  ),
              ],
            ),
            SliverToBoxAdapter(child: _HeroSection(onExplore: () => _demanderConnexion(context, action: 'le suivi des bus'))),
            SliverToBoxAdapter(child: _SectionTitle(onTap: () => _demanderConnexion(context, action: 'les itinéraires'), title: 'Tout le réseau, plus simple', subtitle: 'Les informations essentielles pour mieux vous déplacer au Burkina Faso.')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate(const [
                  _Feature(index: 0, icon: Icons.gps_fixed_rounded, title: 'Suivi en direct', text: 'Visualisez les bus en mouvement sur la carte.'),
                  _Feature(index: 1, icon: Icons.alt_route_rounded, title: 'Itinéraires', text: 'Trouvez les lignes qui vous rapprochent.'),
                  _Feature(index: 2, icon: Icons.schedule_rounded, title: 'Horaires utiles', text: 'Préparez vos départs avec confiance.'),
                  _Feature(index: 3, icon: Icons.notifications_active_outlined, title: 'Alertes réseau', text: 'Restez informé des changements.'),
                ]),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 154,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                ),
              ),
            ),
            SliverToBoxAdapter(child: _NetworkBand(onTap: () => _demanderConnexion(context, action: 'la liste des lignes'))),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 36, 20, 46),
                child: Column(
                  children: [
                    const Text('Prêt à simplifier vos trajets ?', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    const Text('Rejoignez SOTRACO et retrouvez vos bus au même endroit.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    FilledButton.icon(onPressed: () => _ouvrirInscription(context), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Commencer maintenant')),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _Footer(
                onLogin: () => _demanderConnexion(context, action: 'votre espace'),
                onRegister: () => _ouvrirInscription(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final bool compact;
  const _Brand({this.compact = false});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(11)), child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 21)),
        if (!compact) ...[
          const SizedBox(width: 9),
          const Text('SOTRACO', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, letterSpacing: 2)),
        ],
      ]);
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onExplore;
  const _HeroSection({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: Color(0x301E824C), blurRadius: 26, offset: Offset(0, 14))],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final large = constraints.maxWidth > 650;
        final copy = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(30)), child: const Text('Votre mobilité, en temps réel', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
          const SizedBox(height: 24),
          Text('Vos trajets en bus,\nsimplifiés.', style: TextStyle(color: Colors.white, fontSize: large ? 32 : 30, height: 1.08, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          const Text('Trouvez une ligne, repérez votre bus et voyagez plus sereinement dans le réseau SOTRACO.', style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
          const SizedBox(height: 24),
          Wrap(spacing: 10, runSpacing: 10, children: [FilledButton(onPressed: onExplore, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary), child: const Text('Voir les bus')), OutlinedButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)), child: const Text('Se connecter'))]),
        ]);
        final visual = TweenAnimationBuilder<double>(
          tween: Tween(begin: -5, end: 5),
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          builder: (context, offset, child) => Transform.translate(offset: Offset(0, offset), child: child),
          child: Container(width: large ? 220 : double.infinity, height: large ? 160 : 150, margin: EdgeInsets.only(top: large ? 0 : 28), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(24)), child: Stack(children: [Positioned(left: 30, top: 24, right: 26, child: Container(height: 4, color: Colors.white54)), Positioned(left: 58, top: 66, right: 48, child: Container(height: 4, color: AppColors.accent)), Positioned(left: 30, top: 108, right: 30, child: Container(height: 4, color: Colors.white38)), const Positioned(left: 42, top: 48, child: _MapDot()), const Positioned(right: 50, top: 48, child: _MapDot()), const Positioned(left: 112, top: 94, child: _MapDot()), Positioned(right: 48, top: 48, child: Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]), child: const Icon(Icons.directions_bus_filled_rounded, color: AppColors.primary, size: 24)))])),
        );
        return large ? Row(children: [Expanded(child: copy), const SizedBox(width: 28), visual]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [copy, visual]);
      }),
    );
  }
}

class _MapDot extends StatelessWidget {
  const _MapDot();
  @override
  Widget build(BuildContext context) => Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle));
}

class _SectionTitle extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  const _SectionTitle({required this.onTap, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(20, 38, 20, 20), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 7), Text(subtitle, style: const TextStyle(color: AppColors.textSecondary))])), TextButton(onPressed: onTap, child: const Text('Explorer'))]));
}

class _Feature extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title;
  final String text;
  const _Feature({required this.index, required this.icon, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => _AnimatedFeature(index: index, icon: icon, title: title, text: text);
}

class _AnimatedFeature extends StatefulWidget {
  final int index;
  final IconData icon;
  final String title;
  final String text;

  const _AnimatedFeature({required this.index, required this.icon, required this.title, required this.text});

  @override
  State<_AnimatedFeature> createState() => _AnimatedFeatureState();
}

class _AnimatedFeatureState extends State<_AnimatedFeature> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future<void>.delayed(Duration(milliseconds: 100 + widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.86, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) => Transform.scale(scale: scale, alignment: Alignment.topLeft, child: child),
                  child: Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(widget.icon, color: AppColors.primary, size: 20)),
                ),
                const Spacer(),
                Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(widget.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkBand extends StatelessWidget {
  final VoidCallback onTap;
  const _NetworkBand({required this.onTap});
  @override
  Widget build(BuildContext context) => Container(color: AppColors.primaryDark, padding: const EdgeInsets.fromLTRB(20, 28, 20, 28), child: Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Le réseau SOTRACO', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)), SizedBox(height: 6), Text('Lignes, arrêts et bus réunis dans une seule expérience.', style: TextStyle(color: Colors.white70))])), IconButton(onPressed: onTap, tooltip: 'Explorer le réseau', icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.accent, size: 28))]));
}

class _Footer extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _Footer({required this.onLogin, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final large = constraints.maxWidth >= 650;
                  final brand = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.directions_bus_filled_rounded, color: AppColors.accent, size: 25),
                          SizedBox(width: 9),
                          Text('SOTRACO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 2.2)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Votre compagnon pour des déplacements\nplus simples au Burkina Faso.',
                        style: TextStyle(color: Colors.white70, height: 1.45),
                      ),
                    ],
                  );
                  final links = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Accès rapide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          TextButton(onPressed: onLogin, child: const Text('Se connecter', style: TextStyle(color: Colors.white70))),
                          TextButton(onPressed: onRegister, child: const Text('Créer un compte', style: TextStyle(color: Colors.white70))),
                        ],
                      ),
                    ],
                  );
                  return large ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [brand, links]) : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [brand, const SizedBox(height: 24), links]);
                },
              ),
              const SizedBox(height: 28),
              const Divider(color: Colors.white24),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(child: Text('© 2026 SOTRACO. Tous droits réservés.', style: TextStyle(color: Colors.white54, fontSize: 12))),
                  Icon(Icons.favorite_rounded, color: AppColors.accent, size: 15),
                  SizedBox(width: 6),
                  Text('Mobilité au Burkina Faso', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
