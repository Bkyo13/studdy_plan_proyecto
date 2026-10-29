import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/mensajes.dart';
import '../utils/validadores.dart';
import '../widgets/logo_app.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _ocultarPassword = true;
  bool _recordarme = true;

  @override
  void dispose() {
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _iniciarSesion() {
    if (!_formKey.currentState!.validate()) return;
    final error = context.read<AuthProvider>().iniciarSesion(
          _correoCtrl.text,
          _passwordCtrl.text,
          recordarme: _recordarme,
        );
    if (error != null) {
      mostrarMensaje(context, error, error: true);
    }
    // Si no hay error, AuthGate detecta la sesión y abre el dashboard del rol.
  }

  void _proximamente(String funcion) {
    mostrarMensaje(context, '$funcion estará disponible en una próxima versión');
  }

  void _irARegistro() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegistroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pantalla,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _encabezado(),
                    const SizedBox(height: 40),
                    const Text('Correo electrónico', style: AppText.labelCampo),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: validarCorreo,
                      decoration: AppDecor.campo(
                        hint: 'ejemplo@dominio.com',
                        icono: Icons.mail_outline,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Contraseña', style: AppText.labelCampo),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _ocultarPassword,
                      validator: validarPassword,
                      onFieldSubmitted: (_) => _iniciarSesion(),
                      decoration: AppDecor.campo(
                        hint: '••••••••',
                        icono: Icons.lock_outline,
                        sufijo: IconButton(
                          icon: Icon(
                            _ocultarPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textoSuave,
                          ),
                          onPressed: () => setState(
                            () => _ocultarPassword = !_ocultarPassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _filaRecordarme(),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _iniciarSesion,
                      style: AppDecor.botonPrimario(),
                      child: const Text('Iniciar sesión', style: AppText.boton),
                    ),
                    const SizedBox(height: 24),
                    _separador(),
                    const SizedBox(height: 24),
                    _botonesSociales(),
                    const SizedBox(height: 40),
                    _pie(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----- Secciones de la pantalla -----

  Widget _encabezado() {
    return const Column(
      children: [
        LogoApp(),
        SizedBox(height: 24),
        Text('StudyPlan', style: AppText.tituloPantalla),
        SizedBox(height: 12),
        Text(
          'Tu compañero de estudio calmado, ordenado y eficiente.',
          textAlign: TextAlign.center,
          style: AppText.cuerpo,
        ),
      ],
    );
  }

  Widget _filaRecordarme() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _recordarme = !_recordarme),
          child: Row(
            children: [
              Checkbox(
                value: _recordarme,
                activeColor: AppColors.verde,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: const BorderSide(color: AppColors.borde, width: 1.5),
                onChanged: (v) => setState(() => _recordarme = v ?? false),
              ),
              const Text(
                'Recordarme',
                style: TextStyle(fontSize: 14, color: AppColors.textoSuave),
              ),
            ],
          ),
        ),
        Flexible(
          child: TextButton(
            onPressed: () => _proximamente('Recuperar la contraseña'),
            child: const Text(
              '¿Olvidaste tu contraseña?',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.verde,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _separador() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.borde)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('o continúa con', style: TextStyle(color: AppColors.textoSuave)),
        ),
        Expanded(child: Divider(color: AppColors.borde)),
      ],
    );
  }

  Widget _botonesSociales() {
    return Row(
      children: [
        Expanded(
          child: _botonSocial(
            icono: const Text(
              'G',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4285F4),
              ),
            ),
            texto: 'Google',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _botonSocial(
            icono: const Icon(Icons.apple, color: AppColors.texto, size: 24),
            texto: 'Apple',
          ),
        ),
      ],
    );
  }

  Widget _botonSocial({required Widget icono, required String texto}) {
    return OutlinedButton(
      onPressed: () => _proximamente('Iniciar sesión con $texto'),
      style: AppDecor.botonSecundario(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icono,
          const SizedBox(width: 8),
          Text(
            texto,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _pie() {
    return Column(
      children: [
        InkWell(
          onTap: _irARegistro,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text.rich(
              TextSpan(
                text: '¿No tienes una cuenta? ',
                style: AppText.cuerpo,
                children: [
                  TextSpan(
                    text: 'Regístrate gratis',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.verde,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text.rich(
          TextSpan(
            text: 'Al continuar, aceptas nuestros ',
            style: AppText.pequeno,
            children: [
              TextSpan(
                text: 'Términos de servicio',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: AppColors.texto,
                ),
              ),
              TextSpan(text: ' y nuestra '),
              TextSpan(
                text: 'Política de privacidad',
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: AppColors.texto,
                ),
              ),
              TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}