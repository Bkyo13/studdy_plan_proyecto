import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Muestra un SnackBar verde (éxito) o rojizo (error).
/// Con [accion] y [onAccion] agrega un botón, por ejemplo "Deshacer".
void mostrarMensaje(
  BuildContext context,
  String texto, {
  bool error = false,
  String? accion,
  VoidCallback? onAccion,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(texto, style: const TextStyle(color: Colors.white)),
      backgroundColor: error ? AppColors.peligro : AppColors.verde,
      action: (accion != null && onAccion != null)
          ? SnackBarAction(
              label: accion,
              textColor: Colors.white,
              onPressed: onAccion,
            )
          : null,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.campo),
      ),
    ),
  );
}
