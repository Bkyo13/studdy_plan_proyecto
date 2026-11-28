import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../providers/auth_provider.dart';
import '../../providers/logro_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../providers/vinculo_provider.dart';
import '../../services/notificaciones_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/cerrar_sesion.dart';
import '../../utils/mensajes.dart';
import '../../utils/teclado.dart';
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
  bool _guardando = false;

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

  Future<void> _guardar() async {
    ocultarTeclado();
    if (_guardando || !_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final usuario = auth.usuarioActual;
    if (usuario == null) return;

    final nuevoNombre = _nombreCtrl.text.trim();
    final nuevoCorreo = _correoCtrl.text.trim().toLowerCase();
    final cambiaNombre = nuevoNombre != usuario.nombre;
    final cambiaCorreo = nuevoCorreo != usuario.correo.toLowerCase();
    final cambiaPassword = usuario.accesoLocal && _nuevaCtrl.text.isNotEmpty;

    if (!cambiaNombre && !cambiaCorreo && !cambiaPassword) {
      mostrarMensaje(context, 'No hay cambios que guardar');
      return;
    }

    setState(() => _guardando = true);
    // Primero la contraseña: Firebase confirma la actual antes de cambiarla,
    // y si está mal no se toca nada más.
    if (cambiaPassword) {
      final error = await auth.cambiarContrasena(
        actual: _actualCtrl.text,
        nueva: _nuevaCtrl.text,
      );
      if (!mounted) return;
      if (error != null) {
        setState(() => _guardando = false);
        mostrarMensaje(context, error, error: true);
        return;
      }
    }
    if (cambiaNombre || cambiaCorreo) {
      final error = await auth.actualizarPerfil(
        nombre: nuevoNombre,
        correo: nuevoCorreo,
      );
      if (!mounted) return;
      if (error != null) {
        setState(() => _guardando = false);
        mostrarMensaje(context, error, error: true);
        return;
      }
    }
    if (!mounted) return;
    setState(() => _guardando = false);

    _actualCtrl.clear();
    _nuevaCtrl.clear();
    _confirmarCtrl.clear();
    FocusScope.of(context).unfocus();
    if (cambiaCorreo) {
      // El correo se cambia hasta que se confirme el enlace; mientras, el
      // campo regresa al correo actual.
      _correoCtrl.text = usuario.correo;
      mostrarMensaje(
        context,
        'Te enviamos un enlace a $nuevoCorreo. El correo cambiará cuando lo abras.',
      );
    } else {
      mostrarMensaje(context, 'Perfil actualizado');
    }
  }

  Future<void> _eliminarCuenta() async {
    final auth = context.read<AuthProvider>();
    final usuario = auth.usuarioActual;
    if (usuario == null) return;
    final passwordCtrl = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              switch (usuario.rol) {
                Rol.estudiante => 'Se borrarán tu cuenta, tus tareas y tus '
                    'logros. Esta acción no se puede deshacer.',
                Rol.tutor => 'Se borrarán tu cuenta y el vínculo con tu '
                    'estudiante (sus tareas no se borran). Esta acción no se '
                    'puede deshacer.',
                Rol.administrador => 'Se borrará tu cuenta de administrador. '
                    'Las materias y logros del catálogo se quedan. Esta acción '
                    'no se puede deshacer.',
              },
            ),
            if (usuario.accesoLocal) ...[
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Escribe tu contraseña para confirmar',
                ),
              ),
            ],
          ],
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
    final contrasena = passwordCtrl.text;
    passwordCtrl.dispose();
    if (confirmado != true || !mounted) return;

    setState(() => _guardando = true);
    // Firebase pide confirmar la contraseña antes de borrar una cuenta.
    if (usuario.accesoLocal && !await auth.contrasenaCorrecta(contrasena)) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(context, 'La contraseña no es correcta', error: true);
      return;
    }
    // Cuentas de Google: se confirma eligiendo la cuenta otra vez.
    if (!usuario.accesoLocal && !await auth.reautenticarConGoogle()) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(context, 'No se pudo confirmar tu cuenta de Google', error: true);
      return;
    }
    if (!mounted) return;

    final tareas = context.read<TareaProvider>();
    final logros = context.read<LogroProvider>();
    final vinculos = context.read<VinculoProvider>();
    final id = usuario.id;

    // Primero sus datos (las reglas de Firestore exigen que siga con sesión)
    // y al final la cuenta.
    try {
      switch (usuario.rol) {
        case Rol.estudiante:
          await tareas.eliminarDeEstudiante(id);
          await vinculos.eliminarDeEstudiante(id);
          await logros.eliminarDeEstudiante(id);
        case Rol.tutor:
          await vinculos.desvincular(id);
        case Rol.administrador:
          break; // El catálogo es de todos: no se borra.
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      mostrarMensaje(
        context,
        'No se pudieron borrar tus datos. Revisa tu conexión.',
        error: true,
      );
      return;
    }
    tareas.detener();
    vinculos.detener();
    final error = await auth.eliminarCuenta();
    if (!mounted) return;
    if (error != null) {
      setState(() => _guardando = false);
      mostrarMensaje(context, error, error: true);
      return;
    }
    mostrarMensaje(context, 'Tu cuenta fue eliminada');
    Navigator.of(context).pop();
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
                      '${usuario.rol.etiqueta} · ${usuario.correo}',
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
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(Limites.nombreUsuario),
                      ],
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
                      // Con Google, el correo es el de la cuenta de Google.
                      readOnly: !usuario.accesoLocal,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(Limites.correo),
                      ],
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
                      onPressed: _guardando ? null : _guardar,
                      style: AppDecor.botonPrimario(),
                      child: _guardando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar cambios', style: AppText.boton),
                    ),
                    const SizedBox(height: AppSpacing.entreSecciones),

                    if (usuario.rol == Rol.estudiante) ...[
                      _titulo('TUTOR'),
                      const SizedBox(height: 12),
                      _tutores(),
                      const SizedBox(height: AppSpacing.entreSecciones),
                    ],

                    _titulo('AJUSTES'),
                    const SizedBox(height: 12),
                    _ajustes(
                      auth.sesionRecordada,
                      esEstudiante: usuario.rol == Rol.estudiante,
                    ),
                    const SizedBox(height: AppSpacing.entreSecciones),

                    OutlinedButton.icon(
                      onPressed: () => confirmarCerrarSesion(context),
                      style: AppDecor.botonSecundario(),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _guardando ? null : _eliminarCuenta,
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

  /// Tutores que el estudiante aceptó, con opción de quitarlos.
  Widget _tutores() {
    final auth = context.watch<AuthProvider>();
    final aceptados = context.watch<VinculoProvider>().tutoresAceptados;
    if (aceptados.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppDecor.tarjeta(),
        child: const Text(
          'Ningún tutor ve tu avance. Si un tutor te envía una solicitud, '
          'te aparecerá en Inicio.',
          style: AppText.pequeno,
        ),
      );
    }
    return Container(
      decoration: AppDecor.tarjeta(),
      child: Column(
        children: [
          for (final v in aceptados)
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: const Icon(
                  Icons.supervisor_account_outlined,
                  color: AppColors.verde,
                ),
                title: Text(auth.porId(v.tutorId)?.nombre ?? 'Tutor'),
                subtitle: Text(
                  auth.porId(v.tutorId)?.correo ?? 'Puede ver tus tareas y tu XP',
                ),
                trailing: TextButton(
                  onPressed: () => _confirmarQuitarTutor(
                    v.tutorId,
                    auth.porId(v.tutorId)?.nombre ?? 'tu tutor',
                  ),
                  child: const Text(
                    'Quitar',
                    style: TextStyle(color: AppColors.peligro),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmarQuitarTutor(String tutorId, String nombre) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar tutor'),
        content: Text(
          '$nombre dejará de ver tus tareas y tu avance. '
          'Podrá enviarte otra solicitud más adelante.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Quitar',
              style: TextStyle(
                color: AppColors.peligro,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;
    final ok = await context.read<VinculoProvider>().rechazar(tutorId);
    if (!mounted) return;
    mostrarMensaje(
      context,
      ok ? 'Tutor quitado' : 'No se pudo quitar. Revisa tu conexión.',
      error: !ok,
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
        inputFormatters: [
          LengthLimitingTextInputFormatter(Limites.contrasena),
        ],
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
        inputFormatters: [
          LengthLimitingTextInputFormatter(Limites.contrasena),
        ],
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
        inputFormatters: [
          LengthLimitingTextInputFormatter(Limites.contrasena),
        ],
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

  /// Guarda el ajuste de recordatorios y reprograma los avisos de las tareas
  /// pendientes según la nueva preferencia.
  Future<void> _cambiarAvisos({
    bool? activos,
    bool? unDiaAntes,
    bool? unaHoraAntes,
  }) async {
    final avisos = NotificacionesService.instancia;
    final usuario = context.read<AuthProvider>().usuarioActual;
    final tareas = context.read<TareaProvider>();
    await avisos.cambiarAjustes(
      activos: activos,
      unDiaAntes: unDiaAntes,
      unaHoraAntes: unaHoraAntes,
    );
    if (!mounted) return;
    setState(() {});
    if (activos == true) await avisos.pedirPermiso();
    if (usuario != null) {
      await avisos.sincronizar(
        tareas.tareasDe(usuario.id, estado: Estado.pendiente),
      );
    }
  }

  Widget _chipAviso({
    required String texto,
    required bool seleccionado,
    required ValueChanged<bool> onChanged,
  }) {
    return FilterChip(
      label: Text(texto),
      selected: seleccionado,
      onSelected: onChanged,
      selectedColor: AppColors.verdeClaro,
      checkmarkColor: AppColors.verde,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: seleccionado ? AppColors.verde : AppColors.textoSuave,
        fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(color: seleccionado ? AppColors.verde : AppColors.borde),
    );
  }

  /// Los recordatorios solo aplican al estudiante (son de sus tareas).
  Widget _ajustes(bool sesionRecordada, {required bool esEstudiante}) {
    final avisos = NotificacionesService.instancia;
    return Container(
      decoration: AppDecor.tarjeta(),
      // Material transparente dentro de la tarjeta: los renglones (ListTile)
      // pintan su efecto al tocarlos sobre él, sin que el fondo lo tape.
      child: Material(
        type: MaterialType.transparency,
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
        clipBehavior: Clip.antiAlias,
        child: Column(
        children: [
          if (esEstudiante) ...[
          SwitchListTile(
            value: avisos.activos,
            onChanged: (valor) {
              _cambiarAvisos(activos: valor);
              mostrarMensaje(
                context,
                valor
                    ? 'Recibirás recordatorios de tus entregas'
                    : 'Ya no recibirás recordatorios',
              );
            },
            secondary: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.verde,
            ),
            title: const Text(
              'Recordatorios de entregas',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Avisos en el teléfono antes de cada fecha de entrega.',
              style: AppText.pequeno,
            ),
          ),
          if (avisos.activos)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Text('Avisarme:', style: AppText.pequeno),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chipAviso(
                          texto: '1 día antes',
                          seleccionado: avisos.unDiaAntes,
                          onChanged: (v) {
                            // Al menos uno debe quedar encendido.
                            if (!v && !avisos.unaHoraAntes) return;
                            _cambiarAvisos(unDiaAntes: v);
                          },
                        ),
                        _chipAviso(
                          texto: '1 hora antes',
                          seleccionado: avisos.unaHoraAntes,
                          onChanged: (v) {
                            if (!v && !avisos.unDiaAntes) return;
                            _cambiarAvisos(unaHoraAntes: v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1, color: AppColors.borde),
          ],
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
              children: const [
                SizedBox(height: 16),
                Text(
                  'Tus tareas, tu XP y tus logros se guardan en Firebase y solo '
                  'tú (y el tutor que aceptes) pueden verlos. No vendemos ni '
                  'compartimos tus datos y no hay anuncios. Lo que escribes al '
                  'asistente se envía a Gemini para responderte y no se guarda.',
                  style: AppText.pequeno,
                ),
                SizedBox(height: 12),
                Text(
                  'Política de privacidad completa:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                SelectableText(
                  'github.com/Bkyo13/studdy_plan_proyecto/blob/main/docs/PRIVACIDAD.md',
                  style: TextStyle(fontSize: 13, color: AppColors.verde),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
