import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/tarjeta_tarea.dart';
import 'detalle_tarea_screen.dart';
import 'todas_tareas_screen.dart';

/// Dashboard del estudiante (pestaña Inicio). Se muestra dentro de EstudianteHome.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  Widget _encabezado(Usuario usuario) {
    final primerNombre = usuario.nombre.trim().split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('StudyPlan', style: AppText.tituloPantalla),
              const SizedBox(height: 4),
              Text(
                '¡Hola, $primerNombre! Organiza tu día.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.cuerpo,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        AvatarUsuario(nombre: usuario.nombre),
      ],
    );
  }

  Widget _tituloLista(BuildContext context, int total) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Tareas pendientes ($total)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.tituloSeccion,
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TodasTareasScreen()),
          ),
          child: const Text(
            'Ver todas',
            style: TextStyle(
              color: AppColors.verde,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _listaTareas(BuildContext context, List<Tarea> tareas) {
    if (tareas.isEmpty) {
      return const EstadoVacio(
        icono: Icons.inbox_outlined,
        titulo: 'No hay tareas pendientes',
        texto: 'Toca el botón + para agregar una nueva tarea.',
      );
    }
    return Column(
      children: tareas
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.entreTarjetas),
              child: TarjetaTarea(
                tarea: t,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetalleTareaScreen(tareaId: t.id),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    if (usuario == null) return const SizedBox.shrink();
    final tareas = context
        .watch<TareaProvider>()
        .porEstudiante(usuario.id, Estado.pendiente);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pantalla,
          AppSpacing.pantalla,
          AppSpacing.pantalla,
          96,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _encabezado(usuario),
            const SizedBox(height: AppSpacing.entreSecciones),
            _tituloLista(context, tareas.length),
            const SizedBox(height: AppSpacing.entreTarjetas),
            _listaTareas(context, tareas),
          ],
        ),
      ),
    );
  }
}