import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario.dart';

/// Sesión, cuentas y perfiles, con Firebase.
///
/// - Firebase Authentication guarda las cuentas y las contraseñas (cifradas)
///   y mantiene la sesión con su propio token (ID token), que se renueva solo.
/// - Firestore guarda el perfil de cada usuario en `usuarios/{uid}`:
///   nombre, correo, rol y proveedor.
///
/// Al abrir la app, [restaurarSesion] verifica que exista una sesión y que su
/// token siga siendo válido para Firebase (la cuenta existe y no está
/// desactivada).
class AuthProvider extends ChangeNotifier {
  /// Mensajes de consola solo mientras se desarrolla (flutter run).
  static void _log(String mensaje) {
    if (kDebugMode) debugPrint(mensaje);
  }

  /// Si el usuario desmarcó "Recordarme", la próxima vez que abra la app se
  /// cierra la sesión y se muestra el login.
  static const _claveRecordar = 'recordar_sesion';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _coleccion =
      FirebaseFirestore.instance.collection('usuarios');

  Usuario? _usuarioActual;
  bool _sesionRecordada = true;
  List<Usuario> _usuarios = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subUsuarios;

  Usuario? get usuarioActual => _usuarioActual;

  /// Si la sesión se mantiene al cerrar y volver a abrir la app.
  bool get sesionRecordada => _sesionRecordada;

  /// Usuarios registrados (se actualiza en tiempo real mientras hay sesión).
  /// Lo usan el panel del admin (totales) y el tutor (buscar y ver nombres).
  List<Usuario> get usuarios => List.unmodifiable(_usuarios);

