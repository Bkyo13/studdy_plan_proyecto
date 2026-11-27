// Validadores reutilizables para los formularios de autenticación.

String? validarCorreo(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Escribe tu correo electrónico';
  final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto);
  if (!valido) return 'Escribe un correo válido';
  return null;
}

String? validarPassword(String? valor) {
  final texto = valor ?? '';
  if (texto.isEmpty) return 'Escribe tu contraseña';
  if (texto.length < 6) return 'Mínimo 6 caracteres';
  return null;
}

String? validarNombre(String? valor) {
  final texto = (valor ?? '').trim();
  if (texto.isEmpty) return 'Escribe tu nombre';
  if (texto.length < 3) return 'Mínimo 3 caracteres';
  return null;
}

/// Longitudes máximas de los campos de texto (las mismas del modelo de dominio).
class Limites {
  static const nombreUsuario = 50;
  static const correo = 100;
  static const contrasena = 60;
  static const nombreTarea = 100;
  static const descripcionTarea = 500;
  static const textoSubtarea = 80;
  static const subtareasPorTarea = 20;
  static const nombreMateria = 60;
  static const nombreLogro = 60;
  static const descripcionLogro = 150;
}
