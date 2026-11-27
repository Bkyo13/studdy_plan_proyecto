/// Relación tutor → estudiante. El tutor la crea como solicitud
/// ('pendiente') y solo cuenta cuando el estudiante la acepta ('aceptado').
class Vinculo {
  static const pendiente = 'pendiente';
  static const aceptado = 'aceptado';

  final String tutorId;
  final String estudianteId;
  final String estado;

  const Vinculo({
    required this.tutorId,
    required this.estudianteId,
    this.estado = pendiente,
  });

  bool get esAceptado => estado == aceptado;
  bool get esPendiente => estado == pendiente;

  /// Los vínculos creados antes de que existieran las solicitudes no traen
  /// 'estado': se toman como aceptados para no desvincular a nadie.
  factory Vinculo.desdeMapa(String tutorId, Map<String, dynamic> datos) {
    return Vinculo(
      tutorId: tutorId,
      estudianteId: datos['estudianteId'] as String? ?? '',
      estado: datos['estado'] as String? ?? aceptado,
    );
  }
}
