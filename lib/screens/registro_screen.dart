import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usuario.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/mensajes.dart';
import '../utils/validadores.dart';
import '../widgets/boton_circular.dart';
import '../widgets/logo_app.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _ocultarPassword = true;
  Rol _rol = Rol.estudiante;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _crearCuenta() {
    if (!_formKey.currentState!.validate()) return;
    final error = context.read<AuthProvider>().registrar(
          nombre: _nombreCtrl.text,
          correo: _correoCtrl.text,
          contrasena: _passwordCtrl.text,
          rol: _rol,
        );
    if (error != null) {
      mostrarMensaje(context, error, error: true);
      return;
    }
    mostrarMensaje(context, 'Cuenta creada correctamente');
    // La sesión ya quedó abierta: al cerrar esta pantalla, AuthGate muestra
    // el dashboard del rol elegido.
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
              child: Form(
                key: _formKey,
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
                      'Crea tu cuenta',
                      textAlign: TextAlign.center,
                      style: AppText.tituloPantalla,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Empieza a organizar tus entregas.',
                      textAlign: TextAlign.center,
                      style: AppText.cuerpo,
                    ),
                    const SizedBox(height: 32),
                    const Text('Nombre', style: AppText.labelCampo),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreCtrl,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      validator: validarNombre,
                      decoration: AppDecor.campo(
                        hint: 'Tu nombre',
                        icono: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          onPressed: () => setState(
                            () => _ocultarPassword = !_ocultarPassword,
                          ),
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
                        if (v != _passwordCtrl.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      decoration: AppDecor.campo(
                        hint: 'Repite tu contraseña',
                        icono: Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Tipo de usuario', style: AppText.labelCampo),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final rol in Rol.values) ...[
                          Expanded(child: _chipRol(rol)),
                          if (rol != Rol.values.last) const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(_rol.descripcion, style: AppText.pequeno),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _crearCuenta,
                      style: AppDecor.botonPrimario(),
                      child: const Text('Crear cuenta', style: AppText.boton),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text.rich(
                          TextSpan(
                            text: '¿Ya tienes una cuenta? ',
                            style: AppText.cuerpo,
                            children: [
                              TextSpan(
                                text: 'Inicia sesión',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chipRol(Rol rol) {
    final seleccionado = rol == _rol;
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => setState(() => _rol = rol),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.verde : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: seleccionado ? AppColors.verde : AppColors.borde,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            rol.etiqueta,
            style: TextStyle(
              fontSize: 14,
              fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
              color: seleccionado ? Colors.white : AppColors.textoSuave,
            ),
          ),
        ),
      ),
    );
  }
}
