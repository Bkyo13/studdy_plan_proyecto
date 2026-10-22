import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Avatar con la inicial. Al tocarlo ofrece cerrar sesión.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({super.key, required this.nombre});

  final String nombre;

  Future<void> _confirmarCerrarSesion(BuildContext context) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (salir == true && context.mounted) {
      context.read<AuthProvider>().cerrarSesion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inicial = nombre.trim().isEmpty ? '?' : nombre.trim()[0].toUpperCase();
    return GestureDetector(
      onTap: () => _confirmarCerrarSesion(context),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: AppColors.verdeClaro,
        child: Text(
          inicial,
          style: const TextStyle(
            color: AppColors.verde,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}