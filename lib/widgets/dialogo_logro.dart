import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/logro.dart';
import '../theme/app_theme.dart';
import '../utils/animaciones.dart';

/// Aviso de logro(s) desbloqueado(s). Sobrio: la tarjeta aparece con un
/// fundido y crece un poco, y el trofeo entra un instante después. Sin
/// confeti ni brillos. Respeta "Reducir movimiento".
///
/// Se usa al completar una tarea (desde el detalle o al deslizar la tarjeta).
Future<void> mostrarLogrosDesbloqueados(
  BuildContext context,
  List<Logro> nuevos,
) {
  if (nuevos.isEmpty) return Future.value();
  HapticFeedback.mediumImpact();
  final duracion = Animaciones.duracion(
    context,
    const Duration(milliseconds: 260),
  );
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: duracion,
    pageBuilder: (ctx, _, _) => _DialogoLogro(nuevos: nuevos),
    transitionBuilder: (ctx, animacion, _, child) {
      final curva = CurvedAnimation(parent: animacion, curve: Animaciones.curva);
      return FadeTransition(
        opacity: curva,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curva),
          child: child,
        ),
      );
    },
  );
}

class _DialogoLogro extends StatelessWidget {
  final List<Logro> nuevos;

  const _DialogoLogro({required this.nuevos});

  @override
  Widget build(BuildContext context) {
    final varios = nuevos.length > 1;
    final duracionTrofeo = Animaciones.duracion(
      context,
      const Duration(milliseconds: 420),
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.tarjeta),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // El trofeo entra un poco después de la tarjeta.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: duracionTrofeo,
                    curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.scale(scale: 0.8 + 0.2 * v, child: child),
                    ),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.verdeClaro,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        size: 38,
                        color: AppColors.verde,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    varios ? '¡Logros desbloqueados!' : '¡Logro desbloqueado!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: AppColors.textoSuave,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final l in nuevos) ...[
                    Text(
                      l.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.texto,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.descripcion,
                      textAlign: TextAlign.center,
                      style: AppText.cuerpo,
                    ),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: AppDecor.botonPrimario(),
                      child: const Text('¡Genial!', style: AppText.boton),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
