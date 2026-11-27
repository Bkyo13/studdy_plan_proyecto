import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vinculo.dart';

/// Relación entre cada tutor y el estudiante que tiene vinculado (uno por
/// tutor). Se guarda en Firestore en `vinculos/{tutorId}`: como el id del
/// documento es el del tutor, un tutor no puede tener dos vínculos.
///
/// El tutor envía una solicitud ('pendiente') y el estudiante la acepta o la
/// rechaza desde su app. Hasta que la acepta, el tutor no ve nada suyo.
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

  // Lado del estudiante: los vínculos donde él aparece (pendientes o no).
  List<Vinculo> _delEstudiante = [];
  String? _estudianteEscuchado;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subSolicitudes;

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
        _vinculo = datos == null ? null : Vinculo.desdeMapa(tutorId, datos);
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

  /// Lado del estudiante: escucha las solicitudes y los tutores que tiene.
  void escucharSolicitudes(String estudianteId) {
    if (_estudianteEscuchado == estudianteId && _subSolicitudes != null) return;
    _subSolicitudes?.cancel();
    _estudianteEscuchado = estudianteId;
    _delEstudiante = [];
    _subSolicitudes = _coleccion
        .where('estudianteId', isEqualTo: estudianteId)
        .snapshots()
        .listen(
      (snap) {
        _delEstudiante =
            snap.docs.map((d) => Vinculo.desdeMapa(d.id, d.data())).toList();
        notifyListeners();
      },
      onError: (Object e) {
        _log('[Vinculos] No se pudieron leer las solicitudes: $e');
      },
    );
  }

  /// Deja de escuchar (al cerrar sesión).
  void detener() {
    if (_sub == null &&
        _tutorEscuchado == null &&
        _subSolicitudes == null &&
        _estudianteEscuchado == null) {
      return;
    }
    _sub?.cancel();
    _sub = null;
    _tutorEscuchado = null;
    _vinculo = null;
    _cargando = false;
    _subSolicitudes?.cancel();
    _subSolicitudes = null;
    _estudianteEscuchado = null;
    _delEstudiante = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _subSolicitudes?.cancel();
    super.dispose();
  }

  /// Id del estudiante vinculado a [tutorId] (solo si ya aceptó), o null.
  String? estudianteIdDe(String tutorId) {
    final v = _vinculo;
    if (v == null ||
        v.tutorId != tutorId ||
        v.estudianteId.isEmpty ||
        !v.esAceptado) {
      return null;
    }
    return v.estudianteId;
  }

  /// Id del estudiante al que [tutorId] le mandó una solicitud que sigue
  /// sin respuesta, o null.
  String? pendienteDe(String tutorId) {
    final v = _vinculo;
    if (v == null || v.tutorId != tutorId || !v.esPendiente) return null;
    return v.estudianteId.isEmpty ? null : v.estudianteId;
  }

  /// Solicitudes que el estudiante todavía no responde.
  List<Vinculo> get solicitudesPendientes =>
      _delEstudiante.where((v) => v.esPendiente).toList();

  /// Tutores que el estudiante ya aceptó.
  List<Vinculo> get tutoresAceptados =>
      _delEstudiante.where((v) => v.esAceptado).toList();

  /// El tutor envía la solicitud (reemplaza el vínculo anterior, si había).
  Future<void> vincular(String tutorId, String estudianteId) async {
    _vinculo = Vinculo(tutorId: tutorId, estudianteId: estudianteId);
    notifyListeners();
    try {
      await _coleccion.doc(tutorId).set({
        'tutorId': tutorId,
        'estudianteId': estudianteId,
        'estado': Vinculo.pendiente,
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

  /// El estudiante acepta la solicitud de [tutorId].
  Future<bool> aceptar(String tutorId) async {
    try {
      await _coleccion.doc(tutorId).update({'estado': Vinculo.aceptado});
      return true;
    } catch (e) {
      _log('[Vinculos] No se pudo aceptar la solicitud: $e');
      return false;
    }
  }

  /// El estudiante rechaza la solicitud de [tutorId], o quita a un tutor
  /// que ya había aceptado. En los dos casos se borra el vínculo.
  Future<bool> rechazar(String tutorId) async {
    final antes = _delEstudiante;
    _delEstudiante = _delEstudiante.where((v) => v.tutorId != tutorId).toList();
    notifyListeners();
    try {
      await _coleccion.doc(tutorId).delete();
      return true;
    } catch (e) {
      _log('[Vinculos] No se pudo quitar el vínculo: $e');
      _delEstudiante = antes;
      notifyListeners();
      return false;
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
