import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tarea.dart';
import '../providers/materia_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formato_fecha.dart';
import 'etiqueta_prioridad.dart';

class TarjetaTarea extends StatelessWidget {
  const TarjetaTarea({super.key, required this.tarea, this.onTap});

  final Tarea tarea;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final materia = context.watch<MateriaProvider>().porId(tarea.materiaId);
    final nombreMateria = (materia?.nombre ?? 'Sin materia').toUpperCase();

    return Container(
      decoration: AppDecor.tarjeta(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tarjeta),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nombreMateria,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.etiquetaMateria,
                      ),
                    ),
                    const SizedBox(width: 12),
                    EtiquetaPrioridad(prioridad: tarea.prioridad),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tarea.nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tituloTarjeta,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppColors.textoSuave,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Entrega: ${FormatoFecha.entrega(tarea.fechaEntrega)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.cuerpo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}