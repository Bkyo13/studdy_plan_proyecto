import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/materia_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/color_hex.dart';
import '../../widgets/boton_circular.dart';
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
              Text('${materias.length} materias registradas',
                  style: AppText.cuerpo),
              const SizedBox(height: AppSpacing.entreSecciones),
              Expanded(
                child: materias.isEmpty
                    ? _estadoVacio()
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 88),
                        itemCount: materias.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.entreTarjetas),
                        itemBuilder: (context, i) {
                          final m = materias[i];
                          return Container(
                            padding: const EdgeInsets.all(
                              AppSpacing.interiorTarjeta,
                            ),
                            decoration: AppDecor.tarjeta(),
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
                              ],
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

  Widget _estadoVacio() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppDecor.tarjeta(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.verdeClaro,
              child: Icon(Icons.inbox_outlined, color: AppColors.verde),
            ),
            SizedBox(height: 16),
            Text('No hay materias registradas', style: AppText.tituloTarjeta),
            SizedBox(height: 8),
            Text(
              'Agrega la primera con el botón +.',
              textAlign: TextAlign.center,
              style: AppText.cuerpo,
            ),
          ],
        ),
      ),
    );
  }
}
