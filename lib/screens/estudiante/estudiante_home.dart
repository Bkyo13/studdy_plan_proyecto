import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'completadas_screen.dart';
import 'inicio_screen.dart';
import 'logros_screen.dart';
import 'nueva_tarea_screen.dart';

/// Dashboard del Estudiante: barra inferior con Inicio, Completadas y Logros.
class EstudianteHome extends StatefulWidget {
  const EstudianteHome({super.key});

  @override
  State<EstudianteHome> createState() => _EstudianteHomeState();
}

class _EstudianteHomeState extends State<EstudianteHome> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          const InicioScreen(),
          const CompletadasScreen(),
          // Se crea cada vez que se abre la pestaña, para revisar logros nuevos.
          if (_indice == 2) const LogrosScreen() else const SizedBox.shrink(),
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
              icon: Icon(Icons.check_circle_outline),
              label: 'Completadas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Logros',
            ),
          ],
        ),
      ),
    );
  }
}
