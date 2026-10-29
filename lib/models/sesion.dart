/// Sesión abierta de un usuario, identificada por un token.
class Sesion {
  final String token;
  final int usuarioId;
  final DateTime fechaCreacion;
  final DateTime fechaExpiracion;

  const Sesion({
    required this.token,
    required this.usuarioId,
    required this.fechaCreacion,
    required this.fechaExpiracion,
  });

  /// La sesión sigue siendo válida mientras no llegue su fecha de expiración.
  bool get vigente => DateTime.now().isBefore(fechaExpiracion);
}