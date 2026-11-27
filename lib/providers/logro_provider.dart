import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/logro.dart';

/// Catálogo de logros (lo administra el Administrador, en `logros/{id}`) y
/// los logros que obtuvo el estudiante con sesión
/// (`usuarios/{uid}/logros/{logroId}`), guardados en Firestore.
///
/// Empieza a escuchar solo cuando hay una sesión y se detiene al cerrarla.
class LogroProvider extends ChangeNotifier {
  static void _log(String mensaje) {
    if (kDebugMode) debugPrint(mensaje);
  }

  /// Catálogo inicial que el admin puede cargar con un botón.
  static const catalogoInicial = [
    Logro(
      id: 'primer_paso',
      nombre: 'Primer paso',
      descripcion: 'Completa tu primera tarea.',
      xpRequerido: 10,
    ),
    Logro(
      id: 'en_marcha',
      nombre: 'En marcha',
      descripcion: 'Acumula 30 XP completando tareas.',
      xpRequerido: 30,
    ),
    Logro(
      id: 'constante',
      nombre: 'Constante',
      descripcion: 'Acumula 50 XP completando tareas.',
      xpRequerido: 50,
    ),
    Logro(
      id: 'organizado',
      nombre: 'Organizado',
      descripcion: 'Acumula 100 XP completando tareas.',
      xpRequerido: 100,
    ),
    Logro(
      id: 'maestro_del_tiempo',
      nombre: 'Maestro del tiempo',
      descripcion: 'Acumula 200 XP completando tareas.',
      xpRequerido: 200,
    ),
  ];

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _catalogo =>
      _db.collection('logros');
  CollectionReference<Map<String, dynamic>> _obtenidosDe(String uid) =>
      _db.collection('usuarios').doc(uid).collection('logros');

  List<Logro> _logros = [];
  List<EstudianteLogro> _obtenidos = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subCatalogo;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subObtenidos;
  StreamSubscription<User?>? _subSesion;

  LogroProvider() {
    _subSesion = FirebaseAuth.instance.authStateChanges().listen((usuario) {
      _subCatalogo?.cancel();
      _subObtenidos?.cancel();
      _subCatalogo = null;
      _subObtenidos = null;
      _logros = [];
      _obtenidos = [];
      notifyListeners();
      if (usuario == null) return;

      _subCatalogo = _catalogo.snapshots().listen(
        (snap) {
          _logros =
              snap.docs.map((d) => Logro.desdeMapa(d.id, d.data())).toList();
          notifyListeners();
        },
        onError: (Object e) => _log('[Logros] No se pudo leer el catálogo: $e'),
      );
      // Los logros obtenidos son de la propia cuenta (solo los estudiantes
      // tienen; para tutor y admin la lista queda vacía).
      _subObtenidos = _obtenidosDe(usuario.uid).snapshots().listen(
        (snap) {
          _obtenidos = snap.docs
              .map((d) => EstudianteLogro.desdeMapa(usuario.uid, d.id, d.data()))
              .toList();
          notifyListeners();
        },
        onError: (Object e) => _log('[Logros] No se pudieron leer los obtenidos: $e'),
      );
    });
  }

