/// Logro del catálogo: se desbloquea al acumular cierta cantidad de XP.
class Logro {
  final int id;
  final String nombre;
  final String descripcion;
  final int xpRequerido;

  const Logro({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.xpRequerido,
  });
}

/// Registro de que un estudiante obtuvo un logro, y cuándo.
class EstudianteLogro {
  final int id;
  final int estudianteId;
  final int logroId;
  final DateTime fechaObtenido;

  const EstudianteLogro({
    required this.id,
    required this.estudianteId,
    required this.logroId,
    required this.fechaObtenido,
  });
}