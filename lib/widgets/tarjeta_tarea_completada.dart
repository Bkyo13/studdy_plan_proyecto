import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tarea.dart';
import '../providers/materia_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formato_fecha.dart';

class TarjetaTareaCompletada extends StatelessWidget {
  const TarjetaTareaCompletada({super.key, required this.tarea});

  final Tarea tarea;

  @override
  Widget build(BuildContext context) {
    final materia = context.watch<MateriaProvider>().porId(tarea.materiaId);
    final nombreMateria = (materia?.nombre ?? 'Sin materia').toUpperCase();
    final fecha = tarea.fechaCompletada ?? tarea.fechaEntrega;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
      decoration: AppDecor.tarjeta(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_outline,
              color: AppColors.textoTenue,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreMateria,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.textoTenue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tarea.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tituloTarjeta.copyWith(
                    color: AppColors.textoTenue,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completado: ${FormatoFecha.completado(fecha)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cuerpo.copyWith(color: AppColors.textoTenue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}