import 'package:flutter/foundation.dart';

import '../models/tarea.dart';

class TareaProvider extends ChangeNotifier {
  /// XP por tarea completada (valor provisional).
  static const int xpPorTarea = 10;

  // Ajustar si los ids de la PARTE A son distintos.
  static const int _idSofia = 1;
  static const int _matCalculo = 1;
  static const int _matWeb = 2;
  static const int _matEstructura = 3;
  static const int _matLiteratura = 4;
  static const int _matBiologia = 5;
  static const int _matFisica = 6;

  final List<Tarea> _tareas = [];
  int _siguienteId = 1;

  TareaProvider() {
    _cargarEjemplo();
  }

  void _cargarEjemplo() {
    final ahora = DateTime.now();
    DateTime dia(int desplazamiento, int hora, int minuto) => DateTime(
          ahora.year,
          ahora.month,
          ahora.day + desplazamiento,
          hora,
          minuto,
        );

    _tareas.addAll([
      Tarea(
        id: _siguienteId++,
        nombre: 'Resolver problemario de derivadas',
        descripcion:
            'Resolver los ejercicios 1 al 20 del problemario de derivadas parciales y subir el PDF.',
        fechaEntrega: dia(1, 14, 0),
        fechaCompletada: null,
        prioridad: Prioridad.alta,
        estado: Estado.pendiente,
        materiaId: _matCalculo,
        estudianteId: _idSofia,
      ),
      Tarea(
        id: _siguienteId++,
        nombre: 'Rehacer todo el CSS de mi web',
        descripcion:
            'Reescribir los estilos del proyecto con diseño responsivo y variables de color.',
        fechaEntrega: dia(3, 23, 59),
        fechaCompletada: null,
        prioridad: Prioridad.media,
        estado: Estado.pendiente,
        materiaId: _matWeb,
        estudianteId: _idSofia,
      ),
      Tarea(
        id: _siguienteId++,
        nombre: 'Hacer las torres de hanoi',
        descripcion:
            'Implementar las torres de Hanoi de forma recursiva y probar con 3, 4 y 5 discos.',
        fechaEntrega: dia(5, 10, 0),
        fechaCompletada: null,
        prioridad: Prioridad.baja,
        estado: Estado.pendiente,
        materiaId: _matEstructura,
        estudianteId: _idSofia,
      ),
      Tarea(
        id: _siguienteId++,
        nombre: 'Lectura de capítulos 1 y 2',
        descripcion: 'Leer los capítulos 1 y 2 y preparar un resumen.',
        fechaEntrega: dia(-1, 12, 0),
        fechaCompletada: dia(-1, 18, 0),
        prioridad: Prioridad.media,
        estado: Estado.completada,
        materiaId: _matLiteratura,
        estudianteId: _idSofia,
      ),
      Tarea(
        id: _siguienteId++,
        nombre: 'Maqueta de célula animal',
        descripcion: 'Maqueta con las partes principales de la célula animal.',
        fechaEntrega: dia(-3, 9, 0),
        fechaCompletada: dia(-3, 16, 30),
        prioridad: Prioridad.baja,
        estado: Estado.completada,
        materiaId: _matBiologia,
        estudianteId: _idSofia,
      ),
      Tarea(
        id: _siguienteId++,
        nombre: 'Investigación de vectores',
        descripcion: 'Investigar operaciones con vectores y ejemplos físicos.',
        fechaEntrega: dia(-9, 8, 0),
        fechaCompletada: dia(-9, 15, 0),
        prioridad: Prioridad.alta,
        estado: Estado.completada,
        materiaId: _matFisica,
        estudianteId: _idSofia,
      ),
    ]);
  }

  /// Pendientes ordenadas por fecha de entrega; completadas de la más reciente a la más antigua.
  List<Tarea> porEstudiante(int estudianteId, Estado estado) {
    final lista = _tareas
        .where((t) => t.estudianteId == estudianteId && t.estado == estado)
        .toList();
    if (estado == Estado.pendiente) {
      lista.sort((a, b) => a.fechaEntrega.compareTo(b.fechaEntrega));
    } else {
      lista.sort((a, b) => (b.fechaCompletada ?? b.fechaEntrega)
          .compareTo(a.fechaCompletada ?? a.fechaEntrega));
    }
    return lista;
  }

  int totalPorEstado(int estudianteId, Estado estado) {
    return _tareas
        .where((t) => t.estudianteId == estudianteId && t.estado == estado)
        .length;
  }

  int xpDe(int estudianteId) {
    return totalPorEstado(estudianteId, Estado.completada) * xpPorTarea;
  }

  /// Tareas completadas en los últimos 7 días.
  int completadasUltimos7Dias(int estudianteId) {
    final ahora = DateTime.now();
    return _tareas.where((t) {
      final f = t.fechaCompletada;
      return t.estudianteId == estudianteId &&
          t.estado == Estado.completada &&
          f != null &&
          ahora.difference(f).inDays < 7;
    }).length;
  }

  Tarea? porId(int id) {
    for (final t in _tareas) {
      if (t.id == id) return t;
    }
    return null;
  }

  void agregar({
    required String nombre,
    required String descripcion,
    required DateTime fechaEntrega,
    required Prioridad prioridad,
    required int materiaId,
    required int estudianteId,
  }) {
    _tareas.add(
      Tarea(
        id: _siguienteId++,
        nombre: nombre,
        descripcion: descripcion,
        fechaEntrega: fechaEntrega,
        fechaCompletada: null,
        prioridad: prioridad,
        estado: Estado.pendiente,
        materiaId: materiaId,
        estudianteId: estudianteId,
      ),
    );
    notifyListeners();
  }

  void actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required DateTime fechaEntrega,
    required Prioridad prioridad,
    required int materiaId,
  }) {
    final i = _tareas.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final t = _tareas[i];
    _tareas[i] = Tarea(
      id: t.id,
      nombre: nombre,
      descripcion: descripcion,
      fechaEntrega: fechaEntrega,
      fechaCompletada: t.fechaCompletada,
      prioridad: prioridad,
      estado: t.estado,
      materiaId: materiaId,
      estudianteId: t.estudianteId,
    );
    notifyListeners();
  }

  void completar(int id) {
    final i = _tareas.indexWhere((t) => t.id == id);
    if (i == -1) return;
    final t = _tareas[i];
    _tareas[i] = Tarea(
      id: t.id,
      nombre: t.nombre,
      descripcion: t.descripcion,
      fechaEntrega: t.fechaEntrega,
      fechaCompletada: DateTime.now(),
      prioridad: t.prioridad,
      estado: Estado.completada,
      materiaId: t.materiaId,
      estudianteId: t.estudianteId,
    );
    notifyListeners();
  }

  void eliminar(int id) {
    _tareas.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}