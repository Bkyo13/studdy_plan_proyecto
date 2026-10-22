import 'package:flutter/material.dart';

/// Convierte '#RRGGBB' en Color. Si el texto no es válido, regresa el verde de la app.
Color colorDesdeHex(String hex) {
  final limpio = hex.replaceAll('#', '');
  final valor = int.tryParse('FF$limpio', radix: 16);
  return Color(valor ?? 0xFF758B75);
}
