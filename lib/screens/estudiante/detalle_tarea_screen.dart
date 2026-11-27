import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../providers/logro_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/color_hex.dart';
import '../../utils/formato_fecha.dart';
import '../../utils/mensajes.dart';
import '../../widgets/boton_circular.dart';
import '../../widgets/dialogo_logro.dart';
import '../../widgets/etiqueta_prioridad.dart';
import 'asistente_screen.dart';
import 'nueva_tarea_screen.dart';

/// Detalle de una tarea: instrucciones, fecha, y acciones de completar/eliminar.
/// Con [soloLectura] (vista del tutor) se ocultan todas las acciones.
class DetalleTareaScreen extends StatelessWidget {
  final String tareaId;
  final bool soloLectura;

  const DetalleTareaScreen({
    super.key,
    required this.tareaId,
    this.soloLectura = false,
  });

  Future<void> _confirmarEliminar(BuildContext context, Tarea tarea) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text(
          '¿Seguro que quieres eliminar "${tarea.nombre}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.peligro),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;

    final provider = context.read<TareaProvider>();
    mostrarMensaje(context, 'Tarea eliminada');
    Navigator.of(context).pop();
    provider.eliminar(tarea.id);
  }

  Future<void> _completar(BuildContext context, Tarea tarea) async {
    final tareas = context.read<TareaProvider>();
    final logros = context.read<LogroProvider>();

    final puntos = tareas.completar(tarea.id);
    final nuevos = logros.evaluar(
      tarea.estudianteId,
      tareas.xpDe(tarea.estudianteId),
    );
    // Aviso al desbloquear uno o más logros.
    if (nuevos.isNotEmpty && context.mounted) {
      await mostrarLogrosDesbloqueados(context, nuevos);
    }

    if (!context.mounted) return;
    // El aviso va al final para que no lo tape el cuadro del logro.
    mostrarMensaje(
      context,
      puntos > 0
          ? '¡Tarea completada! +$puntos XP'
          : '¡Tarea completada! (sin XP: se completó muy rápido)',
      accion: 'Deshacer',
      onAccion: () => tareas.reabrir(tarea.id),
    );
    Navigator.of(context).pop();
  }

  /// Abre el asistente con una conversación nueva enfocada en esta tarea.
  void _pedirAyuda(BuildContext context, Tarea tarea, String? materia) {
    final deMateria = materia == null ? '' : ' de $materia';
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: AsistenteScreen(
            mostrarRegresar: true,
            preguntaInicial:
                'Ayúdame con mi tarea "${tarea.nombre}"$deMateria. '
                '¿Cómo la divido en pasos y por dónde empiezo?',
          ),
        ),
      ),
    );
  }

  void _reabrir(BuildContext context, Tarea tarea) {
    context.read<TareaProvider>().reabrir(tarea.id);
    mostrarMensaje(context, 'La tarea volvió a tus pendientes');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tarea = context.watch<TareaProvider>().porId(tareaId);
    if (tarea == null) {
      // La tarea ya no existe (por ejemplo, justo después de eliminarla).
      return const Scaffold(body: SizedBox.shrink());
    }
    final materia = context.watch<MateriaProvider>().porId(tarea.materiaId);
    final pendiente = tarea.estado == Estado.pendiente;
    final descripcion = tarea.descripcion.trim().isEmpty
        ? 'Sin descripción.'
        : tarea.descripcion;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BotonCircular(
                    icono: Icons.arrow_back_ios_new,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Detalle de Tarea',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoSuave,
                      ),
                    ),
                  ),
                  if (pendiente && !soloLectura)
                    BotonCircular(
                      icono: Icons.edit_outlined,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NuevaTareaScreen(tarea: tarea),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: AppSpacing.entreSecciones),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
                    decoration: AppDecor.tarjeta(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: colorDesdeHex(materia?.color ?? '#758B75'),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                (materia?.nombre ?? 'Sin materia').toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textoSuave,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            EtiquetaPrioridad(prioridad: tarea.prioridad),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tarea.nombre,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.texto,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.borde),
                        const SizedBox(height: 12),
                        const Text(
                          'INSTRUCCIONES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.textoTenue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          descripcion,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.textoSuave,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.borde),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              tarea.vencida
                                  ? Icons.error_outline
                                  : Icons.calendar_today_outlined,
                              color: tarea.vencida
                                  ? AppColors.peligro
                                  : AppColors.verde,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tarea.vencida
                                      ? 'FECHA DE ENTREGA · VENCIDA'
                                      : 'FECHA DE ENTREGA',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: AppColors.textoTenue,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatoEntrega(tarea.fechaEntrega),
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: tarea.vencida
                                        ? AppColors.peligro
                                        : AppColors.texto,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!soloLectura) ...[
                const SizedBox(height: 16),
                if (pendiente) ...[
                  ElevatedButton.icon(
                    onPressed: () => _completar(context, tarea),
                    style: AppDecor.botonPrimario(),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Marcar como completada', style: AppText.boton),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _pedirAyuda(context, tarea, materia?.nombre),
                    style: AppDecor.botonSecundario(),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text(
                      'Pedir ayuda a la IA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: () => _reabrir(context, tarea),
                    style: AppDecor.botonSecundario(),
                    icon: const Icon(Icons.undo),
                    label: const Text(
                      'Marcar como pendiente',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton(
                  onPressed: () => _confirmarEliminar(context, tarea),
                  style: AppDecor.botonSecundario(color: AppColors.peligro),
                  child: const Text(
                    'Eliminar tarea',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
