import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/bus_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bus_card.dart';
import '../splash_screen.dart';
import 'bus_map_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
  int? _ligneSelectionnee;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BusProvider>();

      provider.chargerLignes();
      provider.chargerBuses();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _rafraichir() async {
    final provider = context.read<BusProvider>();

    await Future.wait([
      provider.chargerLignes(),
      provider.chargerBuses(
        ligneId: _ligneSelectionnee,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final auth = context.watch<AuthProvider>();

    final busEnMarche =
        busProvider.buses.where((b) => b.enDirect).length;

    final nom = auth.user?.name.split(' ').first ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: _rafraichir,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ============================================================
            // APP BAR
            // ============================================================

            SliverAppBar(
          pinned: true,
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Retour',
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          elevation: 0,
          backgroundColor: AppColors.primary,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 70,

          titleSpacing: 20,

          title: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(.12),
                  ),
                ),
                child: const Icon(
                  Icons.directions_bus_filled_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),

      const SizedBox(width: 12),

      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOTRACO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Bus disponibles',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ],
  ),

  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 14),
      child: _GlassButton(
        icon: Icons.refresh_rounded,
        onTap: _rafraichir,
      ),
    ),
  ],
),

            // ============================================================
            // HEADER ANIMÉ
            // ============================================================

            SliverToBoxAdapter(
              child: _AnimatedEntry(
                controller: _animationController,
                delay: 0.0,
                child: _HeaderCard(
                  nom: nom,
                  busEnMarche: busEnMarche,
                  totalBus: busProvider.buses.length,
                  onLogout: () async {
                    await auth.deconnecter();

                    if (!context.mounted) return;

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const SplashScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ),
            ),

            // ============================================================
            // TITRE FILTRES
            // ============================================================

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: _AnimatedEntry(
                  controller: _animationController,
                  delay: .15,
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        'Choisir une ligne',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_ligneSelectionnee != null)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _ligneSelectionnee = null;
                            });

                            context
                                .read<BusProvider>()
                                .chargerBuses();
                          },
                          child: const Text(
                            'Réinitialiser',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ============================================================
            // FILTRES DES LIGNES
            // ============================================================

            SliverToBoxAdapter(
              child: _AnimatedEntry(
                controller: _animationController,
                delay: .25,
                child: SizedBox(
                  height: 52,
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _ChipLigne(
                        label: 'Toutes',
                        icon: Icons.apps_rounded,
                        selectionnee: _ligneSelectionnee == null,
                        onTap: () {
                          setState(() {
                            _ligneSelectionnee = null;
                          });

                          context
                              .read<BusProvider>()
                              .chargerBuses();
                        },
                      ),

                      ...busProvider.lignes.map(
                        (ligne) => Padding(
                          padding: const EdgeInsets.only(left: 9),
                          child: _ChipLigne(
                            label: ligne.nom,
                            icon: Icons.route_rounded,
                            selectionnee:
                                _ligneSelectionnee == ligne.id,
                            onTap: () {
                              setState(() {
                                _ligneSelectionnee = ligne.id;
                              });

                              context
                                  .read<BusProvider>()
                                  .chargerBuses(
                                    ligneId: ligne.id,
                                  );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ============================================================
            // PETIT ESPACE
            // ============================================================

            const SliverToBoxAdapter(
              child: SizedBox(height: 12),
            ),

            // ============================================================
            // TITRE BUS
            // ============================================================

            if (!busProvider.chargement &&
                busProvider.buses.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: _AnimatedEntry(
                    controller: _animationController,
                    delay: .35,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 7),
                        const Text(
                          'Bus disponibles',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${busProvider.buses.length}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ============================================================
            // CHARGEMENT
            // ============================================================

            if (busProvider.chargement)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _LoadingBus(),
              )

            // ============================================================
            // AUCUN BUS
            // ============================================================

            else if (busProvider.buses.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyBusState(),
              )

            // ============================================================
            // LISTE DES BUS
            // ============================================================

            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  30,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final bus = busProvider.buses[index];

                      return _AnimatedEntry(
                        controller: _animationController,
                        delay: .35 + (index * .08),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnimatedBusCard(
                            child: BusCard(
                              bus: bus,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BusMapScreen(
                                      bus: bus,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: busProvider.buses.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ========================================================================
// HEADER CARD
// ========================================================================

class _HeaderCard extends StatefulWidget {
  final String nom;
  final int busEnMarche;
  final int totalBus;
  final VoidCallback onLogout;

  const _HeaderCard({
    required this.nom,
    required this.busEnMarche,
    required this.totalBus,
    required this.onLogout,
  });

  @override
  State<_HeaderCard> createState() => _HeaderCardState();
}

class _HeaderCardState extends State<_HeaderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pourcentage = widget.totalBus == 0
        ? 0
        : (widget.busEnMarche / widget.totalBus).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Stack(
        children: [
          // Décorations
          Positioned(
            top: -45,
            right: -35,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.07),
              ),
            ),
          ),

          Positioned(
            bottom: -55,
            left: -35,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(.05),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BONJOUR 👋',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  GestureDetector(
                    onTap: widget.onLogout,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.13),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Statut direct
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  return Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentLight
                                  .withOpacity(
                                .3 + (_pulse.value * .5),
                              ),
                              blurRadius: 8 + (_pulse.value * 4),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 9),
                      Text(
                        widget.busEnMarche == 0
                            ? 'Aucun bus en circulation'
                            : '${widget.busEnMarche} bus en circulation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 18),

              // Statistiques
              Row(
                children: [
                  Expanded(
                    child: _HeaderStat(
                      icon: Icons.directions_bus_rounded,
                      value: '${widget.totalBus}',
                      label: 'Bus',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeaderStat(
                      icon: Icons.wifi_tethering_rounded,
                      value: '${widget.busEnMarche}',
                      label: 'En direct',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeaderStat(
                      icon: Icons.speed_rounded,
                      value: '${(pourcentage * 100).round()}%',
                      label: 'Actifs',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// STAT HEADER
// ========================================================================

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(.10),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 18,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// CHIP LIGNE
// ========================================================================

class _ChipLigne extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selectionnee;
  final VoidCallback onTap;

  const _ChipLigne({
    required this.label,
    required this.icon,
    required this.selectionnee,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,

      decoration: BoxDecoration(
        gradient: selectionnee
            ? AppColors.heroGradient
            : const LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white,
                ],
              ),
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: selectionnee
              ? Colors.transparent
              : Colors.grey.shade200,
        ),

        boxShadow: selectionnee
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(.20),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(.035),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,

          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),

                  width: 32,
                  height: 32,

                  decoration: BoxDecoration(
                    color: selectionnee
                        ? Colors.white.withOpacity(.16)
                        : AppColors.primary.withOpacity(.07),
                    shape: BoxShape.circle,
                  ),

                  child: Icon(
                    icon,
                    size: 16,
                    color: selectionnee
                        ? Colors.white
                        : AppColors.primary,
                  ),
                ),

                const SizedBox(width: 9),

                Text(
                  label,
                  style: TextStyle(
                    color: selectionnee
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),

                if (selectionnee) ...[
                  const SizedBox(width: 7),

                  const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========================================================================
// BOUTON VERRE
// ========================================================================

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(.13),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

// ========================================================================
// ANIMATION ENTRÉE
// ========================================================================

class _AnimatedEntry extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const _AnimatedEntry({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        delay.clamp(0.0, .75),
        (delay + .25).clamp(.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(
              0,
              25 * (1 - animation.value),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

// ========================================================================
// ANIMATION BUS CARD
// ========================================================================

class _AnimatedBusCard extends StatefulWidget {
  final Widget child;

  const _AnimatedBusCard({
    required this.child,
  });

  @override
  State<_AnimatedBusCard> createState() =>
      _AnimatedBusCardState();
}

class _AnimatedBusCardState
    extends State<_AnimatedBusCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? .985 : 1,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _pressed = true);
        },
        onTapUp: (_) {
          setState(() => _pressed = false);
        },
        onTapCancel: () {
          setState(() => _pressed = false);
        },
        child: widget.child,
      ),
    );
  }
}

// ========================================================================
// CHARGEMENT
// ========================================================================

class _LoadingBus extends StatelessWidget {
  const _LoadingBus();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(17),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Recherche des bus...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================================
// AUCUN BUS
// ========================================================================

class _EmptyBusState extends StatelessWidget {
  const _EmptyBusState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withOpacity(.10),
                    AppColors.accent.withOpacity(.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bus_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun bus disponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Aucun bus ne correspond à cette ligne pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}