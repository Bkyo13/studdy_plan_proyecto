import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../providers/auth_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/boton_circular.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/tarjeta_tarea.dart';

/// Lista de tareas del estudiante vinculado. Solo lectura, con filtro.
class TareasEstudianteScreen extends StatefulWidget {
  final int estudianteId;

  const TareasEstudianteScreen({super.key, required this.estudianteId});

  @override
  State<TareasEstudianteScreen> createState() => _TareasEstudianteScreenState();
}

class _TareasEstudianteScreenState extends State<TareasEstudianteScreen> {
  Estado _filtro = Estado.pendiente;

  @override
  Widget build(BuildContext context) {
    final estudiante = context.watch<AuthProvider>().porId(widget.estudianteId);
    final materias = context.watch<MateriaProvider>();
    final tareas = context
        .watch<TareaProvider>()
        .tareasDe(widget.estudianteId, estado: _filtro);
    final pendientes = _filtro == Estado.pendiente;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pantalla,
            AppSpacing.pantalla,
            AppSpacing.pantalla,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BotonCircular(
                    icono: Icons.arrow_back_ios_new,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16),
                  const Text('Tareas', style: AppText.tituloPantalla),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Solo lectura · ${estudiante?.nombre ?? 'Estudiante'}',
                style: AppText.cuerpo,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _chipFiltro('Pendientes', Estado.pendiente)),
                  const SizedBox(width: 12),
                  Expanded(child: _chipFiltro('Completadas', Estado.completada)),
                ],
              ),
              const SizedBox(height: AppSpacing.entreSecciones),
              Expanded(
                child: tareas.isEmpty
                    ? Align(
                        alignment: Alignment.topCenter,
                        child: EstadoVacio(
                          titulo: pendientes
                              ? 'No hay tareas pendientes'
                              : 'Aún no ha completado tareas',
                          mensaje: pendientes
                              ? 'Tu estudiante está al día.'
                              : 'Cuando termine una, aparecerá aquí.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: AppSpacing.pantalla),
                        itemCount: tareas.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.entreTarjetas),
                        itemBuilder: (context, i) {
                          final tarea = tareas[i];
                          return TarjetaTarea(
                            tarea: tarea,
                            materia: materias.porId(tarea.materiaId),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipFiltro(String texto, Estado estado) {
    final seleccionado = _filtro == estado;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => setState(() => _filtro = estado),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.verde : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: seleccionado ? AppColors.verde : AppColors.borde,
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 15,
            fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
            color: seleccionado ? Colors.white : AppColors.textoSuave,
          ),
        ),
      ),
    );
  }
}
