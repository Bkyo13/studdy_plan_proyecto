import 'package:flutter/foundation.dart';

import '../models/usuario.dart';
import '../models/vinculo.dart';

class VinculoProvider extends ChangeNotifier {
  final List<Vinculo> _vinculos = [];
  // Guarda el estudiante vinculado para mostrar su nombre sin tocar AuthProvider.
  final Map<int, Usuario> _estudiantes = {};

  bool tieneVinculo(int tutorId) => _vinculos.any((v) => v.tutorId == tutorId);

  /// Estudiante vinculado de un tutor (null si no tiene).
  Usuario? estudianteDe(int tutorId) => _estudiantes[tutorId];

  /// Un tutor tiene un solo estudiante: vincular reemplaza el anterior.
  void vincular(int tutorId, Usuario estudiante) {
    _vinculos.removeWhere((v) => v.tutorId == tutorId);
    _vinculos.add(Vinculo(tutorId: tutorId, estudianteId: estudiante.id));
    _estudiantes[tutorId] = estudiante;
    notifyListeners();
  }

  void desvincular(int tutorId) {
    _vinculos.removeWhere((v) => v.tutorId == tutorId);
    _estudiantes.remove(tutorId);
    notifyListeners();
  }
}