import 'package:flutter/material.dart';

import '../../models/usuario.dart';
import '../../theme/app_theme.dart';
import '../../widgets/encabezado_interno.dart';
import '../../widgets/lista_tareas_filtrada.dart';

/// Tareas del estudiante vinculado, solo lectura, con filtro Pendientes / Completadas.
class TareasEstudianteScreen extends StatelessWidget {
  const TareasEstudianteScreen({super.key, required this.estudiante});

  final Usuario estudiante;

  @override
  Widget build(BuildContext context) {
    final primerNombre = estudiante.nombre.trim().split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: SafeArea(
        child: Column(
          children: [
            EncabezadoInterno(titulo: 'Tareas de $primerNombre'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.pantalla,
                  0,
                  AppSpacing.pantalla,
                  AppSpacing.pantalla,
                ),
                child: ListaTareasFiltrada(
                  estudianteId: estudiante.id,
                  soloLectura: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}