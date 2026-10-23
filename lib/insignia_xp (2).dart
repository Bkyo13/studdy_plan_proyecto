import 'package:flutter/material.dart';

import '../models/tarea.dart';
import '../theme/app_theme.dart';

/// Pastilla de prioridad: ALTA, MEDIA o BAJA.
class EtiquetaPrioridad extends StatelessWidget {
  final Prioridad prioridad;

  const EtiquetaPrioridad({super.key, required this.prioridad});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.paraPrioridad(prioridad),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        prioridad.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
