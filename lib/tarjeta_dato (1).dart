import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta que se muestra cuando una lista no tiene elementos.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String mensaje;

  const EstadoVacio({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.icono = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppDecor.tarjeta(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.verdeClaro,
            child: Icon(icono, color: AppColors.verde),
          ),
          const SizedBox(height: 16),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: AppText.tituloTarjeta,
          ),
          const SizedBox(height: 8),
          Text(mensaje, textAlign: TextAlign.center, style: AppText.cuerpo),
        ],
      ),
    );
  }
}
