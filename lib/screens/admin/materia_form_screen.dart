import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/materia_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/color_hex.dart';
import '../../utils/mensajes.dart';
import '../../widgets/boton_circular.dart';

/// Formulario del Administrador: crea una materia nueva.
class MateriaFormScreen extends StatefulWidget {
  const MateriaFormScreen({super.key});

  @override
  State<MateriaFormScreen> createState() => _MateriaFormScreenState();
}

class _MateriaFormScreenState extends State<MateriaFormScreen> {
  static const _paleta = [
    '#758B75',
    '#C0807A',
    '#D4B483',
    '#8FA68A',
    '#7D8FA6',
    '#A68FA6',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  String _colorSeleccionado = _paleta.first;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final error = context
        .read<MateriaProvider>()
        .agregar(_nombreCtrl.text, _colorSeleccionado);
    if (error != null) {
      mostrarMensaje(context, error, error: true);
      return;
    }
    mostrarMensaje(context, 'Materia guardada');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(width: 16),
                  const Text('Nueva materia', style: AppText.tituloSeccion),
                ],
              ),
              const SizedBox(height: AppSpacing.entreSecciones),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nombre de la materia',
                            style: AppText.labelCampo),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nombreCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) {
                            final texto = (v ?? '').trim();
                            if (texto.isEmpty) return 'Escribe el nombre';
                            if (texto.length < 3) return 'Mínimo 3 caracteres';
                            return null;
                          },
                          decoration: AppDecor.campo(
                            hint: 'Ej: Bases de Datos',
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Color', style: AppText.labelCampo),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final hex in _paleta) _opcionColor(hex),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _guardar,
                style: AppDecor.botonPrimario(),
                child: const Text('Guardar materia', style: AppText.boton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _opcionColor(String hex) {
    final seleccionado = hex == _colorSeleccionado;
    return GestureDetector(
      onTap: () => setState(() => _colorSeleccionado = hex),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorDesdeHex(hex),
          shape: BoxShape.circle,
          border: Border.all(
            color: seleccionado ? AppColors.texto : Colors.transparent,
            width: 2,
          ),
        ),
        child: seleccionado
            ? const Icon(Icons.check, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}
