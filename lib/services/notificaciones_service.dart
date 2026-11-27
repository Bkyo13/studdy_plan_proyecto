import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/tarea.dart';

/// Recordatorios locales de entregas. Los programa el propio teléfono (sin
/// servidor ni internet) y llegan aunque la app esté cerrada.
///
/// Por cada tarea pendiente se programan hasta dos avisos:
///   - 1 día antes de la entrega.
///   - 1 hora antes de la entrega.
/// Los que ya pasaron no se programan.
///
/// En Android se usa un horario "aproximado" (inexactAllowWhileIdle): puede
/// llegar unos minutos tarde, pero no necesita el permiso de alarmas exactas,
/// que Google Play restringe a apps de alarma y calendario.
class NotificacionesService {
  NotificacionesService._();
  static final NotificacionesService instancia = NotificacionesService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _listo = false;

  // Ajustes del usuario (se guardan en el teléfono, en "Mi perfil").
  static const _claveActivos = 'avisos_activos';
  static const _claveUnDia = 'aviso_un_dia';
  static const _claveUnaHora = 'aviso_una_hora';
  bool _activos = true;
  bool _unDia = true;
  bool _unaHora = true;

  /// Si el usuario quiere recibir recordatorios.
  bool get activos => _activos;

  /// Aviso 1 día antes de la entrega.
  bool get unDiaAntes => _unDia;

  /// Aviso 1 hora antes de la entrega.
  bool get unaHoraAntes => _unaHora;

  /// Guarda los ajustes. Después hay que llamar a [sincronizar] para que los
  /// avisos ya programados se ajusten.
  Future<void> cambiarAjustes({
    bool? activos,
    bool? unDiaAntes,
    bool? unaHoraAntes,
  }) async {
    _activos = activos ?? _activos;
    _unDia = unDiaAntes ?? _unDia;
    _unaHora = unaHoraAntes ?? _unaHora;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_claveActivos, _activos);
      await prefs.setBool(_claveUnDia, _unDia);
      await prefs.setBool(_claveUnaHora, _unaHora);
    } catch (e) {
      if (kDebugMode) debugPrint('[Notificaciones] No se guardaron los ajustes: $e');
    }
  }

  static const _canal = AndroidNotificationDetails(
    'recordatorios_entregas',
    'Recordatorios de entregas',
    channelDescription: 'Avisos antes de la fecha de entrega de tus tareas',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _detalles = NotificationDetails(
    android: _canal,
    iOS: DarwinNotificationDetails(),
  );

  /// Las notificaciones locales no existen en la versión web.
  bool get _soportado => !kIsWeb;

  /// Se llama una vez al abrir la app (en main.dart). No pide permisos aquí,
  /// para no lanzar el aviso del sistema antes de que el usuario inicie sesión.
  Future<void> inicializar() async {
    if (!_soportado || _listo) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _activos = prefs.getBool(_claveActivos) ?? true;
      _unDia = prefs.getBool(_claveUnDia) ?? true;
      _unaHora = prefs.getBool(_claveUnaHora) ?? true;

      const ajustes = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: ajustes);
      _listo = true;
    } catch (e) {
      if (kDebugMode) debugPrint('[Notificaciones] No se pudo inicializar: $e');
    }
  }

  /// Pide permiso para mostrar notificaciones (Android 13+ e iOS).
  /// Si el usuario ya respondió antes, el sistema no vuelve a preguntar.
  Future<void> pedirPermiso() async {
    if (!_soportado || !_listo) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      if (kDebugMode) debugPrint('[Notificaciones] Error al pedir permiso: $e');
    }
  }

  /// Programa (o reprograma) los avisos de una tarea. Si ya no está
  /// pendiente, solo cancela los que tuviera.
  Future<void> programarTarea(Tarea tarea) async {
    if (!_soportado || !_listo) return;
    await cancelarTarea(tarea.id);
    if (!_activos || tarea.estado != Estado.pendiente) return;

    final entrega = tarea.fechaEntrega;
    if (_unDia) {
      await _programar(
        id: _idAviso(tarea.id, 0),
        cuando: entrega.subtract(const Duration(days: 1)),
        titulo: '📚 Mañana se entrega una tarea',
        cuerpo: tarea.nombre,
      );
    }
    if (_unaHora) {
      await _programar(
        id: _idAviso(tarea.id, 1),
        cuando: entrega.subtract(const Duration(hours: 1)),
        titulo: '⏰ Te queda 1 hora para entregar',
        cuerpo: tarea.nombre,
      );
    }
  }

  Future<void> cancelarTarea(String tareaId) async {
    if (!_soportado || !_listo) return;
    try {
      await _plugin.cancel(id: _idAviso(tareaId, 0));
      await _plugin.cancel(id: _idAviso(tareaId, 1));
    } catch (e) {
      if (kDebugMode) debugPrint('[Notificaciones] Error al cancelar: $e');
    }
  }

  /// Borra todos los avisos (al cerrar sesión o eliminar la cuenta), para que
  /// otra persona que use el mismo teléfono no reciba los recordatorios.
  Future<void> cancelarTodas() async {
    if (!_soportado || !_listo) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      if (kDebugMode) debugPrint('[Notificaciones] Error al cancelar todo: $e');
    }
  }

  /// Deja programados exactamente los avisos de estas tareas (al iniciar
  /// sesión o abrir la app).
  Future<void> sincronizar(List<Tarea> tareas) async {
    if (!_soportado || !_listo) return;
    await cancelarTodas();
    for (final t in tareas) {
      await programarTarea(t);
    }
  }

  Future<void> _programar({
    required int id,
    required DateTime cuando,
    required String titulo,
    required String cuerpo,
  }) async {
    if (!cuando.isAfter(DateTime.now())) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        // Se convierte el mismo instante a UTC: así no hace falta saber la
        // zona horaria del teléfono para que el aviso salga a la hora correcta.
        scheduledDate: tz.TZDateTime.from(cuando, tz.UTC),
        notificationDetails: _detalles,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: titulo,
        body: cuerpo,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[Notificaciones] Error al programar: $e');
    }
  }

  /// Convierte el id de texto de la tarea en un número estable (el plugin
  /// pide un int). [n] distingue el aviso de 1 día (0) del de 1 hora (1).
  static int _idAviso(String tareaId, int n) {
    var h = 0;
    for (final c in tareaId.codeUnits) {
      h = (h * 31 + c) % 1000000007;
    }
    return (h % 1000000000) * 2 + n;
  }
}
