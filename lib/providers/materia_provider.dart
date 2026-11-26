import 'package:flutter/foundation.dart';

import '../models/materia.dart';

/// Catálogo de materias (en memoria, solo para la demo).
class MateriaProvider extends ChangeNotifier {
  final List<Materia> _materias = [
    const Materia(id: '1', nombre: 'Cálculo de Varias Variables', color: '#758B75'),
    const Materia(id: '2', nombre: 'Aplicaciones Web', color: '#C0807A'),
    const Materia(id: '3', nombre: 'Estructura de Datos', color: '#D4B483'),
    const Materia(id: '4', nombre: 'Literatura', color: '#8FA68A'),
    const Materia(id: '5', nombre: 'Biología', color: '#7D8FA6'),
    const Materia(id: '6', nombre: 'Física I', color: '#A68FA6'),
  ];

  int _siguienteId = 7;

  List<Materia> get materias => List.unmodifiable(_materias);

  Materia? porId(String id) {
    for (final m in _materias) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Revisa nombre vacío, largo y repetido. [idActual] es la materia que se
  /// está editando (para que no choque consigo misma).
  String? _validar(String nombre, {String? idActual}) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe el nombre de la materia';
    if (limpio.length < 3) return 'Mínimo 3 caracteres';
    if (limpio.length > 60) return 'Máximo 60 caracteres';
    final repetida = _materias.any(
      (m) => m.id != idActual && m.nombre.toLowerCase() == limpio.toLowerCase(),
    );
    if (repetida) return 'Esa materia ya existe';
    return null;
  }

  /// Devuelve null si se guardó, o el mensaje de error.
  String? agregar(String nombre, String color) {
    final error = _validar(nombre);
    if (error != null) return error;
    _materias.add(Materia(id: '${_siguienteId++}', nombre: nombre.trim(), color: color));
    notifyListeners();
    return null;
  }

  /// Cambia nombre y color. Las tareas guardan solo el id de la materia, así
  /// que todas ven el cambio al instante. Devuelve null si se guardó.
  String? actualizar({
    required String id,
    required String nombre,
    required String color,
  }) {
    final i = _materias.indexWhere((m) => m.id == id);
    if (i == -1) return 'La materia ya no existe';
    final error = _validar(nombre, idActual: id);
    if (error != null) return error;
    _materias[i] = Materia(id: id, nombre: nombre.trim(), color: color);
    notifyListeners();
    return null;
  }
}
