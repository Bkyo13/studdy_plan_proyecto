import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/vinculo_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/boton_circular.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/tarjeta_dato.dart';
import 'tareas_estudiante_screen.dart';
import 'vincular_estudiante_screen.dart';

/// Dashboard del Tutor: resumen del estudiante vinculado (solo lectura).
class TutorHome extends StatelessWidget {
  const TutorHome({super.key});

  void _irAVincular(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VincularEstudianteScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tutor = auth.usuarioActual;
    final estudianteId =
        tutor == null ? null : context.watch<VinculoProvider>().estudianteIdDe(tutor.id);
    final estudiante = estudianteId == null ? null : auth.porId(estudianteId);

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
                    onPressed: () => context.read<AuthProvider>().cerrarSesion(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '¡Hola, ${tutor?.nombre ?? ''}! Da seguimiento al avance de tu estudiante.',
                style: AppText.cuerpo,
              ),
              const SizedBox(height: AppSpacing.entreSecciones),
              if (estudiante == null) ...[
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
              icono: Icons.check_circle_outline,
              valor: '$completadas',
              etiqueta: 'Completadas',
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.entreTarjetas),
      TarjetaDato(
        icono: Icons.military_tech_outlined,
        valor: '$xp',
        etiqueta: 'XP acumulado',
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
    ];
  }
}
