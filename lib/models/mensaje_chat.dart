/// Un mensaje del chat con el asistente de IA. Vive solo en memoria: la
/// conversación se borra al cerrar sesión o al tocar "Nueva conversación".
class MensajeChat {
  final String texto;

  /// true si lo escribió el estudiante; false si es respuesta del asistente.
  final bool deUsuario;

  /// true si es un aviso de error (no se manda a la IA como historial).
  final bool esError;

  final DateTime fecha;

  MensajeChat({
    required this.texto,
    required this.deUsuario,
    this.esError = false,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();
}
