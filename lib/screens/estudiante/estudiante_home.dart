import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../services/notificaciones_service.dart';
import '../../theme/app_theme.dart';
import 'asistente_screen.dart';
import 'calendario_screen.dart';
import 'completadas_screen.dart';
import 'inicio_screen.dart';
import 'logros_screen.dart';
import 'nueva_tarea_screen.dart';

/// Dashboard del Estudiante: barra inferior con Inicio, Calendario,
/// Completadas y Logros.
class EstudianteHome extends StatefulWidget {
  const EstudianteHome({super.key});

  @override
  State<EstudianteHome> createState() => _EstudianteHomeState();
}

class _EstudianteHomeState extends State<EstudianteHome> {
  int _indice = 0;

  @override
  void initState() {
    super.initState();
    // Al entrar como estudiante: pedir permiso de notificaciones (solo la
    // primera vez sale el aviso del sistema) y programar los recordatorios
    // de sus tareas pendientes.
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepararAvisos());
  }

  Future<void> _prepararAvisos() async {
    final usuario = context.read<AuthProvider>().usuarioActual;
    if (usuario == null) return;
    // Escucha sus tareas en Firestore; con programarAvisos, cada cambio deja
    // al día los recordatorios del teléfono.
    context
        .read<TareaProvider>()
        .escuchar(usuario.id, programarAvisos: true);
    await NotificacionesService.instancia.pedirPermiso();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          const InicioScreen(),
          const CalendarioScreen(),
          const CompletadasScreen(),
          // Se crea cada vez que se abre la pestaña, para revisar logros nuevos.
          if (_indice == 3) const LogrosScreen() else const SizedBox.shrink(),
          const AsistenteScreen(),
        ],
      ),
      floatingActionButton: _indice == 0
          ? FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NuevaTareaScreen()),
              ),
              backgroundColor: AppColors.verde,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borde)),
        ),
        child: BottomNavigationBar(
          currentIndex: _indice,
          onTap: (i) => setState(() => _indice = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: AppColors.verde,
          unselectedItemColor: AppColors.textoSuave,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              label: 'Calendario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              label: 'Completadas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Logros',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              label: 'Asistente',
            ),
          ],
        ),
      ),
    );
  }
}
