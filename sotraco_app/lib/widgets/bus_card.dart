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
    final statusColor = enDirect ? AppColors.busEnDirect : AppColors.busArrete;

    return Material(
      color: enDirect ? const Color(0xFFF4FBF7) : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: enDirect ? AppColors.heroGradient : null,
                      color: enDirect ? null : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.directions_bus_filled_rounded,
                      color: enDirect ? Colors.white : statusColor,
                    ),
                  ),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                bus.numero,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 3),
              Text(
                bus.ligneNom ?? 'Ligne non assignee',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              Row(
                children: [
                  if (bus.sens != null)
                    Text(
                      bus.sens == 'aller' ? 'Aller' : 'Retour',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    enDirect ? 'EN DIRECT' : 'A L’ARRET',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
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
