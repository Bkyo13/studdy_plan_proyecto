import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/logro_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/boton_circular.dart';
import '../../widgets/estado_vacio.dart';
import 'logro_form_screen.dart';

/// Lista del catálogo de logros (Administrador). Tocar uno lo abre para editarlo.
class LogrosAdminScreen extends StatelessWidget {
  const LogrosAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logros = context.watch<LogroProvider>().logros;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LogroFormScreen()),
        ),
        backgroundColor: AppColors.verde,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pantalla,
            AppSpacing.pantalla,
            AppSpacing.pantalla,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BotonCircular(
                    icono: Icons.arrow_back_ios_new,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16),
                  const Text('Logros', style: AppText.tituloPantalla),
                ],
              ),
              const SizedBox(height: 8),
              Text('${logros.length} logros en el catálogo', style: AppText.cuerpo),
              const SizedBox(height: AppSpacing.entreSecciones),
              Expanded(
                child: logros.isEmpty
                    ? const Align(
                        alignment: Alignment.topCenter,
                        child: EstadoVacio(
                          icono: Icons.emoji_events_outlined,
                          titulo: 'No hay logros registrados',
                          mensaje: 'Crea el primero con el botón +.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: logros.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.entreTarjetas),
                        itemBuilder: (context, i) {
                          final logro = logros[i];
                          return Container(
                            decoration: AppDecor.tarjeta(),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.tarjeta),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(AppRadius.tarjeta),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LogroFormScreen(logro: logro),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: const BoxDecoration(
                                          color: AppColors.verdeClaro,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.emoji_events_outlined,
                                          color: AppColors.verde,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(logro.nombre, style: AppText.tituloTarjeta),
                                            const SizedBox(height: 4),
                                            Text(logro.descripcion, style: AppText.pequeno),
                                            const SizedBox(height: 6),
                                            Text(
                                              'XP requerido: ${logro.xpRequerido}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.verde,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.textoSuave,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
