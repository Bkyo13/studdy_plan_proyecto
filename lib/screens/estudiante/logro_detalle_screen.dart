import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/logro_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato_fecha.dart';
import '../../widgets/boton_circular.dart';

/// Detalle de un logro: requisito, progreso y fecha de obtención (si ya se alcanzó).
class LogroDetalleScreen extends StatelessWidget {
  final int logroId;

  const LogroDetalleScreen({super.key, required this.logroId});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final logros = context.watch<LogroProvider>();
    final tareas = context.watch<TareaProvider>();

    final logro = logros.porId(logroId);
    if (logro == null || usuario == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final xp = tareas.xpDe(usuario.id);
    final obtenido = logros.obtenido(usuario.id, logro.id);
    final desbloqueado = obtenido != null;
    final avance = desbloqueado ? logro.xpRequerido : xp.clamp(0, logro.xpRequerido);
    final progreso = avance / logro.xpRequerido;
    final faltan = logro.xpRequerido - xp;
    final tareasFaltantes = (faltan / TareaProvider.xpPorTarea).ceil();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BotonCircular(
                    icono: Icons.arrow_back_ios_new,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Detalle de Logro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textoSuave,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: AppSpacing.entreSecciones),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
                    decoration: AppDecor.tarjeta(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: desbloqueado ? AppColors.verdeClaro : AppColors.borde,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              desbloqueado ? Icons.emoji_events_outlined : Icons.lock_outline,
                              size: 40,
                              color: desbloqueado ? AppColors.verde : AppColors.textoTenue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            logro.nombre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.texto,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: desbloqueado ? AppColors.verde : AppColors.borde,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              desbloqueado ? 'DESBLOQUEADO' : 'BLOQUEADO',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: desbloqueado ? Colors.white : AppColors.textoSuave,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          logro.descripcion,
                          textAlign: TextAlign.center,
                          style: AppText.cuerpo,
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.borde),
                        const SizedBox(height: 12),
                        _titulo('REQUISITO'),
                        const SizedBox(height: 8),
                        Text(
                          'Acumular ${logro.xpRequerido} XP completando tareas '
                          '(cada tarea completada da ${TareaProvider.xpPorTarea} XP).',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.textoSuave,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _titulo('PROGRESO'),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progreso.toDouble(),
                            minHeight: 10,
                            color: AppColors.verde,
                            backgroundColor: AppColors.borde,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          desbloqueado
                              ? '${logro.xpRequerido} / ${logro.xpRequerido} XP · ¡Completado!'
                              : '$avance / ${logro.xpRequerido} XP · te faltan $faltan XP '
                                  '(unas $tareasFaltantes ${tareasFaltantes == 1 ? 'tarea' : 'tareas'})',
                          style: AppText.pequeno,
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.borde),
                        const SizedBox(height: 12),
                        _titulo('FECHA DE OBTENCIÓN'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: desbloqueado ? AppColors.verde : AppColors.textoTenue,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                desbloqueado
                                    ? formatoFechaLarga(obtenido.fechaObtenido)
                                    : 'Aún no lo has desbloqueado',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: desbloqueado ? AppColors.texto : AppColors.textoTenue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textoTenue,
      ),
    );
  }
}
