import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'passager/home_screen.dart';
import 'chauffeur/driver_home_screen.dart';
import 'admin/admin_home_screen.dart';

class PublicHomeScreen extends StatelessWidget {
  const PublicHomeScreen({super.key});

  /// Ouvre directement la liste des bus.
  void _voirLesBus(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PassengerHomeScreen(),
      ),
    );
  }

  void _ouvrirEspace(BuildContext context, AppUser user) {
    final Widget destination;

    if (user.isAdmin) {
      destination = const AdminHomeScreen();
    } else if (user.isChauffeur) {
      destination = const DriverHomeScreen();
    } else {
      destination = const PassengerHomeScreen();
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  String _libelleEspace(AppUser user) {
    if (user.isAdmin) return 'Espace administration';
    if (user.isChauffeur) return 'Espace chauffeur';
    return 'Espace passager';
  }

  IconData _iconeEspace(AppUser user) {
    if (user.isAdmin) return Icons.admin_panel_settings_rounded;
    if (user.isChauffeur) return Icons.drive_eta_rounded;
    return Icons.person_rounded;
  }

  /// Demande une connexion avant d'accéder à une fonctionnalité protégée.
  Future<void> _demanderConnexion(
    BuildContext context, {
    String action = 'cette fonctionnalité',
  }) async {
    final continuer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary,
            ),
            SizedBox(width: 10),
            Text('Connexion nécessaire'),
          ],
        ),
        content: Text(
          'Connectez-vous pour accéder à $action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Plus tard'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Se connecter'),
          ),
        ],
      ),
    );

    if (continuer != true || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  /// Ouvre l'inscription.
  void _ouvrirInscription(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  /// Action intelligente du bouton "Voir les bus".
  ///
  /// - connecté  → liste des bus
  /// - non connecté → demande de connexion
  void _actionVoirLesBus(
    BuildContext context,
    bool estConnecte,
  ) {
    if (estConnecte) {
      _voirLesBus(context);
    } else {
      _demanderConnexion(
        context,
        action: 'le suivi des bus',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final estConnecte = auth.user != null;

    final largeur = MediaQuery.sizeOf(context).width;
    final grandEcran = largeur >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ============================================================
            // APP BAR
            // ============================================================
            SliverAppBar(
              pinned: true,
              centerTitle: false,
              titleSpacing: 20,
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: _Brand(
                compact: largeur < 600,
              ),
              actions: [
                if (estConnecte)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 12,
                      left: 4,
                    ),
                    child: grandEcran
                        ? FilledButton.icon(
                            onPressed: () => _ouvrirEspace(context, auth.user!),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 19,
                            ),
                            label: Text(
                              _libelleEspace(auth.user!),
                            ),
                          )
                        : IconButton(
                            tooltip: _libelleEspace(auth.user!),
                            onPressed: () => _ouvrirEspace(context, auth.user!),
                            icon: Icon(_iconeEspace(auth.user!)),
                          ),
                  )
                else ...[
                  if (grandEcran)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.login_rounded,
                        size: 18,
                      ),
                      label: const Text('Se connecter'),
                    )
                  else
                    IconButton(
                      tooltip: 'Se connecter',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.login_rounded,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 12,
                      left: 4,
                    ),
                    child: grandEcran
                        ? FilledButton.icon(
                            onPressed: () => _ouvrirInscription(context),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                              size: 18,
                            ),
                            label: const Text('Créer un compte'),
                          )
                        : IconButton(
                            tooltip: 'Créer un compte',
                            onPressed: () => _ouvrirInscription(context),
                            icon: const Icon(
                              Icons.person_add_alt_1_rounded,
                            ),
                          ),
                  ),
                ],
              ],
            ),

            // ============================================================
            // HERO
            // ============================================================
            SliverToBoxAdapter(
              child: _HeroSection(
                estConnecte: estConnecte,
                onExplore: () => _actionVoirLesBus(
                  context,
                  estConnecte,
                ),
              ),
            ),

            // ============================================================
            // STATISTIQUES
            // ============================================================
            const SliverToBoxAdapter(
              child: _StatsBand(),
            ),

            // ============================================================
            // SECTION RESEAU
            // ============================================================
            SliverToBoxAdapter(
              child: _SectionTitle(
                onTap: () => _actionVoirLesBus(
                  context,
                  estConnecte,
                ),
                title: 'Tout le réseau, plus simple',
                subtitle:
                    'Les informations essentielles pour mieux vous déplacer au Burkina Faso.',
              ),
            ),

            // ============================================================
            // FEATURES
            // ============================================================
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                20,
                0,
                20,
                28,
              ),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate(
                  const [
                    _Feature(
                      index: 0,
                      icon: Icons.gps_fixed_rounded,
                      title: 'Suivi en direct',
                      text: 'Visualisez les bus en mouvement sur la carte.',
                    ),
                    _Feature(
                      index: 1,
                      icon: Icons.alt_route_rounded,
                      title: 'Itinéraires',
                      text: 'Trouvez les lignes qui vous rapprochent.',
                    ),
                    _Feature(
                      index: 2,
                      icon: Icons.swap_horiz_rounded,
                      title: 'Aller / Retour',
                      text: 'Sachez toujours dans quel sens roule un bus.',
                    ),
                    _Feature(
                      index: 3,
                      icon: Icons.notifications_active_outlined,
                      title: 'Alertes réseau',
                      text: 'Restez informé des changements.',
                    ),
                  ],
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 280,
                  mainAxisExtent: 158,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
              ),
            ),

            // ============================================================
            // BANDEAU RESEAU
            // ============================================================
            SliverToBoxAdapter(
              child: _NetworkBand(
                onTap: () => _actionVoirLesBus(
                  context,
                  estConnecte,
                ),
              ),
            ),

            // ============================================================
            // CALL TO ACTION
            // ============================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  40,
                  20,
                  46,
                ),
                child: Column(
                  children: [
                    Text(
                      estConnecte
                          ? 'Retrouvez vos bus facilement'
                          : 'Prêt à simplifier vos trajets ?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      estConnecte
                          ? 'Consultez les bus disponibles et suivez vos trajets en temps réel.'
                          : 'Rejoignez SOTRACO et retrouvez vos bus au même endroit.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton.icon(
                      onPressed: () {
                        if (estConnecte) {
                          _ouvrirEspace(context, auth.user!);
                        } else {
                          _ouvrirInscription(context);
                        }
                      },
                      icon: Icon(
                        estConnecte
                            ? _iconeEspace(auth.user!)
                            : Icons.arrow_forward_rounded,
                      ),
                      label: Text(
                        estConnecte
                            ? _libelleEspace(auth.user!)
                            : 'Commencer maintenant',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============================================================
            // FOOTER
            // ============================================================
            SliverToBoxAdapter(
              child: _Footer(
                estConnecte: estConnecte,
                onLogin: () => _demanderConnexion(
                  context,
                  action: 'votre espace',
                ),
                onRegister: () => _ouvrirInscription(context),
                onSpace: () => _ouvrirEspace(context, auth.user!),
                spaceLabel: estConnecte ? _libelleEspace(auth.user!) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================================
// BRAND
// ==========================================================================

class _Brand extends StatelessWidget {
  final bool compact;

  const _Brand({
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.directions_bus_filled_rounded,
            color: Colors.white,
            size: 21,
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 9),
          const Text(
            'SOTRACO',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}

// ==========================================================================
// HERO
// ==========================================================================

class _HeroSection extends StatelessWidget {
  final VoidCallback onExplore;
  final bool estConnecte;

  const _HeroSection({
    required this.onExplore,
    required this.estConnecte,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(
        26,
        38,
        26,
        32,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(
          AppRadius.xl,
        ),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: _Blob(
              size: 130,
              opacity: 0.08,
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final large = constraints.maxWidth > 650;

              final copy = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.accentLight,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Votre mobilité, en temps réel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Vos trajets en bus,\nsimplifiés.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: large ? 36 : 31,
                      height: 1.06,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Trouvez une ligne, repérez votre bus et voyagez plus sereinement dans le réseau SOTRACO.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15.5,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: onExplore,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                        ),
                        icon: const Icon(
                          Icons.directions_bus_filled_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Voir les bus',
                        ),
                      ),

                      // Le bouton connexion disparaît
                      // lorsque l'utilisateur est connecté.
                      if (!estConnecte)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white54,
                            ),
                          ),
                          icon: const Icon(
                            Icons.login_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'Se connecter',
                          ),
                        ),
                    ],
                  ),
                ],
              );

              final visual = _LiveMapMock(
                large: large,
              );

              return large
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: copy,
                        ),
                        const SizedBox(width: 32),
                        visual,
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        copy,
                        const SizedBox(height: 28),
                        visual,
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// MINI CARTE ANIMEE
// ==========================================================================

class _LiveMapMock extends StatefulWidget {
  final bool large;

  const _LiveMapMock({
    required this.large,
  });

  @override
  State<_LiveMapMock> createState() => _LiveMapMockState();
}

class _LiveMapMockState extends State<_LiveMapMock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.large ? 240 : double.infinity,
      height: widget.large ? 190 : 170,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _RoutesPainter(),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;

              return Positioned(
                left: 30 + t * (widget.large ? 150 : 220),
                top: 40 + (t * 60),
                child: child!,
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus_filled_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// ROUTES PAINTER
// ==========================================================================

class _RoutesPainter extends CustomPainter {
  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(
        20,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.1,
        size.width * 0.8,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.6,
        size.width - 20,
        size.height * 0.75,
      );

    canvas.drawPath(
      path,
      paint,
    );

    final dotPaint = Paint()..color = AppColors.accentLight;

    canvas.drawCircle(
      Offset(
        20,
        size.height * 0.35,
      ),
      5,
      dotPaint,
    );

    canvas.drawCircle(
      Offset(
        size.width - 20,
        size.height * 0.75,
      ),
      5,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}

// ==========================================================================
// BLOB
// ==========================================================================

class _Blob extends StatelessWidget {
  final double size;
  final double opacity;

  const _Blob({
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(
          opacity,
        ),
      ),
    );
  }
}

// ==========================================================================
// STATS
// ==========================================================================

class _StatsBand extends StatelessWidget {
  const _StatsBand();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        26,
        20,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          const items = [
            _StatItem(
              value: '100%',
              label: 'Suivi en direct',
            ),
            _StatItem(
              value: '2 sens',
              label: 'Aller & retour',
            ),
            _StatItem(
              value: '24/7',
              label: 'Réseau actif',
            ),
          ];

          return compact
              ? Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: items,
                )
              : Row(
                  children: items
                      .map(
                        (e) => Expanded(
                          child: e,
                        ),
                      )
                      .toList(),
                );
        },
      ),
    );
  }
}

