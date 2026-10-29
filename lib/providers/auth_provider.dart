import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sesion.dart';
import '../models/token_recuperacion.dart';
import '../models/usuario.dart';

/// Maneja la sesión y los usuarios (en memoria, solo para la demo).
///
/// La sesión se identifica con un token que se guarda en el dispositivo
/// (shared_preferences). Al abrir la app se verifica que el token exista, que
/// no haya vencido y que pertenezca a un usuario existente.
class AuthProvider extends ChangeNotifier {
  static const _claveToken = 'sesion_token';
  static const _claveUsuario = 'sesion_usuario_id';
  static const _claveCreada = 'sesion_creada';
  static const _claveExpira = 'sesion_expira';
  static const _duracionSesion = Duration(days: 7);

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
      nombre: 'Carmen Torres',
      correo: 'tutor@demo.com',
      contrasena: '123456',
      rol: Rol.tutor,
    ),
    const Usuario(
      id: 3,
      nombre: 'Administrador',
      correo: 'admin@demo.com',
      contrasena: '123456',
      rol: Rol.administrador,
    ),
  ];

  Usuario? _usuarioActual;
  Sesion? _sesion;
  int _siguienteId = 4;

  // Recuperación de contraseña
  static const _duracionCodigo = Duration(minutes: 10);
  final List<TokenRecuperacion> _tokensRecuperacion = [];
  int _siguienteTokenId = 1;

  Usuario? get usuarioActual => _usuarioActual;

  /// Sesión activa (con su token), o null si no hay.
  Sesion? get sesion => _sesion;

  List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  // ---------------------------------------------------------------------
  // Token de sesión
  // ---------------------------------------------------------------------

  String _generarToken() {
    final azar = Random.secure();
    return List.generate(32, (_) => azar.nextInt(16).toRadixString(16)).join();
  }

  /// Verifica si existe una sesión activa y válida mediante el token guardado.
  /// Devuelve true (y deja al usuario con la sesión abierta) si es válida.
  Future<bool> restaurarSesion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_claveToken);
      final usuarioId = prefs.getInt(_claveUsuario);
      final creada = DateTime.tryParse(prefs.getString(_claveCreada) ?? '');
      final expira = DateTime.tryParse(prefs.getString(_claveExpira) ?? '');

      if (token == null || usuarioId == null || creada == null || expira == null) {
        debugPrint('[Sesion] No hay token guardado: se mostrará el login.');
        return false;
      }

      final sesion = Sesion(
        token: token,
        usuarioId: usuarioId,
        fechaCreacion: creada,
        fechaExpiracion: expira,
      );

      if (!sesion.vigente) {
        debugPrint('[Sesion] Token vencido (expiró el $expira): se borra y se muestra el login.');
        await _borrarSesionGuardada();
        return false;
      }

      final usuario = porId(usuarioId);
      if (usuario == null) {
        debugPrint('[Sesion] El token pertenece a un usuario que ya no existe: se borra.');
        await _borrarSesionGuardada();
        return false;
      }

      _sesion = sesion;
      _usuarioActual = usuario;
      notifyListeners();
      debugPrint(
        '[Sesion] Token válido (${token.substring(0, 8)}…) para ${usuario.correo}. '
        'Expira el $expira.',
      );
      return true;
    } catch (e) {
      debugPrint('[Sesion] Error al verificar el token: $e');
      return false;
    }
  }

  Future<void> _guardarSesion(Sesion sesion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_claveToken, sesion.token);
      await prefs.setInt(_claveUsuario, sesion.usuarioId);
      await prefs.setString(_claveCreada, sesion.fechaCreacion.toIso8601String());
      await prefs.setString(_claveExpira, sesion.fechaExpiracion.toIso8601String());
      debugPrint('[Sesion] Token guardado (${sesion.token.substring(0, 8)}…), '
          'expira el ${sesion.fechaExpiracion}.');
    } catch (e) {
      debugPrint('[Sesion] No se pudo guardar el token: $e');
    }
  }

  Future<void> _borrarSesionGuardada() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_claveToken);
      await prefs.remove(_claveUsuario);
      await prefs.remove(_claveCreada);
      await prefs.remove(_claveExpira);
    } catch (e) {
      debugPrint('[Sesion] No se pudo borrar el token: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Inicio de sesión, registro y cierre
  // ---------------------------------------------------------------------

  /// Devuelve null si todo salió bien, o el mensaje de error.
  /// Con [recordarme] el token se guarda para reabrir la sesión al volver.
  String? iniciarSesion(
    String correo,
    String contrasena, {
    bool recordarme = false,
  }) {
    final buscado = correo.trim().toLowerCase();
    for (final u in _usuarios) {
      if (u.correo.toLowerCase() == buscado) {
        if (u.contrasena != contrasena) {
          return 'Contraseña incorrecta';
        }
        _usuarioActual = u;
        final ahora = DateTime.now();
        _sesion = Sesion(
          token: _generarToken(),
          usuarioId: u.id,
          fechaCreacion: ahora,
          fechaExpiracion: ahora.add(_duracionSesion),
        );
        if (recordarme) {
          _guardarSesion(_sesion!);
        } else {
          _borrarSesionGuardada();
        }
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
    final ahora = DateTime.now();
    _sesion = Sesion(
      token: _generarToken(),
      usuarioId: nuevo.id,
      fechaCreacion: ahora,
      fechaExpiracion: ahora.add(_duracionSesion),
    );
    _borrarSesionGuardada();
    notifyListeners();
    return null;
  }

  void cerrarSesion() {
    _usuarioActual = null;
    _sesion = null;
    notifyListeners();
    _borrarSesionGuardada();
    debugPrint('[Sesion] Sesión cerrada y token eliminado.');
  }

  // ---------------------------------------------------------------------
  // Recuperación de contraseña
  // ---------------------------------------------------------------------

  Usuario? _buscarPorCorreo(String correo) {
    final buscado = correo.trim().toLowerCase();
    for (final u in _usuarios) {
      if (u.correo.toLowerCase() == buscado) return u;
    }
    return null;
  }

  /// Genera un código de 6 dígitos para la cuenta con ese correo y lo devuelve.
  /// Devuelve null si no existe una cuenta con ese correo.
  /// (En una app real el código se enviaría por correo; en esta demo se
  /// muestra en pantalla.)
  String? solicitarRecuperacion(String correo) {
    final usuario = _buscarPorCorreo(correo);
    if (usuario == null) {
      debugPrint('[Recuperacion] No existe una cuenta con el correo $correo.');
      return null;
    }
    // Los códigos anteriores de esa cuenta dejan de servir.
    for (final t in _tokensRecuperacion) {
      if (t.usuarioId == usuario.id) t.usado = true;
    }
    final codigo = (Random.secure().nextInt(900000) + 100000).toString();
    _tokensRecuperacion.add(
      TokenRecuperacion(
        id: _siguienteTokenId++,
        token: codigo,
        usuarioId: usuario.id,
        fechaExpiracion: DateTime.now().add(_duracionCodigo),
      ),
    );
    debugPrint('[Recuperacion] Código generado para ${usuario.correo}; vence en 10 minutos.');
    return codigo;
  }

  /// Cambia la contraseña si el código es correcto, no se ha usado y no ha
  /// vencido. Devuelve null si salió bien, o el mensaje de error.
  String? restablecerContrasena({
    required String correo,
    required String codigo,
    required String nuevaContrasena,
  }) {
    final usuario = _buscarPorCorreo(correo);
    if (usuario == null) {
      return 'No existe una cuenta con ese correo';
    }

    TokenRecuperacion? token;
    for (final t in _tokensRecuperacion) {
      if (t.usuarioId == usuario.id && t.token == codigo.trim()) {
        token = t;
      }
    }
    if (token == null) return 'El código no es correcto';
    if (token.usado) return 'Ese código ya no sirve. Solicita uno nuevo';
    if (!token.vigente) return 'El código venció. Solicita uno nuevo';

    final i = _usuarios.indexWhere((u) => u.id == usuario.id);
    final actualizado = Usuario(
      id: usuario.id,
      nombre: usuario.nombre,
      correo: usuario.correo,
      contrasena: nuevaContrasena,
      rol: usuario.rol,
    );
    _usuarios[i] = actualizado;
    if (_usuarioActual?.id == usuario.id) _usuarioActual = actualizado;
    token.usado = true;
    notifyListeners();
    debugPrint('[Recuperacion] Contraseña actualizada para ${usuario.correo}.');
    return null;
  }

  Usuario? porId(int id) {
    for (final u in _usuarios) {
      if (u.id == id) return u;
    }
    return null;
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