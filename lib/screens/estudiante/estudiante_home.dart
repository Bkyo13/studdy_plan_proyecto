import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'completadas_screen.dart';
import 'inicio_screen.dart';
import 'nueva_tarea_screen.dart';

class EstudianteHome extends StatefulWidget {
  const EstudianteHome({super.key});

  @override
  State<EstudianteHome> createState() => _EstudianteHomeState();
}

class _EstudianteHomeState extends State<EstudianteHome> {
  int _indice = 0;

  void _abrirNuevaTarea() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NuevaTareaScreen()),
    );
  }

  Widget _barraInferior() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppColors.verde,
        unselectedItemColor: AppColors.textoSuave,
        currentIndex: _indice,
        onTap: (i) => setState(() => _indice = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'Completadas',
          ),
        ],
      ),
    );
  }

  Widget? _botonFlotante() {
    if (_indice != 0) return null;
    return FloatingActionButton(
      onPressed: _abrirNuevaTarea,
      backgroundColor: AppColors.verde,
      foregroundColor: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: IndexedStack(
        index: _indice,
        children: const [
          InicioScreen(),
          CompletadasScreen(),
        ],
      ),
      floatingActionButton: _botonFlotante(),
      bottomNavigationBar: _barraInferior(),
    );
  }
}