import 'package:flutter/material.dart';

import '../models/nivel.dart';
import '../providers/tarea_provider.dart';
import '../theme/app_theme.dart';
import '../utils/animaciones.dart';

/// Tarjeta con el nivel actual y la barra hacia el siguiente:
/// "Nivel 3 · Constante — te faltan 45 XP para Organizado (unas 3 tareas)".
class TarjetaNivel extends StatelessWidget {
  final int xp;

  /// Para la vista del tutor: el texto habla en tercera persona.
  final bool deOtro;

  const TarjetaNivel({super.key, required this.xp, this.deOtro = false});

  @override
  Widget build(BuildContext context) {
    final nivel = Nivel.de(xp);
    final sig = nivel.siguiente;
    final faltan = nivel.faltan(xp);
    final tareas = (faltan / TareaProvider.xpTareaTipica).ceil();

    final String detalle;
    if (sig == null) {
      detalle = deOtro
          ? 'Llegó al nivel más alto.'
          : 'Llegaste al nivel más alto. ¡Excelente constancia!';
    } else {
      final unas = tareas == 1 ? 'una tarea' : 'unas $tareas tareas';
      detalle = deOtro
          ? 'Le faltan $faltan XP para ${sig.nombre} ($unas).'
          : 'Te faltan $faltan XP para ${sig.nombre} ($unas).';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppDecor.tarjeta(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.verdeClaro,
            child: Text(
              '${nivel.numero}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.verde,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nivel ${nivel.numero} · ${nivel.nombre}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.texto,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: nivel.avance(xp)),
                    duration: Animaciones.duracion(
                      context,
                      const Duration(milliseconds: 500),
                    ),
                    curve: Animaciones.curva,
                    builder: (context, valor, child) => LinearProgressIndicator(
                      value: valor,
                      minHeight: 6,
                      backgroundColor: AppColors.verdeClaro,
                      color: AppColors.verde,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(detalle, style: AppText.pequeno),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
