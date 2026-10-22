import 'package:flutter/material.dart';

import '../models/tarea.dart'; // aquí viven (vía export) los enums Prioridad y Estado

class AppColors {
  static const fondo = Color(0xFFFAF9F5);
  static const verde = Color(0xFF758B75);
  static const verdeClaro = Color(0xFFECF0EB);
  static const texto = Color(0xFF2D2D2A);
  static const textoSuave = Color(0xFF6B6B66);
  static const textoTenue = Color(0xFF9A9992);
  static const borde = Color(0xFFE4E2DC);
  static const peligro = Color(0xFFC0807A);
  static const prioridadAlta = Color(0xFFC0807A);
  static const prioridadMedia = Color(0xFFD4B483);
  static const prioridadBaja = Color(0xFF8FA68A);

  static Color paraPrioridad(Prioridad p) {
    switch (p) {
      case Prioridad.alta:
        return prioridadAlta;
      case Prioridad.media:
        return prioridadMedia;
      case Prioridad.baja:
        return prioridadBaja;
    }
  }
}

class AppSpacing {
  static const double pantalla = 24; // margen lateral de toda pantalla
  static const double entreTarjetas = 16;
  static const double interiorTarjeta = 20;
  static const double entreSecciones = 24;
}

class AppRadius {
  static const double tarjeta = 20;
  static const double campo = 16;
  static const double boton = 28;
}

class AppText {
  static const tituloPantalla = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.texto,
  );
  static const tituloSeccion = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.texto,
  );
  static const tituloTarjeta = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.texto,
  );
  static const etiquetaMateria = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: AppColors.verde,
  );
  static const cuerpo = TextStyle(fontSize: 16, color: AppColors.textoSuave);
  static const pequeno = TextStyle(fontSize: 13, color: AppColors.textoSuave);
  static const labelCampo = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.texto,
  );
  static const boton = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
}

class AppDecor {
  // Tarjeta blanca con borde fino y sombra casi imperceptible
  static BoxDecoration tarjeta() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
        border: Border.all(color: AppColors.borde),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );

  static InputDecoration campo({
    required String hint,
    IconData? icono,
    Widget? sufijo,
  }) {
    OutlineInputBorder borde(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.campo),
          borderSide: BorderSide(color: c),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textoSuave),
      prefixIcon:
          icono == null ? null : Icon(icono, color: AppColors.textoSuave),
      suffixIcon: sufijo,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: borde(AppColors.borde),
      focusedBorder: borde(AppColors.verde),
      errorBorder: borde(AppColors.peligro),
      focusedErrorBorder: borde(AppColors.peligro),
    );
  }

  // Botón principal: verde, 56 de alto, totalmente redondeado
  static ButtonStyle botonPrimario() => ElevatedButton.styleFrom(
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.boton),
        ),
      );

  // Botón secundario: fondo blanco, borde fino, 52 de alto
  static ButtonStyle botonSecundario({Color color = AppColors.texto}) =>
      OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: AppColors.borde),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.campo),
        ),
      );
}
