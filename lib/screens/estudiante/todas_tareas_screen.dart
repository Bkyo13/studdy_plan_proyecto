import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/encabezado_interno.dart';
import '../../widgets/lista_tareas_filtrada.dart';

/// "Ver todas": todas las tareas del estudiante con filtro Pendientes / Completadas.
class TodasTareasScreen extends StatelessWidget {
  const TodasTareasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;

    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: SafeArea(
        child: Column(
          children: [
            const EncabezadoInterno(titulo: 'Todas mis tareas'),
            Expanded(
              child: usuario == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.pantalla,
                        0,
                        AppSpacing.pantalla,
                        AppSpacing.pantalla,
                      ),
                      child: ListaTareasFiltrada(estudianteId: usuario.id),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}