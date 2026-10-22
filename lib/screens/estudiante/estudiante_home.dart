import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class EstudianteHome extends StatelessWidget {
  const EstudianteHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.pantalla),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dashboard del estudiante\n(pendiente de integrar)',
                  textAlign: TextAlign.center,
                  style: AppText.tituloSeccion,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.read<AuthProvider>().cerrarSesion(),
                  style: AppDecor.botonPrimario(),
                  child: const Text('Cerrar sesión', style: AppText.boton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