  @override
  void dispose() {
    _subUsuarios?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Sesión
  // ---------------------------------------------------------------------

  /// Verifica si hay una sesión activa y válida. Devuelve true si se pudo
  /// entrar directo (sin pasar por el login).
  Future<bool> restaurarSesion() async {
    try {
      // Firebase recupera la sesión guardada en el teléfono; el primer valor
      // del stream es el usuario restaurado (o null si no había).
      final usuarioFirebase = await _auth.authStateChanges().first;
      if (usuarioFirebase == null) {
        _log('[Sesion] No hay sesión guardada: se mostrará el login.');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      _sesionRecordada = prefs.getBool(_claveRecordar) ?? true;
      if (!_sesionRecordada) {
        _log('[Sesion] El usuario no pidió recordar la sesión: se cierra.');
        await _auth.signOut();
        return false;
      }

      // Pide a Firebase un token nuevo: si la cuenta se borró o se
      // desactivó, falla y se cierra la sesión. Sin internet se sigue con la
      // sesión guardada (Firestore funciona sin conexión con su caché).
      try {
        await usuarioFirebase.getIdToken(true);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'network-request-failed') {
          _log('[Sesion] Token rechazado por Firebase (${e.code}): se cierra.');
          await _auth.signOut();
          return false;
        }
        _log('[Sesion] Sin conexión: se usa la sesión guardada.');
      }

      final ok = await _cargarPerfil(usuarioFirebase);
      if (!ok) {
        _log('[Sesion] La cuenta no tiene perfil en Firestore: se cierra.');
        await _auth.signOut();
        return false;
      }
      _log('[Sesion] Token de Firebase válido para el usuario '
          '${usuarioFirebase.uid.substring(0, 6)}… (rol: ${_usuarioActual!.rol.name}).');
      return true;
    } catch (e) {
      _log('[Sesion] Error al verificar la sesión: $e');
      return false;
    }
  }

  /// Lee el perfil de Firestore y empieza a escuchar la lista de usuarios.
  Future<bool> _cargarPerfil(User usuarioFirebase) async {
    final doc = await _coleccion.doc(usuarioFirebase.uid).get();
    final datos = doc.data();
    if (datos == null) return false;

    var usuario = Usuario.desdeMapa(doc.id, datos);
    // Si cambió su correo (confirmó el enlace de verificación), se actualiza
    // también en el perfil.
    final correoReal = usuarioFirebase.email?.toLowerCase();
    if (correoReal != null && correoReal != usuario.correo) {
      usuario = usuario.copyWith(correo: correoReal);
      await _coleccion.doc(usuario.id).update({'correo': correoReal});
    }

    _usuarioActual = usuario;
    _escucharUsuarios();
    notifyListeners();
    return true;
  }

  void _escucharUsuarios() {
    _subUsuarios?.cancel();
    _subUsuarios = _coleccion.snapshots().listen(
      (snap) {
        _usuarios = snap.docs
            .map((d) => Usuario.desdeMapa(d.id, d.data()))
            .toList();
        // Mantiene al día el perfil propio (por ejemplo, si el admin le
        // cambia algo desde la consola).
        final actual = _usuarioActual;
        if (actual != null) {
          for (final u in _usuarios) {
            if (u.id == actual.id) _usuarioActual = u;
          }
        }
        notifyListeners();
      },
      onError: (Object e) => _log('[Usuarios] No se pudo leer la lista: $e'),
    );
  }

  Future<void> cambiarRecordarSesion(bool recordar) async {
    _sesionRecordada = recordar;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_claveRecordar, recordar);
    } catch (e) {
      _log('[Sesion] No se pudo guardar la preferencia: $e');
    }
  }

  /// Devuelve null si entró, o el mensaje de error para mostrar.
  Future<String?> iniciarSesion(
    String correo,
    String contrasena, {
    bool recordarme = true,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: correo.trim().toLowerCase(),
        password: contrasena,
      );
      final ok = await _cargarPerfil(cred.user!);
      if (!ok) {
        await _auth.signOut();
        return 'No se encontró el perfil de esta cuenta';
      }
      await cambiarRecordarSesion(recordarme);
      _log('[Sesion] Inicio de sesión correcto (recordar: $recordarme).');
      return null;
    } on FirebaseAuthException catch (e) {
      _log('[Sesion] Error al iniciar sesión: ${e.code}');
      return _mensajeDeError(e.code);
    } catch (e) {
      _log('[Sesion] Error al iniciar sesión: $e');
      return 'No se pudo iniciar sesión. Intenta de nuevo.';
    }
  }

  /// Crea la cuenta en Firebase y su perfil en Firestore, y deja la sesión
  /// abierta. Devuelve null si se creó, o el mensaje de error.
  Future<String?> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
    required Rol rol,
  }) async {
    // El rol de administrador no se puede elegir desde la app: se asigna a
    // mano en la consola de Firebase (y las reglas de Firestore lo impiden).
    if (rol == Rol.administrador) {
      return 'Ese tipo de cuenta no se puede crear desde la app';
    }
    User? nuevo;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: correo.trim().toLowerCase(),
        password: contrasena,
      );
      nuevo = cred.user!;
      await nuevo.updateDisplayName(nombre.trim());
      final usuario = Usuario(
        id: nuevo.uid,
        nombre: nombre.trim(),
        correo: correo.trim().toLowerCase(),
        rol: rol,
      );
      await _coleccion.doc(usuario.id).set({
        ...usuario.aMapa(),
        'fechaRegistro': FieldValue.serverTimestamp(),
      });
      _usuarioActual = usuario;
      _escucharUsuarios();
      await cambiarRecordarSesion(true);
      _log('[Cuenta] Cuenta creada (rol: ${rol.name}).');
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _log('[Cuenta] Error al registrar: ${e.code}');
      return _mensajeDeError(e.code);
    } catch (e) {
      // Si se creó la cuenta pero falló el perfil, se borra la cuenta para
      // no dejarla a medias.
      _log('[Cuenta] Error al guardar el perfil: $e');
      try {
        await nuevo?.delete();
      } catch (_) {}
      return 'No se pudo crear la cuenta. Revisa tu conexión e intenta de nuevo.';
    }
  }

  Future<void> cerrarSesion() async {
    await _subUsuarios?.cancel();
    _subUsuarios = null;
    _usuarioActual = null;
    _usuarios = [];
    notifyListeners();
    try {
      await _auth.signOut();
      _log('[Sesion] Sesión cerrada.');
    } catch (e) {
      _log('[Sesion] Error al cerrar sesión: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Perfil
  // ---------------------------------------------------------------------

  /// Confirma la contraseña con Firebase (reautenticación). Firebase la pide
  /// antes de acciones delicadas, como cambiar la contraseña o borrar la cuenta.
  Future<bool> contrasenaCorrecta(String contrasena) async {
    final u = _auth.currentUser;
    final correo = u?.email;
    if (u == null || correo == null) return false;
    try {
      await u.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: correo, password: contrasena),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _log('[Cuenta] Reautenticación fallida: ${e.code}');
      return false;
    }
  }

  /// Cambia el nombre y/o el correo. El correo nuevo no se cambia de
  /// inmediato: Firebase manda un enlace al correo nuevo y el cambio se
  /// aplica cuando el usuario lo abre. Devuelve null si todo salió bien.
  Future<String?> actualizarPerfil({
    required String nombre,
    required String correo,
  }) async {
    final actual = _usuarioActual;
    final u = _auth.currentUser;
    if (actual == null || u == null) return 'No hay una sesión activa';

    final nuevoNombre = nombre.trim();
    final nuevoCorreo = correo.trim().toLowerCase();
    try {
      if (nuevoNombre != actual.nombre) {
        await _coleccion.doc(actual.id).update({'nombre': nuevoNombre});
        await u.updateDisplayName(nuevoNombre);
        _usuarioActual = actual.copyWith(nombre: nuevoNombre);
        notifyListeners();
      }
      if (nuevoCorreo != actual.correo) {
        await u.verifyBeforeUpdateEmail(nuevoCorreo);
        _log('[Cuenta] Enlace de verificación enviado al correo nuevo.');
      }
      return null;
    } on FirebaseAuthException catch (e) {
      _log('[Cuenta] Error al actualizar el perfil: ${e.code}');
      return _mensajeDeError(e.code);
    } catch (e) {
      _log('[Cuenta] Error al actualizar el perfil: $e');
      return 'No se pudo guardar. Revisa tu conexión.';
    }
  }

  /// Devuelve null si se cambió, o el mensaje de error.
  Future<String?> cambiarContrasena({
    required String actual,
    required String nueva,
  }) async {
    final u = _auth.currentUser;
    if (u == null) return 'No hay una sesión activa';
    if (!await contrasenaCorrecta(actual)) {
      return 'La contraseña actual no es correcta';
    }
    try {
      await u.updatePassword(nueva);
      _log('[Cuenta] Contraseña actualizada.');
      return null;
    } on FirebaseAuthException catch (e) {
      _log('[Cuenta] Error al cambiar la contraseña: ${e.code}');
      return _mensajeDeError(e.code);
    }
  }

  /// Borra el perfil y la cuenta. Antes hay que llamar a [contrasenaCorrecta]
  /// (Firebase exige un inicio de sesión reciente) y borrar los datos del
  /// estudiante en los otros providers. Devuelve null si se borró.
  Future<String?> eliminarCuenta() async {
    final u = _auth.currentUser;
    final actual = _usuarioActual;
    if (u == null || actual == null) return 'No hay una sesión activa';
    try {
      await _subUsuarios?.cancel();
      _subUsuarios = null;
      await _coleccion.doc(actual.id).delete();
      await u.delete();
      _usuarioActual = null;
      _usuarios = [];
      _log('[Cuenta] Cuenta eliminada.');
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      _log('[Cuenta] Error al eliminar la cuenta: ${e.code}');
      return _mensajeDeError(e.code);
    } catch (e) {
      _log('[Cuenta] Error al eliminar la cuenta: $e');
      return 'No se pudo eliminar la cuenta. Revisa tu conexión.';
    }
  }

  // ---------------------------------------------------------------------
  // Recuperación de contraseña
  // ---------------------------------------------------------------------

  /// Firebase manda un correo con un enlace para crear una contraseña nueva.
  /// Si el correo no tiene cuenta no se avisa (para no revelar qué correos
  /// están registrados); solo se devuelve error si algo falló de verdad.
  Future<String?> solicitarRecuperacion(String correo) async {
    try {
      await _auth.sendPasswordResetEmail(email: correo.trim().toLowerCase());
      _log('[Recuperacion] Correo de recuperación solicitado.');
      return null;
    } on FirebaseAuthException catch (e) {
      _log('[Recuperacion] ${e.code}');
      if (e.code == 'user-not-found') return null;
      return _mensajeDeError(e.code);
    }
  }

  // ---------------------------------------------------------------------
  // Consultas
  // ---------------------------------------------------------------------

  Usuario? porId(String id) {
    for (final u in _usuarios) {
      if (u.id == id) return u;
    }
    if (_usuarioActual?.id == id) return _usuarioActual;
    return null;
  }

  Usuario? buscarEstudiantePorCorreo(String correo) {
    final buscado = correo.trim().toLowerCase();
    for (final u in _usuarios) {
      if (u.rol == Rol.estudiante && u.correo.toLowerCase() == buscado) {
        return u;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Mensajes de error de Firebase en español
  // ---------------------------------------------------------------------

  static String _mensajeDeError(String codigo) {
    switch (codigo) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-email':
        return 'Correo o contraseña incorrectos';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo';
      case 'weak-password':
        return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
      case 'user-disabled':
        return 'Esta cuenta está desactivada';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e intenta de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Revisa tu red e intenta de nuevo.';
      case 'requires-recent-login':
        return 'Por seguridad, cierra sesión y vuelve a entrar para hacer este cambio.';
      default:
        return 'Ocurrió un error ($codigo). Intenta de nuevo.';
    }
  }
}
