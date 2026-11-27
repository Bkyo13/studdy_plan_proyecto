import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../services/notificaciones_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/animaciones.dart';
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

  static const _destinos = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'Inicio',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month_rounded),
      label: 'Calendario',
    ),
    NavigationDestination(
      icon: Icon(Icons.check_circle_outline),
      selectedIcon: Icon(Icons.check_circle_rounded),
      label: 'Hechas',
    ),
    NavigationDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events_rounded),
      label: 'Logros',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: 'Asistente',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pestanas = [
      const InicioScreen(),
      const CalendarioScreen(),
      const CompletadasScreen(),
      // Se crea cada vez que se abre la pestaña, para revisar logros nuevos.
      if (_indice == 3) const LogrosScreen() else const SizedBox.shrink(),
      const AsistenteScreen(),
    ];
    final duracion = Animaciones.duracion(context, Animaciones.normal);

    return Scaffold(
      // Todas las pestañas siguen vivas (no pierden su scroll ni lo escrito);
      // la visible aparece con un fundido corto y la anterior se desvanece.
      body: Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < pestanas.length; i++)
            IgnorePointer(
              ignoring: i != _indice,
              child: ExcludeSemantics(
                excluding: i != _indice,
                child: TickerMode(
                  enabled: i == _indice,
                  child: AnimatedOpacity(
                    opacity: i == _indice ? 1 : 0,
                    duration: duracion,
                    curve: Animaciones.curva,
                    child: pestanas[i],
                  ),
                ),
              ),
            ),
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
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.borde)),
        ),
        child: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: (i) {
            if (i == _indice) return;
            HapticFeedback.selectionClick();
            setState(() => _indice = i);
          },
          animationDuration: duracion,
          height: 68,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppColors.verdeClaro,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _destinos,
        ),
      ),
    );
  }
}
