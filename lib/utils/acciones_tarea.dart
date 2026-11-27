import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/nivel.dart';
import '../models/tarea.dart';
import '../providers/logro_provider.dart';
import '../providers/tarea_provider.dart';
import '../widgets/dialogo_logro.dart';
import 'mensajes.dart';

/// Completa una tarea con todo lo que eso implica, igual desde el detalle
/// que al deslizar la tarjeta: guarda el XP, revisa logros nuevos (y muestra
/// su aviso) y deja el mensaje "+N XP" (o "¡Subiste a nivel N!") con el
/// botón "Deshacer".
Future<void> completarTarea(BuildContext context, Tarea tarea) async {
  final tareas = context.read<TareaProvider>();
  final logros = context.read<LogroProvider>();

  HapticFeedback.lightImpact();
  final nivelAntes = Nivel.de(tareas.xpDe(tarea.estudianteId));
  final puntos = tareas.completar(tarea.id);
  final xpDespues = tareas.xpDe(tarea.estudianteId);
  final nivelDespues = Nivel.de(xpDespues);
  final subioNivel = nivelDespues.numero > nivelAntes.numero;
  final nuevos = logros.evaluar(tarea.estudianteId, xpDespues);
  if (nuevos.isNotEmpty && context.mounted) {
    await mostrarLogrosDesbloqueados(context, nuevos);
  }
  if (!context.mounted) return;
  // El aviso va al final para que no lo tape el cuadro del logro.
  mostrarMensaje(
    context,
    subioNivel
        ? '+$puntos XP · ¡Subiste a nivel ${nivelDespues.numero}: '
            '${nivelDespues.nombre}!'
        : puntos > 0
            ? '¡Tarea completada! +$puntos XP'
            : '¡Tarea completada! (sin XP: se completó muy rápido)',
    accion: 'Deshacer',
    onAccion: () => tareas.reabrir(tarea.id),
  );
}