  @override
  void dispose() {
    _subCatalogo?.cancel();
    _subObtenidos?.cancel();
    _subSesion?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Consultas
  // -------------------------------------------------------------------

  /// Catálogo completo, del que pide menos XP al que pide más.
  List<Logro> get logros {
    final lista = List<Logro>.of(_logros);
    lista.sort((a, b) => a.xpRequerido.compareTo(b.xpRequerido));
    return lista;
  }

  Logro? porId(String id) {
    for (final l in _logros) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Registro de obtención de un logro para un estudiante, o null si sigue bloqueado.
  EstudianteLogro? obtenido(String estudianteId, String logroId) {
    for (final o in _obtenidos) {
      if (o.estudianteId == estudianteId && o.logroId == logroId) return o;
    }
    return null;
  }

  int cantidadObtenidos(String estudianteId) {
    return _obtenidos.where((o) => o.estudianteId == estudianteId).length;
  }

  // -------------------------------------------------------------------
  // Desbloqueo
  // -------------------------------------------------------------------

  /// Borra los logros obtenidos por un estudiante (al eliminar su cuenta).
  /// Se debe llamar ANTES de borrar la cuenta, mientras sigue con sesión.
  Future<void> eliminarDeEstudiante(String estudianteId) async {
    final snap = await _obtenidosDe(estudianteId).get();
    final lote = _db.batch();
    for (final d in snap.docs) {
      lote.delete(d.reference);
    }
    await lote.commit();
    _obtenidos = [];
    notifyListeners();
  }

  /// Desbloquea los logros cuyo XP requerido ya se alcanzó y devuelve los que
  /// se desbloquearon en este momento (para avisarle al estudiante).
  List<Logro> evaluar(String estudianteId, int xp) {
    final nuevos = <Logro>[];
    for (final logro in logros) {
      if (xp >= logro.xpRequerido && obtenido(estudianteId, logro.id) == null) {
        final ahora = DateTime.now();
        // Se agrega en memoria para avisar al instante, y se guarda en
        // Firestore (el id del documento es el del logro: no se duplica).
        _obtenidos.add(
          EstudianteLogro(
            id: logro.id,
            estudianteId: estudianteId,
            logroId: logro.id,
            fechaObtenido: ahora,
          ),
        );
        _escribir(
          _obtenidosDe(estudianteId)
              .doc(logro.id)
              .set({'fechaObtenido': Timestamp.fromDate(ahora)}),
        );
        nuevos.add(logro);
      }
    }
    if (nuevos.isNotEmpty) notifyListeners();
    return nuevos;
  }

  // -------------------------------------------------------------------
  // Administración del catálogo
  // -------------------------------------------------------------------

  String? _validar({
    String? idActual,
    required String nombre,
    required String descripcion,
    required int xpRequerido,
  }) {
    final n = nombre.trim();
    final d = descripcion.trim();
    if (n.length < 3) return 'El nombre debe tener al menos 3 caracteres';
    if (n.length > 60) return 'El nombre puede tener máximo 60 caracteres';
    if (d.isEmpty) return 'Escribe una descripción';
    if (d.length > 150) return 'La descripción puede tener máximo 150 caracteres';
    if (xpRequerido < 1) return 'El XP requerido debe ser mayor a 0';
    final repetido = _logros.any(
      (l) => l.id != idActual && l.nombre.toLowerCase() == n.toLowerCase(),
    );
    if (repetido) return 'Ya existe un logro con ese nombre';
    return null;
  }

  /// Devuelve null si se guardó, o el mensaje de error.
  String? agregar({
    required String nombre,
    required String descripcion,
    required int xpRequerido,
  }) {
    final error = _validar(
      nombre: nombre,
      descripcion: descripcion,
      xpRequerido: xpRequerido,
    );
    if (error != null) return error;
    _escribir(_catalogo.add({
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'xpRequerido': xpRequerido,
    }));
    return null;
  }

  /// Devuelve null si se guardó, o el mensaje de error. Los logros que algún
  /// estudiante ya obtuvo se conservan aunque cambie el XP requerido.
  String? actualizar({
    required String id,
    required String nombre,
    required String descripcion,
    required int xpRequerido,
  }) {
    if (porId(id) == null) return 'El logro ya no existe';
    final error = _validar(
      idActual: id,
      nombre: nombre,
      descripcion: descripcion,
      xpRequerido: xpRequerido,
    );
    if (error != null) return error;
    _escribir(_catalogo.doc(id).update({
      'nombre': nombre.trim(),
      'descripcion': descripcion.trim(),
      'xpRequerido': xpRequerido,
    }));
    return null;
  }

  /// Carga los logros de ejemplo (solo el admin; no borra los que ya hay).
  Future<void> cargarCatalogoInicial() async {
    final lote = _db.batch();
    for (final l in catalogoInicial) {
      lote.set(_catalogo.doc(l.id), l.aMapa());
    }
    await _escribir(lote.commit());
  }

  Future<void> _escribir(Future<Object?> operacion) async {
    try {
      await operacion;
    } catch (e) {
      _log('[Logros] No se pudo guardar: $e');
    }
  }
}
