import 'package:flutter/foundation.dart';

import '../models/usuario.dart';

/// Maneja la sesión y los usuarios (en memoria, solo para la demo).
class AuthProvider extends ChangeNotifier {
  final List<Usuario> _usuarios = [
    const Usuario(
      id: 1,
      nombre: 'Sofía',
      correo: 'sofia@demo.com',
      contrasena: '123456',
      rol: Rol.estudiante,
    ),
    const Usuario(
      id: 2,
      nombre: 'Carolina Herrera',
      correo: 'tutor@demo.com',
      contrasena: '123456',
      rol: Rol.tutor,
    ),
    const Usuario(
      id: 3,
      nombre: 'ADMIN',
      correo: 'admin@demo.com',
      contrasena: '123456',
      rol: Rol.administrador,
    ),
  ];

  Usuario? _usuarioActual;
  int _siguienteId = 4;

  Usuario? get usuarioActual => _usuarioActual;

  List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  /// Devuelve null si todo salió bien, o el mensaje de error.
  String? iniciarSesion(String correo, String contrasena) {
    final buscado = correo.trim().toLowerCase();
    for (final u in _usuarios) {
      if (u.correo.toLowerCase() == buscado) {
        if (u.contrasena != contrasena) {
          return 'Contraseña incorrecta';
        }
        _usuarioActual = u;
        notifyListeners();
        return null;
      }
    }
    return 'No existe una cuenta con ese correo';
  }

  /// Crea la cuenta e inicia sesión. Devuelve null si salió bien.
  String? registrar({
    required String nombre,
    required String correo,
    required String contrasena,
    required Rol rol,
  }) {
    final correoLimpio = correo.trim().toLowerCase();
    final existe = _usuarios.any((u) => u.correo.toLowerCase() == correoLimpio);
    if (existe) {
      return 'Ya existe una cuenta con ese correo';
    }
    final nuevo = Usuario(
      id: _siguienteId++,
      nombre: nombre.trim(),
      correo: correoLimpio,
      contrasena: contrasena,
      rol: rol,
    );
    _usuarios.add(nuevo);
    _usuarioActual = nuevo;
    notifyListeners();
    return null;
  }

  void cerrarSesion() {
    _usuarioActual = null;
    notifyListeners();
  }

  /// Lo usa el tutor para vincular a un estudiante por correo.
  Usuario? buscarEstudiantePorCorreo(String correo) {
    final buscado = correo.trim().toLowerCase();
    for (final u in _usuarios) {
      if (u.rol == Rol.estudiante && u.correo.toLowerCase() == buscado) {
        return u;
      }
    }
    return null;
  }
}
