import 'enums.dart';

export 'enums.dart';

class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String contrasena;
  final Rol rol;

  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.contrasena,
    required this.rol,
  });
}
