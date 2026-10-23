import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../providers/auth_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_xp.dart';
import '../../widgets/tarjeta_tarea.dart';

/// Pestaña Completadas: historial, XP y banner de progreso (lista secundaria).
class CompletadasScreen extends StatelessWidget {
  const CompletadasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final materias = context.watch<MateriaProvider>();
    final tareasProvider = context.watch<TareaProvider>();

    final completadas = usuario == null
        ? <Tarea>[]
        : tareasProvider.tareasDe(usuario.id, estado: Estado.completada);
    final xp = usuario == null ? 0 : tareasProvider.xpDe(usuario.id);
    final enLaSemana =
        usuario == null ? 0 : tareasProvider.completadasEnLaSemana(usuario.id);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pantalla),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Completadas', style: AppText.tituloPantalla),
                    SizedBox(height: 4),
                    Text(
                      'Tu historial de logros escolares.',
                      style: AppText.cuerpo,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InsigniaXp(xp: xp),
            ],
          ),
          const SizedBox(height: AppSpacing.entreSecciones),
          if (enLaSemana > 0) ...[
            _bannerProgreso(enLaSemana),
            const SizedBox(height: AppSpacing.entreSecciones),
          ],
          if (completadas.isEmpty)
            const EstadoVacio(
              icono: Icons.check_circle_outline,
              titulo: 'Aún no has completado tareas',
              mensaje: 'Cuando termines una, aparecerá aquí.',
            )
          else
            for (final tarea in completadas) ...[
              TarjetaTarea(
                tarea: tarea,
                materia: materias.porId(tarea.materiaId),
              ),
              const SizedBox(height: AppSpacing.entreTarjetas),
            ],
        ],
      ),
    );
  }

  Widget _bannerProgreso(int cantidad) {
    final texto = cantidad == 1 ? 'tarea clave' : 'tareas clave';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.verdeClaro,
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text('🎉', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¡Gran progreso esta semana!',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.texto,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Has terminado $cantidad $texto para tus materias.',
                  style: AppText.cuerpo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
