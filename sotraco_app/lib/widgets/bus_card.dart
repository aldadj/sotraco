import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../theme/app_theme.dart';

class BusCard extends StatelessWidget {
  final Bus bus;
  final VoidCallback onTap;

  const BusCard({super.key, required this.bus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enDirect = bus.enDirect;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: enDirect ? AppColors.heroGradient : null,
                    color: enDirect ? null : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.directions_bus_filled_rounded,
                    color: enDirect ? Colors.white : AppColors.busArrete,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(bus.numero, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                          ),
                          if (bus.sens != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(bus.sens == 'aller' ? Icons.north_east_rounded : Icons.south_west_rounded, size: 11, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Text(bus.sens == 'aller' ? 'Aller' : 'Retour', style: const TextStyle(color: AppColors.primary, fontSize: 10.5, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bus.ligneNom ?? 'Ligne non assignée',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (bus.chauffeurNom != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.person_rounded, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(child: Text(bus.chauffeurNom!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: (enDirect ? AppColors.busEnDirect : AppColors.busArrete).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 7, height: 7, decoration: BoxDecoration(color: enDirect ? AppColors.busEnDirect : AppColors.busArrete, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(
                            enDirect ? 'En direct' : 'Arrêté',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: enDirect ? AppColors.busEnDirect : AppColors.busArrete),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
