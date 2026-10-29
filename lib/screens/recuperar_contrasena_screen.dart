import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/mensajes.dart';
import '../utils/validadores.dart';
import '../widgets/boton_circular.dart';
import '../widgets/logo_app.dart';

/// Recuperación de contraseña en dos pasos:
/// 1) se escribe el correo y se genera un código temporal;
/// 2) se escribe el código y la nueva contraseña.
class RecuperarContrasenaScreen extends StatefulWidget {
  /// Correo que ya había escrito en el login (para no volver a pedirlo).
  final String correoInicial;

  const RecuperarContrasenaScreen({super.key, this.correoInicial = ''});

  @override
  State<RecuperarContrasenaScreen> createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final _formCorreo = GlobalKey<FormState>();
  final _formCodigo = GlobalKey<FormState>();
  late final TextEditingController _correoCtrl;
  final _codigoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();

  bool _ocultarPassword = true;

  /// Código generado (null mientras se está en el paso 1).
  String? _codigoGenerado;
  String _correoDestino = '';

  bool get _enPaso2 => _codigoGenerado != null;

  @override
  void initState() {
    super.initState();
    _correoCtrl = TextEditingController(text: widget.correoInicial.trim());
  }

  @override
  void dispose() {
    _correoCtrl.dispose();
    _codigoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _enviarCodigo() {
    if (!_formCorreo.currentState!.validate()) return;
    final codigo =
        context.read<AuthProvider>().solicitarRecuperacion(_correoCtrl.text);
    if (codigo == null) {
      mostrarMensaje(context, 'No existe una cuenta con ese correo', error: true);
      return;
    }
    setState(() {
      _codigoGenerado = codigo;
      _correoDestino = _correoCtrl.text.trim();
      _codigoCtrl.clear();
      _passwordCtrl.clear();
      _confirmarCtrl.clear();
    });
  }

  void _cambiarContrasena() {
    if (!_formCodigo.currentState!.validate()) return;
    final error = context.read<AuthProvider>().restablecerContrasena(
          correo: _correoDestino,
          codigo: _codigoCtrl.text,
          nuevaContrasena: _passwordCtrl.text,
        );
    if (error != null) {
      mostrarMensaje(context, error, error: true);
      return;
    }
    mostrarMensaje(context, 'Contraseña actualizada. Ya puedes iniciar sesión');
    Navigator.of(context).pop();
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
                    _enPaso2
                        ? 'Escribe el código y elige tu nueva contraseña.'
                        : 'Escribe el correo de tu cuenta y te daremos un código para restablecerla.',
                    textAlign: TextAlign.center,
                    style: AppText.cuerpo,
                  ),
                  const SizedBox(height: 32),
                  if (_enPaso2) _paso2() else _paso1(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paso1() {
    return Form(
      key: _formCorreo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Correo electrónico', style: AppText.labelCampo),
          const SizedBox(height: 8),
          TextFormField(
            controller: _correoCtrl,
            keyboardType: TextInputType.emailAddress,
            validator: validarCorreo,
            onFieldSubmitted: (_) => _enviarCodigo(),
            decoration: AppDecor.campo(
              hint: 'ejemplo@dominio.com',
              icono: Icons.mail_outline,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _enviarCodigo,
            style: AppDecor.botonPrimario(),
            child: const Text('Enviar código', style: AppText.boton),
          ),
        ],
      ),
    );
  }

  Widget _paso2() {
    return Form(
      key: _formCodigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _avisoCodigo(),
          const SizedBox(height: 24),
          const Text('Código de 6 dígitos', style: AppText.labelCampo),
          const SizedBox(height: 8),
          TextFormField(
            controller: _codigoCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textInputAction: TextInputAction.next,
            validator: (v) => (v ?? '').trim().length != 6
                ? 'Escribe el código de 6 dígitos'
                : null,
            decoration: AppDecor.campo(
              hint: '000000',
              icono: Icons.pin_outlined,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Nueva contraseña', style: AppText.labelCampo),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _ocultarPassword,
            textInputAction: TextInputAction.next,
            validator: validarPassword,
            decoration: AppDecor.campo(
              hint: 'Mínimo 6 caracteres',
              icono: Icons.lock_outline,
              sufijo: IconButton(
                icon: Icon(
                  _ocultarPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textoSuave,
                ),
                onPressed: () =>
                    setState(() => _ocultarPassword = !_ocultarPassword),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Confirmar contraseña', style: AppText.labelCampo),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmarCtrl,
            obscureText: _ocultarPassword,
            validator: (v) {
              if ((v ?? '').isEmpty) return 'Confirma tu contraseña';
              if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
              return null;
            },
            decoration: AppDecor.campo(
              hint: 'Repite tu contraseña',
              icono: Icons.lock_outline,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _cambiarContrasena,
            style: AppDecor.botonPrimario(),
            child: const Text('Cambiar contraseña', style: AppText.boton),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _codigoGenerado = null),
            child: const Text(
              'Usar otro correo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.verde,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// En una app real el código llegaría por correo. En esta demo se muestra
  /// aquí, y se aclara en pantalla para que no parezca un envío real.
  Widget _avisoCodigo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.verdeClaro,
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SIMULACIÓN DE CORREO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.verde,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Para $_correoDestino. En una app real este código llegaría a tu bandeja; aquí se muestra para la demostración y vence en 10 minutos.',
            style: AppText.cuerpo,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _codigoGenerado ?? '',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
                color: AppColors.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}