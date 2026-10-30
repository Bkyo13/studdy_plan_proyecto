import 'package:flutter/foundation.dart';

import '../models/vinculo.dart';

/// Relación entre cada tutor y el estudiante que tiene vinculado (uno por tutor).
class VinculoProvider extends ChangeNotifier {
  final List<Vinculo> _vinculos = [];

  /// Id del estudiante vinculado a [tutorId], o null si todavía no tiene.
  int? estudianteIdDe(int tutorId) {
    for (final v in _vinculos) {
      if (v.tutorId == tutorId) return v.estudianteId;
    }
    return null;
  }

  /// Vincula al tutor con un estudiante (reemplaza el vínculo anterior, si había).
  void vincular(int tutorId, int estudianteId) {
    _vinculos.removeWhere((v) => v.tutorId == tutorId);
    _vinculos.add(Vinculo(tutorId: tutorId, estudianteId: estudianteId));
    notifyListeners();
  }

  /// Quita los vínculos de tutores con un estudiante (al eliminar su cuenta).
  void eliminarDeEstudiante(int estudianteId) {
    _vinculos.removeWhere((v) => v.estudianteId == estudianteId);
    notifyListeners();
  }

  void desvincular(int tutorId) {
    _vinculos.removeWhere((v) => v.tutorId == tutorId);
    notifyListeners();
  }
}
