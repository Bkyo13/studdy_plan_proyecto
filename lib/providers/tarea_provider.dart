import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/tarea.dart';
import '../services/notificaciones_service.dart';

/// Tareas de los estudiantes, guardadas en Firestore (`tareas/{id}`).
///
/// La app escucha solo las tareas de UN estudiante a la vez ([escuchar]):
///   - el estudiante, las suyas;
///   - el tutor, las del estudiante que tiene vinculado.
/// Firestore manda los cambios en tiempo real, y como guarda una copia en el
/// teléfono, la app también funciona sin internet (los cambios se suben
/// cuando vuelve la conexión).
class TareaProvider extends ChangeNotifier {
  /// XP que se gana por cada tarea completada (valor provisional, ajustable).
  static const int xpPorTarea = 10;

  static void _log(String mensaje) {
    if (kDebugMode) debugPrint(mensaje);
  }

  final CollectionReference<Map<String, dynamic>> _coleccion =
      FirebaseFirestore.instance.collection('tareas');

  List<Tarea> _tareas = [];
  String? _estudianteEscuchado;
  bool _programarAvisos = false;
  bool _cargando = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  /// True mientras llega la primera lectura de Firestore.
  bool get cargando => _cargando;

  /// Empieza a escuchar las tareas de [estudianteId]. Si ya las estaba
  /// escuchando, no hace nada. Con [programarAvisos] (solo el propio
  /// estudiante), cada cambio deja al día los recordatorios del teléfono.
  void escuchar(String estudianteId, {bool programarAvisos = false}) {
    if (_estudianteEscuchado == estudianteId &&
        _programarAvisos == programarAvisos &&
        _sub != null) {
      return;
    }
    _sub?.cancel();
    _estudianteEscuchado = estudianteId;
    _programarAvisos = programarAvisos;
    _tareas = [];
    _cargando = true;
    notifyListeners();

    _sub = _coleccion
        .where('estudianteId', isEqualTo: estudianteId)
        .snapshots()
        .listen(
      (snap) {
        _tareas = snap.docs
            .map((d) => Tarea.desdeMapa(d.id, d.data()))
            .toList();
        _cargando = false;
        if (_programarAvisos) {
          NotificacionesService.instancia.sincronizar(
            _tareas.where((t) => t.estado == Estado.pendiente).toList(),
          );
        }
        notifyListeners();
      },
      onError: (Object e) {
        _log('[Tareas] No se pudieron leer: $e');
        _cargando = false;
        notifyListeners();
      },
    );
  }

