/// Código temporal para restablecer la contraseña de un usuario.
class TokenRecuperacion {
  final int id;
  final String token; // código de 6 dígitos
  final int usuarioId;
  final DateTime fechaExpiracion;
  bool usado;

  TokenRecuperacion({
    required this.id,
    required this.token,
    required this.usuarioId,
    required this.fechaExpiracion,
    this.usado = false,
  });

  /// Sirve si todavía no se usó y no ha llegado su fecha de expiración.
  bool get vigente => !usado && DateTime.now().isBefore(fechaExpiracion);
}