import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/logro.dart';
import '../../providers/logro_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../widgets/boton_circular.dart';

/// Formulario del Administrador: crea un logro o edita uno existente.
class LogroFormScreen extends StatefulWidget {
  /// Si se pasa un logro, la pantalla funciona como "Editar logro".
  final Logro? logro;

  const LogroFormScreen({super.key, this.logro});

  @override
  State<LogroFormScreen> createState() => _LogroFormScreenState();
}

class _LogroFormScreenState extends State<LogroFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _xpCtrl;

  bool get _editando => widget.logro != null;

  @override
  void initState() {
    super.initState();
    final l = widget.logro;
    _nombreCtrl = TextEditingController(text: l?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: l?.descripcion ?? '');
    _xpCtrl = TextEditingController(text: l == null ? '' : '${l.xpRequerido}');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<LogroProvider>();
    final xp = int.parse(_xpCtrl.text.trim());

    final error = _editando
        ? provider.actualizar(
            id: widget.logro!.id,
            nombre: _nombreCtrl.text,
            descripcion: _descripcionCtrl.text,
            xpRequerido: xp,
          )
        : provider.agregar(
            nombre: _nombreCtrl.text,
            descripcion: _descripcionCtrl.text,
            xpRequerido: xp,
          );

    if (error != null) {
      mostrarMensaje(context, error, error: true);
      return;
    }
    mostrarMensaje(context, _editando ? 'Logro actualizado' : 'Logro creado');
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
                  Text(
                    _editando ? 'Editar logro' : 'Nuevo logro',
                    style: AppText.tituloSeccion,
                  ),
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
                        const Text('Nombre del logro', style: AppText.labelCampo),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nombreCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [LengthLimitingTextInputFormatter(60)],
                          validator: (v) {
                            final t = (v ?? '').trim();
                            if (t.isEmpty) return 'Escribe el nombre';
                            if (t.length < 3) return 'Mínimo 3 caracteres';
                            return null;
                          },
                          decoration: AppDecor.campo(hint: 'Ej: Madrugador'),
                        ),
                        const SizedBox(height: 20),
                        const Text('Descripción', style: AppText.labelCampo),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descripcionCtrl,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [LengthLimitingTextInputFormatter(150)],
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Escribe una descripción'
                              : null,
                          decoration: AppDecor.campo(
                            hint: 'Qué hay que lograr para obtenerlo (máx. 150 caracteres)',
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('XP requerido', style: AppText.labelCampo),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _xpCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          validator: (v) {
                            final n = int.tryParse((v ?? '').trim());
                            if (n == null) return 'Escribe el XP requerido';
                            if (n < 1) return 'Debe ser mayor a 0';
                            return null;
                          },
                          decoration: AppDecor.campo(
                            hint: 'Ej: 150',
                            icono: Icons.military_tech_outlined,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _editando
                              ? 'Los estudiantes que ya obtuvieron este logro lo conservan aunque cambies el XP requerido.'
                              : 'Cada tarea completada da 10 XP. El logro se desbloquea cuando el estudiante llega al XP requerido.',
                          style: AppText.pequeno,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _guardar,
                style: AppDecor.botonPrimario(),
                child: Text(
                  _editando ? 'Guardar cambios' : 'Crear logro',
                  style: AppText.boton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