  /// Deja de escuchar (al cerrar sesión o desvincular).
  void detener() {
    if (_sub == null && _estudianteEscuchado == null) return;
    _sub?.cancel();
    _sub = null;
    _estudianteEscuchado = null;
    _programarAvisos = false;
    _tareas = [];
    _cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Consultas (sobre las tareas que se están escuchando)
  // ---------------------------------------------------------------------

  /// Tareas de un estudiante. Pendientes por fecha de entrega (la más próxima
  /// primero) y completadas de la más reciente a la más antigua.
  List<Tarea> tareasDe(String estudianteId, {Estado? estado}) {
    final lista = _tareas
        .where((t) =>
            t.estudianteId == estudianteId &&
            (estado == null || t.estado == estado))
        .toList();
    lista.sort((a, b) {
      if (a.estado == Estado.completada && b.estado == Estado.completada) {
        final fa = a.fechaCompletada ?? a.fechaEntrega;
        final fb = b.fechaCompletada ?? b.fechaEntrega;
        return fb.compareTo(fa);
      }
      return a.fechaEntrega.compareTo(b.fechaEntrega);
    });
    return lista;
  }

  Tarea? porId(String id) {
    for (final t in _tareas) {
      if (t.id == id) return t;
    }
    return null;
  }

  int contarPorEstado(String estudianteId, Estado estado) {
    return _tareas
        .where((t) => t.estudianteId == estudianteId && t.estado == estado)
        .length;
  }

  /// Tareas pendientes cuya fecha de entrega ya pasó.
  int contarVencidas(String estudianteId) {
    return _tareas
        .where((t) => t.estudianteId == estudianteId && t.vencida)
        .length;
  }

  /// XP total: puntos por cada tarea completada.
  int xpDe(String estudianteId) {
    return contarPorEstado(estudianteId, Estado.completada) * xpPorTarea;
  }

  /// Tareas completadas en los últimos 7 días (para el banner de progreso).
  int completadasEnLaSemana(String estudianteId) {
    final limite = DateTime.now().subtract(const Duration(days: 7));
    return _tareas
        .where((t) =>
            t.estudianteId == estudianteId &&
            t.estado == Estado.completada &&
            t.fechaCompletada != null &&
            t.fechaCompletada!.isAfter(limite))
        .length;
  }

  // ---------------------------------------------------------------------
  // Cambios (se guardan en Firestore; la lista se actualiza sola al llegar
  // el cambio, incluso sin internet)
  // ---------------------------------------------------------------------

  Future<void> agregar({
    required String nombre,
    required String descripcion,
    required DateTime fechaEntrega,
    required Prioridad prioridad,
    required String materiaId,
    required String estudianteId,
  }) async {
    final doc = _coleccion.doc();
    final nueva = Tarea(
      id: doc.id,
      nombre: nombre.trim(),
      descripcion: descripcion.trim(),
      fechaEntrega: fechaEntrega,
      prioridad: prioridad,
      materiaId: materiaId,
      estudianteId: estudianteId,
    );
    await _guardar(() => doc.set(nueva.aMapa()));
  }

  Future<void> actualizar({
    required String id,
    required String nombre,
    required String descripcion,
    required DateTime fechaEntrega,
    required Prioridad prioridad,
    required String materiaId,
  }) async {
    await _guardar(() => _coleccion.doc(id).update({
          'nombre': nombre.trim(),
          'descripcion': descripcion.trim(),
          'fechaEntrega': Timestamp.fromDate(fechaEntrega),
          'prioridad': prioridad.name,
          'materiaId': materiaId,
        }));
  }

  Future<void> completar(String id) async {
    final tarea = porId(id);
    if (tarea == null || tarea.estado == Estado.completada) return;
    final ahora = DateTime.now();
    // Se marca también en memoria para que XP y logros se calculen al
    // instante (justo después de completar se evalúan los logros).
    tarea.estado = Estado.completada;
    tarea.fechaCompletada = ahora;
    notifyListeners();
    await _guardar(() => _coleccion.doc(id).update({
          'estado': Estado.completada.name,
          'fechaCompletada': Timestamp.fromDate(ahora),
        }));
  }

  /// Regresa una tarea completada a pendiente (botón "Deshacer" o
  /// "Marcar como pendiente"). El XP baja solo, porque se calcula a partir
  /// de las tareas completadas.
  Future<void> reabrir(String id) async {
    final tarea = porId(id);
    if (tarea == null || tarea.estado == Estado.pendiente) return;
    tarea.estado = Estado.pendiente;
    tarea.fechaCompletada = null;
    notifyListeners();
    await _guardar(() => _coleccion.doc(id).update({
          'estado': Estado.pendiente.name,
          'fechaCompletada': null,
        }));
  }

  Future<void> eliminar(String id) async {
    await _guardar(() => _coleccion.doc(id).delete());
  }

  /// Borra todas las tareas de un estudiante (al eliminar su cuenta). Se
  /// debe llamar ANTES de borrar la cuenta, mientras sigue con sesión.
  Future<void> eliminarDeEstudiante(String estudianteId) async {
    final snap =
        await _coleccion.where('estudianteId', isEqualTo: estudianteId).get();
    final lote = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      lote.delete(d.reference);
    }
    await lote.commit();
    await NotificacionesService.instancia.cancelarTodas();
  }

  /// Sin internet, Firestore guarda el cambio en el teléfono y lo sube
  /// después; el Future no termina hasta entonces, así que no se espera de
  /// más: solo se registra si falla (por ejemplo, por las reglas).
  Future<void> _guardar(Future<void> Function() operacion) async {
    try {
      await operacion();
    } catch (e) {
      _log('[Tareas] No se pudo guardar el cambio: $e');
    }
  }
}
