import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botón circular blanco de 44x44 con borde fino (atrás, editar, cerrar sesión...).
class BotonCircular extends StatelessWidget {
  final IconData icono;
  final VoidCallback onPressed;

  const BotonCircular({super.key, required this.icono, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.borde)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icono, size: 18, color: AppColors.texto),
        ),
      ),
    );
  }
}
