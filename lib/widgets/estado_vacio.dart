import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    required this.texto,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppDecor.tarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.verdeClaro,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: AppColors.verde, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: 8),
          Text(texto, textAlign: TextAlign.center, style: AppText.cuerpo),
          if (accion != null) ...[
            const SizedBox(height: 20),
            accion!,
          ],
        ],
      ),
    );
  }
}