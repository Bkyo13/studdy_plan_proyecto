import 'package:flutter/material.dart';

import '../models/logro.dart';
import '../theme/app_theme.dart';
import '../utils/formato_fecha.dart';

/// Tarjeta de un logro: obtenido (con fecha) o bloqueado (con su progreso).
class TarjetaLogro extends StatelessWidget {
  final Logro logro;
  final EstudianteLogro? obtenido;
  final int xpActual;
  final VoidCallback? onTap;

  const TarjetaLogro({
    super.key,
    required this.logro,
    required this.obtenido,
    required this.xpActual,
    this.onTap,
  });

  bool get _desbloqueado => obtenido != null;

  @override
  Widget build(BuildContext context) {
    final avance = _desbloqueado ? logro.xpRequerido : xpActual.clamp(0, logro.xpRequerido);
    final progreso = logro.xpRequerido == 0 ? 1.0 : avance / logro.xpRequerido;

    return Container(
      decoration: AppDecor.tarjeta(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.tarjeta),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _medalla(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        logro.nombre,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _desbloqueado ? AppColors.texto : AppColors.textoSuave,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(logro.descripcion, style: AppText.pequeno),
                      const SizedBox(height: 10),
                      Text(
                        'XP requerido: ${logro.xpRequerido}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.texto,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progreso.toDouble(),
                          minHeight: 8,
                          color: AppColors.verde,
                          backgroundColor: AppColors.borde,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$avance / ${logro.xpRequerido} XP', style: AppText.pequeno),
                          Flexible(
                            child: Text(
                              _desbloqueado
                                  ? 'Obtenido: ${formatoCompletado(obtenido!.fechaObtenido)}'
                                  : 'Bloqueado',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _desbloqueado ? AppColors.verde : AppColors.textoTenue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _medalla() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _desbloqueado ? AppColors.verdeClaro : AppColors.borde,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _desbloqueado ? Icons.emoji_events_outlined : Icons.lock_outline,
        color: _desbloqueado ? AppColors.verde : AppColors.textoTenue,
      ),
    );
  }
}
