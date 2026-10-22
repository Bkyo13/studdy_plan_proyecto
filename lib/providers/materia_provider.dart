import 'package:flutter/foundation.dart';

import '../models/materia.dart';

/// Catálogo de materias (en memoria, solo para la demo).
class MateriaProvider extends ChangeNotifier {
  final List<Materia> _materias = [
    const Materia(id: 1, nombre: 'Cálculo de Varias Variables', color: '#758B75'),
    const Materia(id: 2, nombre: 'Aplicaciones Web', color: '#C0807A'),
    const Materia(id: 3, nombre: 'Estructura de Datos', color: '#D4B483'),
    const Materia(id: 4, nombre: 'Literatura', color: '#8FA68A'),
    const Materia(id: 5, nombre: 'Biología', color: '#7D8FA6'),
    const Materia(id: 6, nombre: 'Física I', color: '#A68FA6'),
  ];

  int _siguienteId = 7;

  List<Materia> get materias => List.unmodifiable(_materias);

  Materia? porId(int id) {
    for (final m in _materias) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Devuelve null si se guardó, o el mensaje de error.
  String? agregar(String nombre, String color) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) {
      return 'Escribe el nombre de la materia';
    }
    final repetida =
        _materias.any((m) => m.nombre.toLowerCase() == limpio.toLowerCase());
    if (repetida) {
      return 'Esa materia ya existe';
    }
    _materias.add(Materia(id: _siguienteId++, nombre: limpio, color: color));
    notifyListeners();
    return null;
  }
}
