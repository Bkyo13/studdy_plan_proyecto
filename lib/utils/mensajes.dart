import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Muestra un SnackBar verde (éxito) o rojizo (error).
void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(texto, style: const TextStyle(color: Colors.white)),
      backgroundColor: error ? AppColors.peligro : AppColors.verde,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.campo),
      ),
    ),
  );
}
