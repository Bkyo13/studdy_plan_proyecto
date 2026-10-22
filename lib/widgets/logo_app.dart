import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Logo de StudyPlan: libro abierto sobre un cuadro redondeado verde claro.
class LogoApp extends StatelessWidget {
  final double tamano;

  const LogoApp({super.key, this.tamano = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        color: AppColors.verdeClaro,
        borderRadius: BorderRadius.circular(tamano * 0.3),
      ),
      child: Icon(
        Icons.menu_book_outlined,
        color: AppColors.verde,
        size: tamano * 0.5,
      ),
    );
  }
}
