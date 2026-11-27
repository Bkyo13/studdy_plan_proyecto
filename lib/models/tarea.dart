import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';
import 'subtarea.dart';

export 'enums.dart';
export 'subtarea.dart';

class Tarea {
  final String id;
  final String nombre;
  final String descripcion;
  final DateTime fechaEntrega;
  final Prioridad prioridad;
  final String materiaId;
  final String estudianteId;
  Estado estado;
  DateTime? fechaCompletada;

  /// Cuándo se creó (para el anti-trampa del XP). Las tareas creadas antes
  /// de este cambio no la tienen.
  final DateTime? fechaCreacion;

  /// Pasos de la tarea (checklist). Puede estar vacía.
  List<Subtarea> subtareas;

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
    this.fechaCreacion,
    this.subtareas = const [],
  });

  int get subtareasHechas => subtareas.where((s) => s.hecha).length;

  /// Avance de los pasos, de 0 a 1 (0 si no tiene pasos).
  double get avanceSubtareas =>
      subtareas.isEmpty ? 0 : subtareasHechas / subtareas.length;

  /// Sigue pendiente y ya pasó su fecha y hora de entrega.
  bool get vencida =>
      estado == Estado.pendiente && fechaEntrega.isBefore(DateTime.now());

  /// Lee un documento de Firestore (`tareas/{id}`).
  factory Tarea.desdeMapa(String id, Map<String, dynamic> datos) {
    DateTime? fecha(Object? valor) =>
        valor is Timestamp ? valor.toDate() : null;
    return Tarea(
      id: id,
      nombre: datos['nombre'] as String? ?? '',
      descripcion: datos['descripcion'] as String? ?? '',
      fechaEntrega: fecha(datos['fechaEntrega']) ?? DateTime.now(),
      prioridad: Prioridad.values.firstWhere(
        (p) => p.name == datos['prioridad'],
        orElse: () => Prioridad.media,
      ),
      materiaId: datos['materiaId'] as String? ?? '',
      estudianteId: datos['estudianteId'] as String? ?? '',
      estado: datos['estado'] == Estado.completada.name
          ? Estado.completada
          : Estado.pendiente,
      fechaCompletada: fecha(datos['fechaCompletada']),
      fechaCreacion: fecha(datos['fechaCreacion']),
      subtareas: (datos['subtareas'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Subtarea.desdeMapa)
          .toList(),
    );
  }

  /// Datos que se guardan en Firestore (el id es el nombre del documento).
  Map<String, dynamic> aMapa() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'fechaEntrega': Timestamp.fromDate(fechaEntrega),
        'prioridad': prioridad.name,
        'materiaId': materiaId,
        'estudianteId': estudianteId,
        'estado': estado.name,
        'fechaCompletada':
            fechaCompletada == null ? null : Timestamp.fromDate(fechaCompletada!),
        if (fechaCreacion != null)
          'fechaCreacion': Timestamp.fromDate(fechaCreacion!),
        'subtareas': subtareas.map((s) => s.aMapa()).toList(),
      };
}
