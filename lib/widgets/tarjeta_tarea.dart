import 'package:flutter/material.dart';

import '../models/materia.dart';
import '../models/tarea.dart';
import '../theme/app_theme.dart';
import '../utils/formato_fecha.dart';
import 'etiqueta_prioridad.dart';

/// Tarjeta de una tarea. Pendiente: materia, prioridad, nombre y fecha de
/// entrega. Completada: check gris, nombre tachado y fecha de completado.
class TarjetaTarea extends StatelessWidget {
  final Tarea tarea;
  final Materia? materia;
  final VoidCallback? onTap;

  const TarjetaTarea({
    super.key,
    required this.tarea,
    required this.materia,
    this.onTap,
  });

  bool get _completada => tarea.estado == Estado.completada;

  @override
  Widget build(BuildContext context) {
    final nombreMateria = (materia?.nombre ?? 'Sin materia').toUpperCase();

    return Container(
      decoration: AppDecor.tarjeta(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tarjeta),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
            child: _completada ? _contenidoCompletada(nombreMateria) : _contenidoPendiente(nombreMateria),
          ),
        ),
      ),
    );
  }

  Widget _contenidoPendiente(String nombreMateria) {
    return Column(
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
        Text(tarea.nombre, style: AppText.tituloTarjeta),
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
                'Entrega: ${formatoEntrega(tarea.fechaEntrega)}',
                style: AppText.cuerpo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _contenidoCompletada(String nombreMateria) {
    final fecha = tarea.fechaCompletada;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline, size: 28, color: AppColors.textoTenue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tarea.nombre,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textoTenue,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    nombreMateria,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textoTenue,
                    ),
                  ),
                  if (fecha != null)
                    Text(
                      'Completado: ${formatoCompletado(fecha)}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textoTenue),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
