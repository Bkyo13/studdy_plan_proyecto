import 'package:flutter/material.dart';

/// Medidas comunes para las animaciones de la app, para que todas se sientan
/// iguales: cortas, suaves y sin rebotes.
class Animaciones {
  /// Cambios pequeños (un chip, un ícono, un color).
  static const rapida = Duration(milliseconds: 150);

  /// Cambios de contenido (pestañas, tarjetas que aparecen).
  static const normal = Duration(milliseconds: 220);

  /// Curva principal: arranca rápido y frena suave al final.
  static const curva = Curves.easeOutCubic;

  /// Duración que respeta la opción "Reducir movimiento" del teléfono:
  /// si el usuario la activó, la animación es instantánea.
  static Duration duracion(BuildContext context, Duration normal) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : normal;
  }
}
