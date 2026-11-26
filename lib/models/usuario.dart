import 'enums.dart';

export 'enums.dart';

/// Perfil de un usuario. La cuenta (correo y contraseña) la maneja Firebase
/// Authentication; aquí solo vive lo que guardamos en Firestore, en el
/// documento `usuarios/{id}`, donde `id` es el uid que asigna Firebase.
/// La contraseña ya NO se guarda en la app ni en la base de datos.
class Usuario {
  final String id;
  final String nombre;
  final String correo;
  final Rol rol;

  /// Cómo accede a la cuenta: 'correo' (con contraseña), 'google' o 'apple'.
  final String proveedor;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.proveedor = 'correo',
  });

  /// Las cuentas de acceso local entran con correo y contraseña.
  bool get accesoLocal => proveedor == 'correo';

  Usuario copyWith({String? nombre, String? correo}) {
    return Usuario(
      id: id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      rol: rol,
      proveedor: proveedor,
    );
  }

  /// Lee el documento de Firestore. Si el rol guardado no es válido, se trata
  /// como estudiante (el rol con menos permisos que puede usar la app).
  factory Usuario.desdeMapa(String id, Map<String, dynamic> datos) {
    final rolTexto = datos['rol'] as String? ?? '';
    final rol = Rol.values.firstWhere(
      (r) => r.name == rolTexto,
      orElse: () => Rol.estudiante,
    );
    return Usuario(
      id: id,
      nombre: datos['nombre'] as String? ?? '',
      correo: datos['correo'] as String? ?? '',
      rol: rol,
      proveedor: datos['proveedor'] as String? ?? 'correo',
    );
  }

  /// Datos que se guardan en Firestore (el id es el nombre del documento).
  Map<String, dynamic> aMapa() => {
        'nombre': nombre,
        'correo': correo,
        'rol': rol.name,
        'proveedor': proveedor,
      };
}
