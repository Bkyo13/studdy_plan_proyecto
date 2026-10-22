import 'enums.dart';

export 'enums.dart';

class Tarea {
  final int id;
  final String nombre;
  final String descripcion;
  final DateTime fechaEntrega;
  final Prioridad prioridad;
  final int materiaId;
  final int estudianteId;
  Estado estado;
  DateTime? fechaCompletada;

  Tarea({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaEntrega,
    required this.prioridad,
    required this.materiaId,
    required this.estudianteId,
    this.estado = Estado.pendiente,
    this.fechaCompletada,
  });
}
