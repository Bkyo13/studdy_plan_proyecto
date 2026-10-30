import 'enums.dart';

export 'enums.dart';

class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String contrasena;
  final Rol rol;

  /// Cómo accede a la cuenta: 'correo' (acceso local, con contraseña),
  /// 'google' o 'apple'. Hoy todas las cuentas son de acceso local.
  final String proveedor;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.rol,
    this.proveedor = 'correo',
  });

  /// Las cuentas de acceso local entran con correo y contraseña.
  bool get accesoLocal => proveedor == 'correo';

  Usuario copyWith({String? nombre, String? correo, String? contrasena}) {
    return Usuario(
      id: id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      contrasena: contrasena ?? this.contrasena,
      rol: rol,
      proveedor: proveedor,
    );
  }
}
