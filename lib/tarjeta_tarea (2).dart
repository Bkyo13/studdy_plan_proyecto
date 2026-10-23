import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pastilla verde con la medalla y los puntos de experiencia.
class InsigniaXp extends StatelessWidget {
  final int xp;

  const InsigniaXp({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.verdeClaro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech_outlined, color: AppColors.verde, size: 20),
          const SizedBox(width: 6),
          Text(
            '$xp XP',
            style: const TextStyle(
              color: AppColors.verde,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
