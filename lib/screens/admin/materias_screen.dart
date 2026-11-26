import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/materia_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/color_hex.dart';
import '../../widgets/boton_circular.dart';
import '../../widgets/estado_vacio.dart';
import 'materia_form_screen.dart';

/// Lista de materias (lista secundaria de la entrega).
class MateriasScreen extends StatelessWidget {
  const MateriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final materias = context.watch<MateriaProvider>().materias;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MateriaFormScreen()),
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
                  const Text('Materias', style: AppText.tituloPantalla),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${materias.length} materias registradas · toca una para editarla',
                style: AppText.cuerpo,
              ),
              const SizedBox(height: AppSpacing.entreSecciones),
              Expanded(
                child: materias.isEmpty
                    ? const Align(
                        alignment: Alignment.topCenter,
                        child: EstadoVacio(
                          icono: Icons.menu_book_outlined,
                          titulo: 'No hay materias registradas',
                          mensaje: 'Agrega la primera con el botón +.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: materias.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.entreTarjetas),
                        itemBuilder: (context, i) {
                          final m = materias[i];
                          return Container(
                            decoration: AppDecor.tarjeta(),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.tarjeta),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(AppRadius.tarjeta),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MateriaFormScreen(materia: m),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    AppSpacing.interiorTarjeta,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: colorDesdeHex(m.color),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          m.nombre,
                                          style: AppText.tituloTarjeta,
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
