import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/animaciones.dart';

/// Pastilla verde con la medalla y los puntos de experiencia. Cuando el XP
/// cambia, el número cuenta hasta el nuevo valor (de 40 a 55, por ejemplo)
/// en lugar de saltar de golpe.
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
          // Sin valor inicial: la primera vez muestra el número directo; en
          // los cambios siguientes anima desde el valor anterior.
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: xp.toDouble()),
            duration: Animaciones.duracion(
              context,
              const Duration(milliseconds: 700),
            ),
            curve: Animaciones.curva,
            builder: (_, valor, _) => Text(
              '${valor.round()} XP',
              style: const TextStyle(
                color: AppColors.verde,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
