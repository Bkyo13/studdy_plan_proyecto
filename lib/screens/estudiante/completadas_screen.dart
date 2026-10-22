import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../providers/auth_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/tarjeta_tarea_completada.dart';

/// Pestaña Completadas. Se muestra dentro de EstudianteHome.
class CompletadasScreen extends StatelessWidget {
  const CompletadasScreen({super.key});

  Widget _encabezado(int xp) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Completadas',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.tituloPantalla,
              ),
              const SizedBox(height: 4),
              const Text(
                'Tu historial de logros escolares.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.cuerpo,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _insigniaXp(xp),
      ],
    );
  }

  Widget _insigniaXp(int xp) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.verdeClaro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.military_tech_outlined, color: AppColors.verde, size: 20),
          const SizedBox(width: 6),
          Text(
            '$xp XP',
            style: const TextStyle(
              color: AppColors.verde,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerProgreso(int n) {
    final texto = n == 1
        ? 'Has terminado 1 tarea clave para tus materias.'
        : 'Has terminado $n tareas clave para tus materias.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.verdeClaro,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Text('🎉', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Gran progreso esta semana!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(texto, style: AppText.pequeno),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _listaCompletadas(List<Tarea> tareas) {
    if (tareas.isEmpty) {
      return const EstadoVacio(
        icono: Icons.check_circle_outline,
        titulo: 'Aún no has completado tareas',
        texto: 'Cuando completes una tarea aparecerá aquí.',
      );
    }
    return Column(
      children: tareas
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.entreTarjetas),
              child: TarjetaTareaCompletada(tarea: t),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    if (usuario == null) return const SizedBox.shrink();
    final provider = context.watch<TareaProvider>();
    final tareas = provider.porEstudiante(usuario.id, Estado.completada);
    final recientes = provider.completadasUltimos7Dias(usuario.id);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.pantalla),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _encabezado(provider.xpDe(usuario.id)),
            const SizedBox(height: AppSpacing.entreSecciones),
            if (recientes > 0) ...[
              _bannerProgreso(recientes),
              const SizedBox(height: AppSpacing.entreSecciones),
            ],
            _listaCompletadas(tareas),
          ],
        ),
      ),
    );
  }
}