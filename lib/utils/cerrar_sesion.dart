import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/tarea_provider.dart';
import '../providers/vinculo_provider.dart';
import '../services/notificaciones_service.dart';
import '../theme/app_theme.dart';

/// Pregunta antes de cerrar la sesión y, si el usuario confirma, la cierra.
/// Devuelve true si se cerró. Lo usan el panel del admin, el del tutor y el
/// perfil del estudiante, para que los tres se comporten igual.
Future<bool> confirmarCerrarSesion(BuildContext context) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cerrar sesión'),
      content: const Text('¿Seguro que quieres cerrar tu sesión?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text(
            'Cerrar sesión',
            style: TextStyle(
              color: AppColors.peligro,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  if (confirmado != true || !context.mounted) return false;
  // Si la pantalla está encima de otras (como el perfil), se regresa a la
  // raíz para que AuthGate muestre el login.
  final auth = context.read<AuthProvider>();
  final tareas = context.read<TareaProvider>();
  final vinculos = context.read<VinculoProvider>();
  Navigator.of(context).popUntil((ruta) => ruta.isFirst);
  tareas.detener();
  vinculos.detener();
  // Los recordatorios son de esta cuenta: no deben llegarle a quien entre después.
  NotificacionesService.instancia.cancelarTodas();
  auth.cerrarSesion();
  return true;
}
