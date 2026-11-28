import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/mensajes.dart';
import '../utils/teclado.dart';
import '../utils/validadores.dart';
import '../widgets/boton_circular.dart';
import '../widgets/logo_app.dart';

/// Recuperación de contraseña con Firebase: se escribe el correo y Firebase
/// manda un enlace para crear una contraseña nueva. La contraseña se cambia
/// en esa página de Firebase; después se inicia sesión con la nueva.
class RecuperarContrasenaScreen extends StatefulWidget {
  /// Correo que ya había escrito en el login (para no volver a pedirlo).
  final String correoInicial;

  const RecuperarContrasenaScreen({super.key, this.correoInicial = ''});

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _correoCtrl;
  bool _cargando = false;

  /// Correo al que se pidió el enlace (null mientras no se envía).
  String? _correoEnviado;

  @override
  void initState() {
    super.initState();
    _correoCtrl = TextEditingController(text: widget.correoInicial.trim());
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarEnlace() async {
    ocultarTeclado();
    if (_cargando || !_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    final error =
        await context.read<AuthProvider>().solicitarRecuperacion(_correoCtrl.text);
    if (!mounted) return;
    setState(() => _cargando = false);
    if (error != null) {
      mostrarMensaje(context, error, error: true);
      return;
    }
    setState(() => _correoEnviado = _correoCtrl.text.trim().toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pantalla),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: BotonCircular(
                      icono: Icons.arrow_back_ios_new,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(child: LogoApp(tamano: 56)),
                  const SizedBox(height: 20),
                  const Text(
                    'Recuperar contraseña',
                    textAlign: TextAlign.center,
                    style: AppText.tituloPantalla,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _correoEnviado == null
                        ? 'Escribe el correo de tu cuenta y te enviaremos un enlace para crear una contraseña nueva.'
                        : 'Revisa tu bandeja de entrada.',
                    textAlign: TextAlign.center,
                    style: AppText.cuerpo,
                  ),
                  const SizedBox(height: 32),
                  if (_correoEnviado == null) _formulario() else _enviado(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Correo electrónico', style: AppText.labelCampo),
          const SizedBox(height: 8),
          TextFormField(
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              LengthLimitingTextInputFormatter(Limites.correo),
            ],
            validator: validarCorreo,
            onFieldSubmitted: (_) => _enviarEnlace(),
            decoration: AppDecor.campo(
              hint: 'ejemplo@dominio.com',
              icono: Icons.mail_outline,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _cargando ? null : _enviarEnlace,
            style: AppDecor.botonPrimario(),
            child: _cargando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enviar enlace', style: AppText.boton),
          ),
        ],
      ),
    );
  }

  Widget _enviado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
          decoration: AppDecor.tarjeta(),
          child: Column(
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: AppColors.verde,
              ),
              const SizedBox(height: 12),
              // Mismo mensaje exista o no la cuenta, para no revelar qué
              // correos están registrados.
              Text(
                'Si $_correoEnviado tiene una cuenta en StudyPlan, te '
                'llegará un correo con un enlace para crear tu contraseña '
                'nueva. Revisa también la carpeta de spam.',
                textAlign: TextAlign.center,
                style: AppText.cuerpo,
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: AppDecor.botonPrimario(),
          child: const Text('Volver al inicio de sesión', style: AppText.boton),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() => _correoEnviado = null),
          child: const Text(
            'Usar otro correo',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.verde,
            ),
          ),
        ),
      ],
    );
  }
}
