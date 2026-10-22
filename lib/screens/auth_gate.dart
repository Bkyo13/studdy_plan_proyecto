import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_home.dart';
import 'estudiante/estudiante_home.dart';
import 'login_screen.dart';
import 'tutor/tutor_home.dart';

/// Enrutador por rol: sin sesión muestra el login; con sesión abre el
/// dashboard que le corresponde al usuario.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    if (usuario == null) {
      return const LoginScreen();
    }
    return switch (usuario.rol) {
      Rol.estudiante => const EstudianteHome(),
      Rol.tutor => const TutorHome(),
      Rol.administrador => const AdminHome(),
    };
  }
}
