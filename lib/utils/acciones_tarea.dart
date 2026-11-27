import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/tarea.dart';
import '../providers/logro_provider.dart';
import '../providers/tarea_provider.dart';
import '../widgets/dialogo_logro.dart';
import 'mensajes.dart';

/// Completa una tarea con todo lo que eso implica, igual desde el detalle
/// que al deslizar la tarjeta: guarda el XP, revisa logros nuevos (y muestra
/// su aviso) y deja el mensaje "+N XP" con el botón "Deshacer".
Future<void> completarTarea(BuildContext context, Tarea tarea) async {
  final tareas = context.read<TareaProvider>();
  final logros = context.read<LogroProvider>();

  HapticFeedback.lightImpact();
  final puntos = tareas.completar(tarea.id);
  final nuevos = logros.evaluar(
    tarea.estudianteId,
    tareas.xpDe(tarea.estudianteId),
  );
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
}
