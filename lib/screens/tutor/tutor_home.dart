import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/vinculo_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_usuario.dart';
import '../../widgets/estado_vacio.dart';
import 'tareas_estudiante_screen.dart';
import 'vincular_estudiante_screen.dart';

/// Dashboard del tutor.
class TutorHome extends StatelessWidget {
  const TutorHome({super.key});

  void _abrirVincular(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VincularEstudianteScreen()),
    );
  }

  Widget _encabezado(Usuario tutor) {
    final primerNombre = tutor.nombre.trim().split(' ').first;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Panel del tutor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.tituloPantalla,
              ),
              const SizedBox(height: 4),
              Text(
                '¡Hola, $primerNombre! Sigue el avance escolar.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.cuerpo,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        AvatarUsuario(nombre: tutor.nombre),
      ],
    );
  }

  Widget _sinVinculo(BuildContext context) {
    return EstadoVacio(
      icono: Icons.link_outlined,
      titulo: 'Sin estudiante vinculado',
      texto: 'Vincula a un estudiante para ver sus tareas en modo lectura.',
      accion: ElevatedButton(
        onPressed: () => _abrirVincular(context),
        style: AppDecor.botonPrimario(),
        child: const Text('Vincular estudiante', style: AppText.boton),
      ),
    );
  }

  Widget _dato(String valor, String etiqueta) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.verdeClaro,
          borderRadius: BorderRadius.circular(AppRadius.campo),
        ),
        child: Column(
          children: [
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.verde,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.pequeno,
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumen(BuildContext context, Usuario estudiante) {
    final tareas = context.watch<TareaProvider>();
    final pendientes = tareas.totalPorEstado(estudiante.id, Estado.pendiente);
    final completadas = tareas.totalPorEstado(estudiante.id, Estado.completada);
    final xp = tareas.xpDe(estudiante.id);
    final inicial = estudiante.nombre.trim().isEmpty
        ? '?'
        : estudiante.nombre.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
      decoration: AppDecor.tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.verdeClaro,
                child: Text(
                  inicial,
                  style: const TextStyle(
                    color: AppColors.verde,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ESTUDIANTE VINCULADO', style: AppText.etiquetaMateria),
                    const SizedBox(height: 4),
                    Text(
                      estudiante.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.tituloTarjeta,
                    ),
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
          const SizedBox(height: 20),
          Row(
            children: [
              _dato('$pendientes', 'Pendientes'),
              const SizedBox(width: 12),
              _dato('$completadas', 'Completadas'),
              const SizedBox(width: 12),
              _dato('$xp', 'XP'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _acciones(BuildContext context, Usuario estudiante) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TareasEstudianteScreen(estudiante: estudiante),
            ),
          ),
          style: AppDecor.botonPrimario(),
          child: const Text('Ver tareas', style: AppText.boton),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _abrirVincular(context),
          style: AppDecor.botonSecundario(),
          child: const Text('Cambiar estudiante'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutor = context.watch<AuthProvider>().usuarioActual;
    if (tutor == null) {
      return const Scaffold(backgroundColor: AppColors.fondo);
    }
    final estudiante = context.watch<VinculoProvider>().estudianteDe(tutor.id);

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _encabezado(tutor),
              const SizedBox(height: AppSpacing.entreSecciones),
              if (estudiante == null)
                _sinVinculo(context)
              else ...[
                _resumen(context, estudiante),
                const SizedBox(height: AppSpacing.entreSecciones),
                _acciones(context, estudiante),
              ],
            ],
          ),
        ),
      ),
    );
  }
}