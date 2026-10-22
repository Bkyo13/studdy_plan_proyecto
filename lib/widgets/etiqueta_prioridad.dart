import 'package:flutter/material.dart';

import '../models/tarea.dart';
import '../theme/app_theme.dart';

class EtiquetaPrioridad extends StatelessWidget {
  const EtiquetaPrioridad({super.key, required this.prioridad});

  final Prioridad prioridad;

  String get _texto {
    switch (prioridad) {
      case Prioridad.alta:
        return 'ALTA';
      case Prioridad.media:
        return 'MEDIA';
      case Prioridad.baja:
        return 'BAJA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.paraPrioridad(prioridad),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _texto,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}