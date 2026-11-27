import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/registro_xp.dart';
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
  // ---------------- Reglas del XP ----------------
  /// Puntos base según la prioridad de la tarea.
  static const xpAlta = 15;
  static const xpMedia = 10;
  static const xpBaja = 5;

  /// Bono por completarla antes de la fecha de entrega.
  static const bonoATiempo = 5;

  /// Anti-trampa: si se completa antes de este tiempo desde que se creó,
  /// no da XP (evita crear "a" y completarla al instante para subir de nivel).
  static const tiempoMinimo = Duration(hours: 1);

  /// XP de una tarea típica (prioridad media, a tiempo). Solo para mostrar
  /// estimaciones ("te faltan unas N tareas").
  static const xpTareaTipica = xpMedia + bonoATiempo;

  /// Calcula los puntos y el motivo de completar [tarea] en [momento]:
  /// base por prioridad, +5 a tiempo, la mitad si es tarde, 0 si fue
  /// completada menos de 1 hora después de crearla.
  static (int, String) calcularXP(Tarea tarea, DateTime momento) {
    final creada = tarea.fechaCreacion;
    if (creada != null && momento.difference(creada) < tiempoMinimo) {
      return (0, 'muy_rapido');
    }
    final base = switch (tarea.prioridad) {
      Prioridad.alta => xpAlta,
      Prioridad.media => xpMedia,
      Prioridad.baja => xpBaja,
    };
    if (!momento.isAfter(tarea.fechaEntrega)) {
      return (base + bonoATiempo, 'a_tiempo');
    }
    return ((base / 2).ceil(), 'tarde');
  }

  static void _log(String mensaje) {
    if (kDebugMode) debugPrint(mensaje);
  }

  final CollectionReference<Map<String, dynamic>> _coleccion =
      FirebaseFirestore.instance.collection('tareas');

  List<Tarea> _tareas = [];
  List<RegistroXP> _registrosXP = [];
  String? _estudianteEscuchado;
  bool _programarAvisos = false;
  bool _cargando = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subXP;

  CollectionReference<Map<String, dynamic>> _xpDe(String estudianteId) =>
      FirebaseFirestore.instance
          .collection('usuarios')
          .doc(estudianteId)
          .collection('xp');

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
    _registrosXP = [];
    _cargando = true;
    notifyListeners();

    // Historial de XP del mismo estudiante (también lo lee su tutor).
    _subXP?.cancel();
    _subXP = _xpDe(estudianteId).snapshots().listen(
      (snap) {
        _registrosXP = snap.docs
            .map((d) => RegistroXP.desdeMapa(d.id, d.data()))
            .toList();
        notifyListeners();
      },
      onError: (Object e) => _log('[XP] No se pudo leer el historial: $e'),
    );

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
    _subXP?.cancel();
    _subXP = null;
    _registrosXP = [];
    _estudianteEscuchado = null;
    _programarAvisos = false;
    _tareas = [];
    _cargando = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _subXP?.cancel();
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

  /// XP total: suma del historial guardado (no baja si se borra una tarea).
  int xpDe(String estudianteId) {
    if (estudianteId != _estudianteEscuchado) return 0;
    return _registrosXP.fold(0, (total, r) => total + r.puntos);
  }

  /// Historial de XP del estudiante escuchado, del más reciente al más viejo
  /// (lo usa la pantalla Mi progreso).
  List<RegistroXP> registrosXP(String estudianteId) {
    if (estudianteId != _estudianteEscuchado) return const [];
    return List.of(_registrosXP)..sort((a, b) => b.fecha.compareTo(a.fecha));
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
      fechaCreacion: DateTime.now(),
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

  /// Marca la tarea como completada y guarda su XP. Devuelve los puntos
  /// ganados (0 si no la encontró o si aplicó el anti-trampa), para mostrar
  /// "+N XP". Todo se actualiza en memoria al instante (los logros se
  /// evalúan justo después) y se guarda en Firestore en segundo plano.
  int completar(String id) {
    final tarea = porId(id);
    if (tarea == null || tarea.estado == Estado.completada) return 0;
    final ahora = DateTime.now();
    final (puntos, motivo) = calcularXP(tarea, ahora);
    tarea.estado = Estado.completada;
    tarea.fechaCompletada = ahora;
    final registro = RegistroXP(
      tareaId: tarea.id,
      puntos: puntos,
      motivo: motivo,
      prioridad: tarea.prioridad,
      materiaId: tarea.materiaId,
      tareaNombre: tarea.nombre,
      fecha: ahora,
    );
    _registrosXP = [
      ..._registrosXP.where((r) => r.tareaId != tarea.id),
      registro,
    ];
    notifyListeners();
    _guardar(() => _coleccion.doc(id).update({
          'estado': Estado.completada.name,
          'fechaCompletada': Timestamp.fromDate(ahora),
        }));
    _guardar(() => _xpDe(tarea.estudianteId).doc(tarea.id).set(registro.aMapa()));
    return puntos;
  }

  /// Regresa una tarea completada a pendiente (botón "Deshacer" o
  /// "Marcar como pendiente"). El XP baja solo, porque se calcula a partir
  /// de las tareas completadas.
  Future<void> reabrir(String id) async {
    final tarea = porId(id);
    if (tarea == null || tarea.estado == Estado.pendiente) return;
    tarea.estado = Estado.pendiente;
    tarea.fechaCompletada = null;
    // Se quita el XP que dio, para que completar y deshacer no sume de más.
    _registrosXP = _registrosXP.where((r) => r.tareaId != id).toList();
    notifyListeners();
    await _guardar(() => _coleccion.doc(id).update({
          'estado': Estado.pendiente.name,
          'fechaCompletada': null,
        }));
    await _guardar(() => _xpDe(tarea.estudianteId).doc(id).delete());
  }

  /// Borra la tarea. El XP que ya dio se queda (está en el historial).
  /// Se quita de la lista al instante (lo necesita el deslizar para borrar).
  Future<void> eliminar(String id) async {
    _tareas = _tareas.where((t) => t.id != id).toList();
    notifyListeners();
    await _guardar(() => _coleccion.doc(id).delete());
  }

  /// Borra todas las tareas de un estudiante (al eliminar su cuenta). Se
  /// debe llamar ANTES de borrar la cuenta, mientras sigue con sesión.
  Future<void> eliminarDeEstudiante(String estudianteId) async {
    final snap =
        await _coleccion.where('estudianteId', isEqualTo: estudianteId).get();
    final xp = await _xpDe(estudianteId).get();
    final lote = FirebaseFirestore.instance.batch();
    for (final d in [...snap.docs, ...xp.docs]) {
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
