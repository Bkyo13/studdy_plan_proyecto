import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/vinculo_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/cerrar_sesion.dart';
import '../../utils/mensajes.dart';
import '../../widgets/boton_circular.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/tarjeta_dato.dart';
import 'tareas_estudiante_screen.dart';
import 'vincular_estudiante_screen.dart';

/// Dashboard del Tutor: resumen del estudiante vinculado (solo lectura).
class TutorHome extends StatelessWidget {
  const TutorHome({super.key});

  Future<void> _confirmarDesvincular(
    BuildContext context,
    Usuario estudiante,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular estudiante'),
        content: Text(
          'Dejarás de ver las tareas y el avance de ${estudiante.nombre}. '
          'Podrás volver a vincularlo cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Desvincular',
              style: TextStyle(color: AppColors.peligro, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true || !context.mounted) return;
    final tutor = context.read<AuthProvider>().usuarioActual;
    if (tutor == null) return;
    context.read<VinculoProvider>().desvincular(tutor.id);
    mostrarMensaje(context, 'Estudiante desvinculado');
  }

  void _irAVincular(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VincularEstudianteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tutor = auth.usuarioActual;
    final vinculos = context.watch<VinculoProvider>();
    final estudianteId = tutor == null ? null : vinculos.estudianteIdDe(tutor.id);
    final estudiante = estudianteId == null ? null : auth.porId(estudianteId);
    // Mientras llegan el vínculo o el perfil del estudiante desde Firestore.
    final cargando =
        vinculos.cargando || (estudianteId != null && estudiante == null);

    // Escucha el vínculo del tutor y las tareas del estudiante vinculado.
    // (Se hace después de dibujar; las dos llamadas no hacen nada si ya
    // estaban escuchando lo mismo.)
    if (tutor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.read<VinculoProvider>().escuchar(tutor.id);
        final tareas = context.read<TareaProvider>();
        if (estudianteId != null) {
          tareas.escuchar(estudianteId);
        } else if (!vinculos.cargando) {
          tareas.detener();
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Panel del tutor',
                      style: AppText.tituloPantalla,
                    ),
                  ),
                  const SizedBox(width: 12),
                  BotonCircular(
                    icono: Icons.logout,
                    onPressed: () => confirmarCerrarSesion(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '¡Hola, ${tutor?.nombre ?? ''}! Da seguimiento al avance de tu estudiante.',
                style: AppText.cuerpo,
              ),
              const SizedBox(height: AppSpacing.entreSecciones),
              if (cargando)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.verde),
                  ),
                )
              else if (estudiante == null) ...[
                const EstadoVacio(
                  icono: Icons.person_add_alt_1_outlined,
                  titulo: 'Aún no tienes un estudiante vinculado',
                  mensaje:
                      'Vincula a un estudiante con su correo para ver sus tareas y su avance.',
                ),
                const SizedBox(height: AppSpacing.entreSecciones),
                ElevatedButton(
                  onPressed: () => _irAVincular(context),
                  style: AppDecor.botonPrimario(),
                  child: const Text('Vincular estudiante', style: AppText.boton),
                ),
              ] else
                ..._resumen(context, estudiante),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _resumen(BuildContext context, Usuario estudiante) {
    final tareas = context.watch<TareaProvider>();
    final pendientes = tareas.contarPorEstado(estudiante.id, Estado.pendiente);
    final atrasadas = tareas.contarVencidas(estudiante.id);
    final completadas = tareas.contarPorEstado(estudiante.id, Estado.completada);
    final xp = tareas.xpDe(estudiante.id);
    final inicial =
        estudiante.nombre.isNotEmpty ? estudiante.nombre[0].toUpperCase() : '?';

    return [
      Container(
        padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
        decoration: AppDecor.tarjeta(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.verdeClaro,
              child: Text(
                inicial,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.verde,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estudiante.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.tituloTarjeta,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    estudiante.correo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.pequeno,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.entreTarjetas),
      Row(
        children: [
          Expanded(
            child: TarjetaDato(
              icono: Icons.pending_actions_outlined,
              valor: '$pendientes',
              etiqueta: 'Pendientes',
            ),
          ),
          const SizedBox(width: AppSpacing.entreTarjetas),
          Expanded(
            child: TarjetaDato(
              icono: Icons.error_outline,
              valor: '$atrasadas',
              etiqueta: 'Atrasadas',
              alerta: atrasadas > 0,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.entreTarjetas),
      Row(
        children: [
          Expanded(
            child: TarjetaDato(
              icono: Icons.check_circle_outline,
              valor: '$completadas',
              etiqueta: 'Completadas',
            ),
          ),
          const SizedBox(width: AppSpacing.entreTarjetas),
          Expanded(
            child: TarjetaDato(
              icono: Icons.military_tech_outlined,
              valor: '$xp',
              etiqueta: 'XP acumulado',
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.entreSecciones),
      ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TareasEstudianteScreen(estudianteId: estudiante.id),
          ),
        ),
        style: AppDecor.botonPrimario(),
        icon: const Icon(Icons.list_alt_outlined),
        label: const Text('Ver tareas', style: AppText.boton),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => _irAVincular(context),
        style: AppDecor.botonSecundario(),
        child: const Text(
          'Cambiar estudiante',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: () => _confirmarDesvincular(context, estudiante),
        child: const Text(
          'Desvincular estudiante',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.peligro,
          ),
        ),
      ),
    ];
  }
}
