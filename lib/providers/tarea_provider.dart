import 'package:flutter/foundation.dart';

import '../models/tarea.dart';

/// Tareas de los estudiantes (en memoria, con datos de ejemplo para Sofía).
class TareaProvider extends ChangeNotifier {
  /// XP que se gana por cada tarea completada (valor provisional, ajustable).
  static const int xpPorTarea = 10;

  final List<Tarea> _tareas = [];
  int _siguienteId = 1;

  TareaProvider() {
    _cargarDatosDeEjemplo();
  }

  DateTime _enDias(int dias, int hora, int minuto) {
    final h = DateTime.now();
    return DateTime(h.year, h.month, h.day + dias, hora, minuto);
  }

  void _cargarDatosDeEjemplo() {
    const sofiaId = 1;
    _tareas.addAll([
      Tarea(
        id: _siguienteId++,
        nombre: 'Resolver problemario de derivadas',
        descripcion:
            'Completar los ejercicios del 1 al 15 de la sección 4.2 del libro de texto. '
            'Es necesario mostrar todo el procedimiento y justificar la regla de la '
            'cadena aplicada en cada solución. Entregar en formato PDF.',
        fechaEntrega: _enDias(1, 14, 0),
        prioridad: Prioridad.alta,
        materiaId: 1,
        estudianteId: sofiaId,
      ),
      Tarea(
        id: _siguienteId++,
        nombre: 'Rehacer todo el CSS de mi web',
        descripcion:
            'Reescribir los estilos del sitio con flexbox y variables de color.',
        fechaEntrega: _enDias(3, 23, 59),
        prioridad: Prioridad.media,
        materiaId: 2,
        estudianteId: sofiaId,
      ),
      Tarea(
        id: _siguienteId++,
        nombre: 'Hacer las torres de hanoi',
        descripcion: 'Implementar la solución recursiva y probarla con 3 y 4 discos.',
        fechaEntrega: _enDias(5, 10, 0),
        prioridad: Prioridad.baja,
        materiaId: 3,
        estudianteId: sofiaId,
      ),
      Tarea(
        id: _siguienteId++,
        nombre: 'Lectura de capítulos 1 y 2',
        descripcion: 'Leer los dos primeros capítulos y preparar un resumen.',
        fechaEntrega: _enDias(-1, 23, 59),
        prioridad: Prioridad.media,
        materiaId: 4,
        estudianteId: sofiaId,
        estado: Estado.completada,
        fechaCompletada: _enDias(-1, 18, 30),
      ),
      Tarea(
        id: _siguienteId++,
        nombre: 'Maqueta de célula animal',
        descripcion: 'Maqueta con las partes principales de la célula, rotuladas.',
        fechaEntrega: _enDias(-3, 12, 0),
        prioridad: Prioridad.baja,
        materiaId: 5,
        estudianteId: sofiaId,
        estado: Estado.completada,
        fechaCompletada: _enDias(-3, 9, 15),
      ),
      Tarea(
        id: _siguienteId++,
        nombre: 'Investigación de vectores',
        descripcion: 'Investigar operaciones con vectores y entregar un resumen de dos páginas.',
        fechaEntrega: _enDias(-9, 12, 0),
        prioridad: Prioridad.alta,
        materiaId: 6,
        estudianteId: sofiaId,
        estado: Estado.completada,
        fechaCompletada: _enDias(-9, 11, 0),
      ),
    ]);
  }

  /// Tareas de un estudiante. Pendientes por fecha de entrega (la más próxima
  /// primero) y completadas de la más reciente a la más antigua.
  List<Tarea> tareasDe(int estudianteId, {Estado? estado}) {
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

  Tarea? porId(int id) {
    for (final t in _tareas) {
      if (t.id == id) return t;
    }
    return null;
  }

  int contarPorEstado(int estudianteId, Estado estado) {
    return _tareas
        .where((t) => t.estudianteId == estudianteId && t.estado == estado)
        .length;
  }

  /// XP total: puntos por cada tarea completada.
  int xpDe(int estudianteId) {
    return contarPorEstado(estudianteId, Estado.completada) * xpPorTarea;
  }

  /// Tareas completadas en los últimos 7 días (para el banner de progreso).
  int completadasEnLaSemana(int estudianteId) {
    final limite = DateTime.now().subtract(const Duration(days: 7));
    return _tareas
        .where((t) =>
            t.estudianteId == estudianteId &&
            t.estado == Estado.completada &&
            t.fechaCompletada != null &&
            t.fechaCompletada!.isAfter(limite))
        .length;
  }

  void agregar({
    required String nombre,
    required String descripcion,
    required DateTime fechaEntrega,
    required Prioridad prioridad,
    required int materiaId,
    required int estudianteId,
  }) {
    _tareas.add(Tarea(
      id: _siguienteId++,
      nombre: nombre.trim(),
      descripcion: descripcion.trim(),
      fechaEntrega: fechaEntrega,
      prioridad: prioridad,
      materiaId: materiaId,
      estudianteId: estudianteId,
    ));
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
    final anterior = _tareas[i];
    _tareas[i] = Tarea(
      id: id,
      nombre: nombre.trim(),
      descripcion: descripcion.trim(),
      fechaEntrega: fechaEntrega,
      prioridad: prioridad,
      materiaId: materiaId,
      estudianteId: anterior.estudianteId,
      estado: anterior.estado,
      fechaCompletada: anterior.fechaCompletada,
    );
    notifyListeners();
  }

  void completar(int id) {
    final tarea = porId(id);
    if (tarea == null || tarea.estado == Estado.completada) return;
    tarea.estado = Estado.completada;
    tarea.fechaCompletada = DateTime.now();
    notifyListeners();
  }

  /// Borra todas las tareas de un estudiante (al eliminar su cuenta).
  void eliminarDeEstudiante(int estudianteId) {
    _tareas.removeWhere((t) => t.estudianteId == estudianteId);
    notifyListeners();
  }

  void eliminar(int id) {
    _tareas.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
