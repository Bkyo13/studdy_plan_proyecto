// Formato de fechas en español, sin paquete intl.

const _dias = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];

const _meses = [
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

String _hora(DateTime f) {
  final h = f.hour.toString().padLeft(2, '0');
  final m = f.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Días de diferencia entre [fecha] y hoy (0 = hoy, 1 = mañana, -1 = ayer).
int _diasDesdeHoy(DateTime fecha) {
  final ahora = DateTime.now();
  final hoy = DateTime.utc(ahora.year, ahora.month, ahora.day);
  final dia = DateTime.utc(fecha.year, fecha.month, fecha.day);
  return dia.difference(hoy).inDays;
}

/// "Hoy, 14:00", "Mañana, 14:00" o "Viernes 18, 23:59".
String formatoEntrega(DateTime fecha) {
  final diff = _diasDesdeHoy(fecha);
  if (diff == 0) return 'Hoy, ${_hora(fecha)}';
  if (diff == 1) return 'Mañana, ${_hora(fecha)}';
  final nombreDia = _dias[fecha.weekday - 1];
  return '$nombreDia ${fecha.day}, ${_hora(fecha)}';
}

/// "Hoy", "Ayer", "Hace 3 días" u "Oct 12".
String formatoCompletado(DateTime fecha) {
  final atras = -_diasDesdeHoy(fecha);
  if (atras <= 0) return 'Hoy';
  if (atras == 1) return 'Ayer';
  if (atras <= 6) return 'Hace $atras días';
  return '${_meses[fecha.month - 1]} ${fecha.day}';
}

const _mesesLargos = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// "29 de octubre de 2026, 13:05".
String formatoFechaLarga(DateTime fecha) {
  return '${fecha.day} de ${_mesesLargos[fecha.month - 1]} de ${fecha.year}, ${_hora(fecha)}';
}
