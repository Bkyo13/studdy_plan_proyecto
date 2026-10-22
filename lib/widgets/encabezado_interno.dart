import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Botón circular de 44x44 con fondo blanco y borde fino.
class BotonCircular extends StatelessWidget {
  const BotonCircular({super.key, required this.icono, required this.onTap});

  final IconData icono;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: AppColors.borde)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icono, size: 18, color: AppColors.texto),
        ),
      ),
    );
  }
}

/// Encabezado de pantallas internas: botón atrás + título (+ acción opcional).
class EncabezadoInterno extends StatelessWidget {
  const EncabezadoInterno({
    super.key,
    required this.titulo,
    this.accion,
    this.centrado = false,
  });

  final String titulo;
  final Widget? accion;
  final bool centrado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pantalla,
        16,
        AppSpacing.pantalla,
        16,
      ),
      child: Row(
        children: [
          BotonCircular(
            icono: Icons.arrow_back_ios_new,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: centrado ? TextAlign.center : TextAlign.start,
              style: AppText.tituloSeccion,
            ),
          ),
          if (accion != null) ...[
            const SizedBox(width: 16),
            accion!,
          ] else if (centrado) ...[
            const SizedBox(width: 16),
            const SizedBox(width: 44, height: 44),
          ],
        ],
      ),
    );
  }
}