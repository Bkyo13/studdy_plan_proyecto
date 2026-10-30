import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/logro_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/vinculo_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../utils/validadores.dart';
import '../../widgets/boton_circular.dart';

/// Perfil del estudiante: un solo formulario para consultar y editar nombre y
/// correo, cambiar la contraseña (cuentas de acceso local), más ajustes,
/// cierre de sesión y eliminación de la cuenta con confirmación.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _correoCtrl;
  final _actualCtrl = TextEditingController();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _ocultarPassword = true;

  @override
  void initState() {
    super.initState();
    final usuario = context.read<AuthProvider>().usuarioActual;
    _nombreCtrl = TextEditingController(text: usuario?.nombre ?? '');
    _correoCtrl = TextEditingController(text: usuario?.correo ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _actualCtrl.dispose();
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  /// ¿Escribió algo en los campos de contraseña?
  bool get _tocaPassword =>
      _actualCtrl.text.isNotEmpty ||
      _nuevaCtrl.text.isNotEmpty ||
      _confirmarCtrl.text.isNotEmpty;

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final usuario = auth.usuarioActual;
    if (usuario == null) return;

    final nuevoNombre = _nombreCtrl.text.trim();
    final nuevoCorreo = _correoCtrl.text.trim().toLowerCase();
    final cambiaPerfil =
        nuevoNombre != usuario.nombre || nuevoCorreo != usuario.correo.toLowerCase();
    final cambiaPassword = usuario.accesoLocal && _nuevaCtrl.text.isNotEmpty;

    if (!cambiaPerfil && !cambiaPassword) {
      mostrarMensaje(context, 'No hay cambios que guardar');
      return;
    }

    // Se validan las dos cosas antes de cambiar nada, para no dejar la
    // cuenta a medias.
    if (cambiaPassword && !auth.contrasenaCorrecta(_actualCtrl.text)) {
      mostrarMensaje(context, 'La contraseña actual no es correcta', error: true);
      return;
    }
    if (cambiaPerfil) {
      final error = auth.actualizarPerfil(nombre: nuevoNombre, correo: nuevoCorreo);
      if (error != null) {
        mostrarMensaje(context, error, error: true);
        return;
      }
    }
    if (cambiaPassword) {
      final error = auth.cambiarContrasena(
        actual: _actualCtrl.text,
        nueva: _nuevaCtrl.text,
      );
      if (error != null) {
        mostrarMensaje(context, error, error: true);
        return;
      }
    }

    _actualCtrl.clear();
    _nuevaCtrl.clear();
    _confirmarCtrl.clear();
    FocusScope.of(context).unfocus();
    mostrarMensaje(context, 'Perfil actualizado');
  }

  void _cerrarSesion() {
    final auth = context.read<AuthProvider>();
    Navigator.of(context).pop();
    auth.cerrarSesion();
  }

  Future<void> _eliminarCuenta() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Se borrarán tu cuenta, tus tareas y tus logros. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.peligro, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final auth = context.read<AuthProvider>();
    final tareas = context.read<TareaProvider>();
    final logros = context.read<LogroProvider>();
    final vinculos = context.read<VinculoProvider>();
    final id = auth.usuarioActual?.id;
    if (id == null) return;

    mostrarMensaje(context, 'Tu cuenta fue eliminada');
    Navigator.of(context).pop();
    tareas.eliminarDeEstudiante(id);
    logros.eliminarDeEstudiante(id);
    vinculos.eliminarDeEstudiante(id);
    auth.eliminarCuenta();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final usuario = auth.usuarioActual;
    if (usuario == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final inicial =
        usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : '?';

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
                    Row(
                      children: [
                        BotonCircular(
                          icono: Icons.arrow_back_ios_new,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 16),
                        const Text('Mi perfil', style: AppText.tituloSeccion),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.entreSecciones),
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.verdeClaro,
                        child: Text(
                          inicial,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: AppColors.verde,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      usuario.nombre,
                      textAlign: TextAlign.center,
                      style: AppText.tituloTarjeta,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Estudiante · ${usuario.correo}',
                      textAlign: TextAlign.center,
                      style: AppText.pequeno,
                    ),
                    const SizedBox(height: AppSpacing.entreSecciones),

                    _titulo('DATOS PERSONALES'),
                    const SizedBox(height: 12),
                    const Text('Nombre', style: AppText.labelCampo),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
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
                    const SizedBox(height: AppSpacing.entreSecciones),

                    _titulo('CAMBIAR CONTRASEÑA'),
                    const SizedBox(height: 12),
                    if (usuario.accesoLocal) ..._camposContrasena() else
                      Text(
                        'Tu cuenta usa acceso con ${usuario.proveedor}, así que la '
                        'contraseña se administra allí.',
                        style: AppText.pequeno,
                      ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _guardar,
                      style: AppDecor.botonPrimario(),
                      child: const Text('Guardar cambios', style: AppText.boton),
                    ),
                    const SizedBox(height: AppSpacing.entreSecciones),

                    _titulo('AJUSTES'),
                    const SizedBox(height: 12),
                    _ajustes(auth.sesionRecordada),
                    const SizedBox(height: AppSpacing.entreSecciones),

                    OutlinedButton.icon(
                      onPressed: _cerrarSesion,
                      style: AppDecor.botonSecundario(),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _eliminarCuenta,
                      style: AppDecor.botonSecundario(color: AppColors.peligro),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text(
                        'Eliminar cuenta',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _titulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textoTenue,
      ),
    );
  }

  List<Widget> _camposContrasena() {
    final toggle = IconButton(
      icon: Icon(
        _ocultarPassword
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        color: AppColors.textoSuave,
      ),
      onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
    );

    return [
      const Text(
        'Déjalos vacíos si no quieres cambiarla.',
        style: AppText.pequeno,
      ),
      const SizedBox(height: 12),
      const Text('Contraseña actual', style: AppText.labelCampo),
      const SizedBox(height: 8),
      TextFormField(
        controller: _actualCtrl,
        obscureText: _ocultarPassword,
        textInputAction: TextInputAction.next,
        validator: (v) => _tocaPassword && (v ?? '').isEmpty
            ? 'Escribe tu contraseña actual'
            : null,
        decoration: AppDecor.campo(
          hint: 'Tu contraseña actual',
          icono: Icons.lock_outline,
          sufijo: toggle,
        ),
      ),
      const SizedBox(height: 20),
      const Text('Nueva contraseña', style: AppText.labelCampo),
      const SizedBox(height: 8),
      TextFormField(
        controller: _nuevaCtrl,
        obscureText: _ocultarPassword,
        textInputAction: TextInputAction.next,
        validator: (v) {
          if (!_tocaPassword) return null;
          final texto = v ?? '';
          if (texto.isEmpty) return 'Escribe la nueva contraseña';
          if (texto.length < 6) return 'Mínimo 6 caracteres';
          return null;
        },
        decoration: AppDecor.campo(
          hint: 'Mínimo 6 caracteres',
          icono: Icons.lock_outline,
        ),
      ),
      const SizedBox(height: 20),
      const Text('Confirmar contraseña', style: AppText.labelCampo),
      const SizedBox(height: 8),
      TextFormField(
        controller: _confirmarCtrl,
        obscureText: _ocultarPassword,
        validator: (v) {
          if (!_tocaPassword) return null;
          if ((v ?? '') != _nuevaCtrl.text) return 'Las contraseñas no coinciden';
          return null;
        },
        decoration: AppDecor.campo(
          hint: 'Repite la nueva contraseña',
          icono: Icons.lock_outline,
        ),
      ),
    ];
  }

  Widget _ajustes(bool sesionRecordada) {
    return Container(
      decoration: AppDecor.tarjeta(),
      child: Column(
        children: [
          SwitchListTile(
            value: sesionRecordada,
            onChanged: (valor) {
              context.read<AuthProvider>().cambiarRecordarSesion(valor);
              mostrarMensaje(
                context,
                valor
                    ? 'La sesión se mantendrá iniciada en este dispositivo'
                    : 'Se pedirá iniciar sesión al abrir la app',
              );
            },
            title: const Text(
              'Mantener sesión iniciada',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Guarda un token en este dispositivo para no pedir el login cada vez.',
              style: AppText.pequeno,
            ),
          ),
          const Divider(height: 1, color: AppColors.borde),
          ListTile(
            leading: const Icon(Icons.info_outline, color: AppColors.textoSuave),
            title: const Text(
              'Acerca de StudyPlan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right, color: AppColors.textoSuave),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'StudyPlan',
              applicationVersion: '1.0.0',
              applicationLegalese: 'Proyecto escolar · UTNG',
            ),
          ),
        ],
      ),
    );
  }
}
