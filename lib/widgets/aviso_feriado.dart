import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Recuadro informativo: "Este día es feriado: Día de la Independencia".
class AvisoFeriado extends StatelessWidget {
  final String nombreFeriado;

  /// Texto antes del nombre (por ejemplo, "Tu fecha de entrega cae en").
  final String introduccion;

  const AvisoFeriado({
    super.key,
    required this.nombreFeriado,
    this.introduccion = 'Día feriado:',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F1E6),
        borderRadius: BorderRadius.circular(AppRadius.campo),
        border: Border.all(color: AppColors.prioridadMedia),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration_outlined, color: Color(0xFFB08A4E)),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.texto),
                children: [
                  TextSpan(text: '$introduccion '),
                  TextSpan(
                    text: nombreFeriado,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
