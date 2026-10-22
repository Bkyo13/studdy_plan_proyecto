import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/color_hex.dart';
import '../../utils/formato_fecha.dart';
import '../../utils/mensajes.dart';
import '../../widgets/encabezado_interno.dart';
import '../../widgets/etiqueta_prioridad.dart';
import 'nueva_tarea_screen.dart';

class DetalleTareaScreen extends StatelessWidget {
  const DetalleTareaScreen({super.key, required this.tareaId});

  final int tareaId;

  Widget _filaMateria(BuildContext context, Tarea tarea) {
    final materia = context.watch<MateriaProvider>().porId(tarea.materiaId);
    final color = materia == null ? AppColors.verde : colorDeHex(materia.color);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            (materia?.nombre ?? 'Sin materia').toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.etiquetaMateria,
          ),
        ),
        const SizedBox(width: 12),
        EtiquetaPrioridad(prioridad: tarea.prioridad),
      ],
    );
  }

  Widget _etiquetaSeccion(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textoTenue,
      ),
    );
  }

  Widget _contenido(BuildContext context, Tarea tarea) {
    final descripcion = tarea.descripcion.trim();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filaMateria(context, tarea),
          const SizedBox(height: 16),
          Text(
            tarea.nombre,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.texto,
            ),
          ),
          const SizedBox(height: AppSpacing.entreSecciones),
          _etiquetaSeccion('INSTRUCCIONES'),
          const SizedBox(height: 8),
          const Divider(color: AppColors.borde, height: 1),
          const SizedBox(height: 12),
          Text(
            descripcion.isEmpty ? 'Sin descripción.' : descripcion,
            style: AppText.cuerpo,
          ),
          const SizedBox(height: AppSpacing.entreSecciones),
          _etiquetaSeccion('FECHA DE ENTREGA'),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: AppColors.verde,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  FormatoFecha.entrega(tarea.fechaEntrega),
                  style: AppText.tituloTarjeta,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.entreSecciones),
        ],
      ),
    );
  }

  Future<void> _eliminar(BuildContext context, Tarea tarea) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar tarea?'),
        content: Text('Se eliminará "${tarea.nombre}". Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.peligro),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true || !context.mounted) return;
    mostrarConfirmacion(context, 'Tarea eliminada');
    context.read<TareaProvider>().eliminar(tarea.id);
    Navigator.of(context).pop();
  }

  void _completar(BuildContext context, Tarea tarea) {
    mostrarConfirmacion(context, 'Tarea completada. ¡Ganaste ${TareaProvider.xpPorTarea} XP!');
    context.read<TareaProvider>().completar(tarea.id);
    Navigator.of(context).pop();
  }

  Widget _botones(BuildContext context, Tarea tarea) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pantalla,
        8,
        AppSpacing.pantalla,
        24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => _completar(context, tarea),
            style: AppDecor.botonPrimario(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Marcar como completada',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.boton,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _eliminar(context, tarea),
            style: AppDecor.botonSecundario(color: AppColors.peligro),
            child: const Text('Eliminar tarea'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tarea = context.watch<TareaProvider>().porId(tareaId);
    // La tarea puede desaparecer un instante mientras se cierra la pantalla.
    if (tarea == null) {
      return const Scaffold(backgroundColor: AppColors.fondo);
    }

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: SafeArea(
        child: Column(
          children: [
            EncabezadoInterno(
              titulo: 'Detalle',
              centrado: true,
              accion: BotonCircular(
                icono: Icons.edit_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NuevaTareaScreen(tarea: tarea),
                  ),
                ),
              ),
            ),
            Expanded(child: _contenido(context, tarea)),
            _botones(context, tarea),
          ],
        ),
      ),
    );
  }
}