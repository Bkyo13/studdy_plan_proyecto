import 'package:cloud_firestore/cloud_firestore.dart';

/// Logro del catálogo: se desbloquea al acumular cierta cantidad de XP.
/// Se guarda en Firestore en `logros/{id}`.
class Logro {
  final String id;
  final String nombre;
  final String descripcion;
  final int xpRequerido;

  const Logro({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.xpRequerido,
  });

  factory Logro.desdeMapa(String id, Map<String, dynamic> datos) {
    return Logro(
      id: id,
      nombre: datos['nombre'] as String? ?? '',
      descripcion: datos['descripcion'] as String? ?? '',
      xpRequerido: (datos['xpRequerido'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> aMapa() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'xpRequerido': xpRequerido,
      };
}

/// Registro de que un estudiante obtuvo un logro, y cuándo. Se guarda en
/// `usuarios/{estudianteId}/logros/{logroId}` (el id del documento es el del
/// logro, así no se puede obtener el mismo logro dos veces).
class EstudianteLogro {
  final String id;
  final String estudianteId;
  final String logroId;
  final DateTime fechaObtenido;

  const EstudianteLogro({
    required this.id,
    required this.estudianteId,
    required this.logroId,
    required this.fechaObtenido,
  });

  factory EstudianteLogro.desdeMapa(
    String estudianteId,
    String logroId,
    Map<String, dynamic> datos,
  ) {
    final fecha = datos['fechaObtenido'];
    return EstudianteLogro(
      id: logroId,
      estudianteId: estudianteId,
      logroId: logroId,
      fechaObtenido: fecha is Timestamp ? fecha.toDate() : DateTime.now(),
    );
  }
}
