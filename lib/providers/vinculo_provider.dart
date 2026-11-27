import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vinculo.dart';

/// Relación entre cada tutor y el estudiante que tiene vinculado (uno por
/// tutor). Se guarda en Firestore en `vinculos/{tutorId}`: como el id del
/// documento es el del tutor, un tutor no puede tener dos vínculos.
class VinculoProvider extends ChangeNotifier {
  static void _log(String mensaje) {
    if (kDebugMode) debugPrint(mensaje);
  }

  final CollectionReference<Map<String, dynamic>> _coleccion =
      FirebaseFirestore.instance.collection('vinculos');

  Vinculo? _vinculo;
  String? _tutorEscuchado;
  bool _cargando = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  /// True mientras llega la primera lectura de Firestore.
  bool get cargando => _cargando;

  /// Empieza a escuchar el vínculo del tutor que tiene la sesión.
  void escuchar(String tutorId) {
    if (_tutorEscuchado == tutorId && _sub != null) return;
    _sub?.cancel();
    _tutorEscuchado = tutorId;
    _vinculo = null;
    _cargando = true;
    notifyListeners();
    _sub = _coleccion.doc(tutorId).snapshots().listen(
      (doc) {
        final datos = doc.data();
        _vinculo = datos == null
            ? null
            : Vinculo(
                tutorId: tutorId,
                estudianteId: datos['estudianteId'] as String? ?? '',
              );
        _cargando = false;
        notifyListeners();
      },
      onError: (Object e) {
        _log('[Vinculos] No se pudo leer el vínculo: $e');
        _cargando = false;
        notifyListeners();
      },
    );
  }

  /// Deja de escuchar (al cerrar sesión).
  void detener() {
    if (_sub == null && _tutorEscuchado == null) return;
    _sub?.cancel();
    _sub = null;
    _tutorEscuchado = null;
    _vinculo = null;
    _cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Id del estudiante vinculado a [tutorId], o null si todavía no tiene.
  String? estudianteIdDe(String tutorId) {
    final v = _vinculo;
    if (v == null || v.tutorId != tutorId || v.estudianteId.isEmpty) {
      return null;
    }
    return v.estudianteId;
  }

  /// Vincula al tutor con un estudiante (reemplaza el vínculo anterior, si había).
  Future<void> vincular(String tutorId, String estudianteId) async {
    _vinculo = Vinculo(tutorId: tutorId, estudianteId: estudianteId);
    notifyListeners();
    try {
      await _coleccion.doc(tutorId).set({
        'tutorId': tutorId,
        'estudianteId': estudianteId,
        'fecha': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _log('[Vinculos] No se pudo guardar el vínculo: $e');
    }
  }

  Future<void> desvincular(String tutorId) async {
    _vinculo = null;
    notifyListeners();
    try {
      await _coleccion.doc(tutorId).delete();
    } catch (e) {
      _log('[Vinculos] No se pudo borrar el vínculo: $e');
    }
  }

  /// Quita los vínculos de tutores con un estudiante (al eliminar su cuenta).
  /// Se debe llamar ANTES de borrar la cuenta, mientras sigue con sesión.
  Future<void> eliminarDeEstudiante(String estudianteId) async {
    final snap = await _coleccion
        .where('estudianteId', isEqualTo: estudianteId)
        .get();
    final lote = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      lote.delete(d.reference);
    }
    await lote.commit();
  }
}
