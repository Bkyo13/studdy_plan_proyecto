import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/vinculo_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../../widgets/boton_circular.dart';

/// Formulario del Tutor: vincula a un estudiante por su correo.
class VincularEstudianteScreen extends StatefulWidget {
  const VincularEstudianteScreen({super.key});

  @override
  State<VincularEstudianteScreen> createState() =>
      _VincularEstudianteScreenState();
}

class _VincularEstudianteScreenState extends State<VincularEstudianteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  void _vincular() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final tutor = auth.usuarioActual;
    if (tutor == null) return;

    final estudiante = auth.buscarEstudiantePorCorreo(_correoCtrl.text);
    if (estudiante == null) {
      mostrarMensaje(
        context,
        'No se encontró un estudiante con ese correo',
        error: true,
      );
      return;
    }

    context.read<VinculoProvider>().vincular(tutor.id, estudiante.id);
    mostrarMensaje(context, 'Estudiante vinculado: ${estudiante.nombre}');
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
                  const Text('Vincular estudiante', style: AppText.tituloSeccion),
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
                        const Text(
                          'Correo del estudiante',
                          style: AppText.labelCampo,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _correoCtrl,
                          keyboardType: TextInputType.emailAddress,
                          validator: validarCorreo,
                          onFieldSubmitted: (_) => _vincular(),
                          decoration: AppDecor.campo(
                            hint: 'ejemplo@dominio.com',
                            icono: Icons.mail_outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Escribe el correo con el que se registró el estudiante. '
                          'Solo podrás ver sus tareas, no modificarlas.',
                          style: AppText.pequeno,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _vincular,
                style: AppDecor.botonPrimario(),
                child: const Text('Vincular estudiante', style: AppText.boton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
