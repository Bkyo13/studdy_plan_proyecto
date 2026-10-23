import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta con un ícono, un valor grande y su etiqueta (resúmenes del tutor).
class TarjetaDato extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;

  const TarjetaDato({
    super.key,
    required this.icono,
    required this.valor,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
      decoration: AppDecor.tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.verdeClaro,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: AppColors.verde),
          ),
          const SizedBox(height: 16),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.texto,
            ),
          ),
          Text(etiqueta, style: AppText.cuerpo),
        ],
      ),
    );
  }
}
