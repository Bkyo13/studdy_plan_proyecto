import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/usuario.dart';
import '../../providers/auth_provider.dart';
import '../../providers/logro_provider.dart';
import '../../providers/materia_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/boton_circular.dart';
import 'logros_admin_screen.dart';
import 'materia_form_screen.dart';
import 'materias_screen.dart';

/// Dashboard del Administrador: resumen de usuarios, materias y logros.
class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final totalMaterias = context.watch<MateriaProvider>().materias.length;
    final totalLogros = context.watch<LogroProvider>().logros.length;
    final usuarios = auth.usuarios;
    final nombre = auth.usuarioActual?.nombre ?? '';

    int contar(Rol rol) => usuarios.where((u) => u.rol == rol).length;

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
                      'Panel de administración',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.texto,
                      ),
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
                '¡Hola, $nombre! Gestiona las materias y los logros de StudyPlan.',
                style: AppText.cuerpo,
              ),
              const SizedBox(height: AppSpacing.entreSecciones),
              Row(
                children: [
                  Expanded(
                    child: _tarjetaDato(
                      icono: Icons.people_outline,
                      valor: usuarios.length,
                      etiqueta: 'Usuarios',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.entreTarjetas),
                  Expanded(
                    child: _tarjetaDato(
                      icono: Icons.menu_book_outlined,
                      valor: totalMaterias,
                      etiqueta: 'Materias',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.entreTarjetas),
              _tarjetaDato(
                icono: Icons.emoji_events_outlined,
                valor: totalLogros,
                etiqueta: 'Logros en el catálogo',
              ),
              const SizedBox(height: 12),
              Text(
                'Estudiantes: ${contar(Rol.estudiante)} · '
                'Tutores: ${contar(Rol.tutor)} · '
                'Administradores: ${contar(Rol.administrador)}',
                textAlign: TextAlign.center,
                style: AppText.pequeno,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MateriasScreen()),
                ),
                style: AppDecor.botonPrimario(),
                icon: const Icon(Icons.list_alt_outlined),
                label: const Text('Ver materias', style: AppText.boton),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MateriaFormScreen()),
                ),
                style: AppDecor.botonSecundario(),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Nueva materia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LogrosAdminScreen()),
                ),
                style: AppDecor.botonSecundario(),
                icon: const Icon(Icons.emoji_events_outlined),
                label: const Text(
                  'Administrar logros',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaDato({
    required IconData icono,
    required int valor,
    required String etiqueta,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
      decoration: AppDecor.tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.verdeClaro,
              shape: BoxShape.circle,
            ),
            child: Icon(icono, color: AppColors.verde),
          ),
          const SizedBox(height: 16),
          Text(
            '$valor',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.texto,
            ),
          ),
          Text(etiqueta, style: AppText.cuerpo),
        ],
      ),
    );
  }
}
