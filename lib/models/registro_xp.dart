import 'package:cloud_firestore/cloud_firestore.dart';

import 'enums.dart';

/// Puntos de experiencia que ganó un estudiante al completar una tarea.
/// Se guarda en Firestore en `usuarios/{estudianteId}/xp/{tareaId}`: el id
/// del documento es el de la tarea, así cada tarea da XP una sola vez.
///
/// Como el XP queda guardado, borrar la tarea después ya no lo quita. Si la
/// tarea se regresa a pendiente ("Deshacer"), el registro se borra.
class RegistroXP {
  final String tareaId;
  final int puntos;

  /// 'a_tiempo', 'tarde' o 'muy_rapido' (anti-trampa: 0 puntos).
  final String motivo;

  final Prioridad prioridad;
  final String materiaId;
  final String tareaNombre;
  final DateTime fecha;

  const RegistroXP({
    required this.tareaId,
    required this.puntos,
    required this.motivo,
    required this.prioridad,
    required this.materiaId,
    required this.tareaNombre,
    required this.fecha,
  });

  bool get aTiempo => motivo == 'a_tiempo';

  factory RegistroXP.desdeMapa(String tareaId, Map<String, dynamic> datos) {
    final fecha = datos['fecha'];
    return RegistroXP(
      tareaId: tareaId,
      puntos: (datos['puntos'] as num?)?.toInt() ?? 0,
      motivo: datos['motivo'] as String? ?? 'a_tiempo',
      prioridad: Prioridad.values.firstWhere(
        (p) => p.name == datos['prioridad'],
        orElse: () => Prioridad.media,
      ),
      materiaId: datos['materiaId'] as String? ?? '',
      tareaNombre: datos['tareaNombre'] as String? ?? '',
      fecha: fecha is Timestamp ? fecha.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> aMapa() => {
        'puntos': puntos,
        'motivo': motivo,
        'prioridad': prioridad.name,
        'materiaId': materiaId,
        'tareaNombre': tareaNombre,
        'fecha': Timestamp.fromDate(fecha),
      };
}
