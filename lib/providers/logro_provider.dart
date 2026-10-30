import 'package:flutter/foundation.dart';

import '../models/logro.dart';

/// Catálogo de logros (lo administra el Administrador) y los logros que ha
/// obtenido cada estudiante. En memoria, con datos de ejemplo.
class LogroProvider extends ChangeNotifier {
  final List<Logro> _logros = [
    const Logro(
      id: 1,
      nombre: 'Primer paso',
      descripcion: 'Completa tu primera tarea.',
      xpRequerido: 10,
    ),
    const Logro(
      id: 2,
      nombre: 'En marcha',
      descripcion: 'Acumula 30 XP completando tareas.',
      xpRequerido: 30,
    ),
    const Logro(
      id: 3,
      nombre: 'Constante',
      descripcion: 'Acumula 50 XP completando tareas.',
      xpRequerido: 50,
    ),
    const Logro(
      id: 4,
      nombre: 'Organizado',
      descripcion: 'Acumula 100 XP completando tareas.',
      xpRequerido: 100,
    ),
    const Logro(
      id: 5,
      nombre: 'Maestro del tiempo',
      descripcion: 'Acumula 200 XP completando tareas.',
      xpRequerido: 200,
    ),
  ];

  final List<EstudianteLogro> _obtenidos = [];
  int _siguienteLogroId = 6;
  int _siguienteObtenidoId = 1;

  LogroProvider() {
    _cargarDatosDeEjemplo();
  }

  DateTime _enDias(int dias, int hora, int minuto) {
    final h = DateTime.now();
    return DateTime(h.year, h.month, h.day + dias, hora, minuto);
  }

  /// Sofía ya tiene 30 XP (3 tareas completadas), así que ya desbloqueó los
  /// dos primeros logros en las fechas en que llegó a 10 y a 30 XP.
  void _cargarDatosDeEjemplo() {
    const sofiaId = 1;
    _obtenidos.addAll([
      EstudianteLogro(
        id: _siguienteObtenidoId++,
        estudianteId: sofiaId,
        logroId: 1,
        fechaObtenido: _enDias(-9, 11, 0),
      ),
      EstudianteLogro(
        id: _siguienteObtenidoId++,
        estudianteId: sofiaId,
        logroId: 2,
        fechaObtenido: _enDias(-1, 18, 30),
      ),
    ]);
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

  Logro? porId(int id) {
    for (final l in _logros) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Registro de obtención de un logro para un estudiante, o null si sigue bloqueado.
  EstudianteLogro? obtenido(int estudianteId, int logroId) {
    for (final o in _obtenidos) {
      if (o.estudianteId == estudianteId && o.logroId == logroId) return o;
    }
    return null;
  }

  int cantidadObtenidos(int estudianteId) {
    return _obtenidos.where((o) => o.estudianteId == estudianteId).length;
  }

  // -------------------------------------------------------------------
  // Desbloqueo
  // -------------------------------------------------------------------

  /// Borra los logros obtenidos por un estudiante (al eliminar su cuenta).
  void eliminarDeEstudiante(int estudianteId) {
    _obtenidos.removeWhere((o) => o.estudianteId == estudianteId);
    notifyListeners();
  }

  /// Desbloquea los logros cuyo XP requerido ya se alcanzó y devuelve los que
  /// se desbloquearon en este momento (para avisarle al estudiante).
  List<Logro> evaluar(int estudianteId, int xp) {
    final nuevos = <Logro>[];
    for (final logro in logros) {
      if (xp >= logro.xpRequerido && obtenido(estudianteId, logro.id) == null) {
        _obtenidos.add(
          EstudianteLogro(
            id: _siguienteObtenidoId++,
            estudianteId: estudianteId,
            logroId: logro.id,
            fechaObtenido: DateTime.now(),
          ),
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
    int? idActual,
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
    _logros.add(
      Logro(
        id: _siguienteLogroId++,
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
        xpRequerido: xpRequerido,
      ),
    );
    notifyListeners();
    return null;
  }

  /// Devuelve null si se guardó, o el mensaje de error. Los logros que algún
  /// estudiante ya obtuvo se conservan aunque cambie el XP requerido.
  String? actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required int xpRequerido,
  }) {
    final i = _logros.indexWhere((l) => l.id == id);
    if (i == -1) return 'El logro ya no existe';
    final error = _validar(
      idActual: id,
      nombre: nombre,
      descripcion: descripcion,
      xpRequerido: xpRequerido,
    );
    if (error != null) return error;
    _logros[i] = Logro(
      id: id,
      nombre: nombre.trim(),
      descripcion: descripcion.trim(),
      xpRequerido: xpRequerido,
    );
    notifyListeners();
    return null;
  }
}
