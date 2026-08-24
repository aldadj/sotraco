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

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: (enDirect ? AppColors.busEnDirect : AppColors.busArrete).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.directions_bus_filled_rounded,
                  color: enDirect ? AppColors.busEnDirect : AppColors.busArrete,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bus.numero, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(
                      bus.ligneNom ?? 'Ligne non assignée',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (bus.chauffeurNom != null) ...[
                      const SizedBox(height: 2),
                      Text('Chauffeur : ${bus.chauffeurNom}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (enDirect ? AppColors.busEnDirect : AppColors.busArrete).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: enDirect ? AppColors.busEnDirect : AppColors.busArrete,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          enDirect ? 'En direct' : 'Arrêté',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: enDirect ? AppColors.busEnDirect : AppColors.busArrete,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
