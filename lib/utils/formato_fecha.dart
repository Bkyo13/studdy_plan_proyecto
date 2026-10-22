/// Helpers de fecha sin paquete intl.
class FormatoFecha {
  FormatoFecha._();

  static const List<String> _dias = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  static const List<String> _meses = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static DateTime _soloDia(DateTime f) => DateTime.utc(f.year, f.month, f.day);

  static String hora(DateTime f) {
    final h = f.hour.toString().padLeft(2, '0');
    final m = f.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// Hoy, 14:00 / Mañana, 14:00 / Viernes 18, 23:59
  static String entrega(DateTime fecha, {DateTime? ahora}) {
    final referencia = ahora ?? DateTime.now();
    final dif = _soloDia(fecha).difference(_soloDia(referencia)).inDays;
    if (dif == 0) return 'Hoy, ${hora(fecha)}';
    if (dif == 1) return 'Mañana, ${hora(fecha)}';
    return '${_dias[fecha.weekday - 1]} ${fecha.day}, ${hora(fecha)}';
  }

  /// Hoy / Ayer / Hace 3 días / Oct 12
  static String completado(DateTime fecha, {DateTime? ahora}) {
    final referencia = ahora ?? DateTime.now();
    final dif = _soloDia(referencia).difference(_soloDia(fecha)).inDays;
    if (dif <= 0) return 'Hoy';
    if (dif == 1) return 'Ayer';
    if (dif <= 6) return 'Hace $dif días';
    return '${_meses[fecha.month - 1]} ${fecha.day}';
  }
}