// ==========================================================================
// STAT ITEM
// ==========================================================================

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 18,
        horizontal: 16,
      ),
      margin: const EdgeInsets.symmetric(
        horizontal: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          AppRadius.md,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// SECTION TITLE
// ==========================================================================

class _SectionTitle extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.onTap,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        40,
        20,
        20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              size: 17,
            ),
            label: const Text(
              'Explorer',
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// FEATURE
// ==========================================================================

class _Feature extends StatelessWidget {
  final int index;
  final IconData icon;
  final String title;
  final String text;

  const _Feature({
    required this.index,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedFeature(
      index: index,
      icon: icon,
      title: title,
      text: text,
    );
  }
}

// ==========================================================================
// ANIMATED FEATURE
// ==========================================================================

class _AnimatedFeature extends StatefulWidget {
  final int index;
  final IconData icon;
  final String title;
  final String text;

  const _AnimatedFeature({
    required this.index,
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  State<_AnimatedFeature> createState() => _AnimatedFeatureState();
}

class _AnimatedFeatureState extends State<_AnimatedFeature>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 650,
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.14),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future<void>.delayed(
      Duration(
        milliseconds: 100 + widget.index * 100,
      ),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
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
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(
              AppRadius.lg,
            ),
            boxShadow: AppShadows.soft,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0.86,
                  end: 1,
                ),
                duration: const Duration(
                  milliseconds: 900,
                ),
                curve: Curves.elasticOut,
                builder: (
                  context,
                  scale,
                  child,
                ) {
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.topLeft,
                    child: child,
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// NETWORK BAND
// ==========================================================================

class _NetworkBand extends StatelessWidget {
  final VoidCallback onTap;

  const _NetworkBand({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            Color(0xFF083D22),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        20,
        30,
        20,
        30,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Le réseau SOTRACO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Lignes, arrêts et bus réunis dans une seule expérience.',
                  style: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: onTap,
              tooltip: 'Explorer le réseau',
              icon: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// FOOTER
// ==========================================================================

class _Footer extends StatelessWidget {
  final bool estConnecte;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onSpace;
  final String? spaceLabel;

  const _Footer({
    required this.estConnecte,
    required this.onLogin,
    required this.onRegister,
    required this.onSpace,
    required this.spaceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(
        20,
        34,
        20,
        22,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (
                  context,
                  constraints,
                ) {
                  final large = constraints.maxWidth >= 650;

                  final brand = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_bus_filled_rounded,
                            color: AppColors.accentLight,
                            size: 25,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'SOTRACO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Votre compagnon pour des déplacements\nplus simples au Burkina Faso.',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                    ],
                  );

                  final links = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accès rapide',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (estConnecte)
                            TextButton.icon(
                              onPressed: onSpace,
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white70,
                                size: 17,
                              ),
                              label: Text(
                                spaceLabel!,
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            )
                          else ...[
                            TextButton(
                              onPressed: onLogin,
                              child: const Text(
                                'Se connecter',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: onRegister,
                              child: const Text(
                                'Créer un compte',
                                style: TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  );

                  return large
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            brand,
                            links,
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            brand,
                            const SizedBox(
                              height: 24,
                            ),
                            links,
                          ],
                        );
                },
              ),
              const SizedBox(height: 28),
              const Divider(
                color: Colors.white24,
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      '© 2026 SOTRACO. Tous droits réservés.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.favorite_rounded,
                    color: AppColors.accentLight,
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Mobilité au Burkina Faso',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
