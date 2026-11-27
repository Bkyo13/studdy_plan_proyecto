import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Días feriados oficiales de México, de la API pública de Nager.Date
/// (sin clave de API).
///
/// - Se piden por año y se guardan en el teléfono: después funcionan sin
///   internet y no se vuelve a llamar a la API cada vez que se abre la app.
/// - La API cambió de dirección y de formato (v4); por si acaso, si la nueva
///   falla se intenta la anterior (v3).
/// - Si no hay internet ni copia guardada, la app sigue funcionando igual,
///   solo sin los avisos de feriado.
class FeriadoProvider extends ChangeNotifier {
  static const _pais = 'MX';
  static const _clavePrefijo = 'feriados_mx_';

  /// Nombres en español de los feriados oficiales (la API v4 los da en
  /// inglés). Si llega uno que no está aquí, se muestra el de la API.
  static const _nombresEnEspanol = {
    "New Year's Day": 'Año Nuevo',
    'Constitution Day': 'Día de la Constitución',
    "Benito Juárez's birthday": 'Natalicio de Benito Juárez',
    "Benito Juárez's Birthday": 'Natalicio de Benito Juárez',
    'Labour Day': 'Día del Trabajo',
    'Labor Day': 'Día del Trabajo',
    'Independence Day': 'Día de la Independencia',
    'Revolution Day': 'Día de la Revolución',
    'Christmas Day': 'Navidad',
    'Change of Federal Government': 'Transmisión del Poder Ejecutivo Federal',
    'Inauguration Day': 'Transmisión del Poder Ejecutivo Federal',
  };

  static void _log(String mensaje) {
    if (kDebugMode) debugPrint(mensaje);
  }

  /// Fecha (sin hora) → nombre del feriado.
  final Map<DateTime, String> _feriados = {};
  final Set<int> _aniosCargados = {};
  final Set<int> _aniosEnCurso = {};

  FeriadoProvider() {
    final anio = DateTime.now().year;
    cargar(anio);
    cargar(anio + 1);
  }

  /// Nombre del feriado de ese día, o null si es día normal.
  String? feriadoEn(DateTime fecha) =>
      _feriados[DateTime(fecha.year, fecha.month, fecha.day)];

  /// Carga los feriados de un año (primero de la copia guardada; si no hay,
  /// de la API). Llamarla varias veces no repite el trabajo.
  Future<void> cargar(int anio) async {
    if (_aniosCargados.contains(anio) || _aniosEnCurso.contains(anio)) return;
    _aniosEnCurso.add(anio);
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString('$_clavePrefijo$anio');
      if (guardado != null) {
        _agregar(Map<String, String>.from(jsonDecode(guardado) as Map));
        _aniosCargados.add(anio);
        return;
      }
      final desdeApi = await _pedirALaApi(anio);
      if (desdeApi.isEmpty) return;
      _agregar(desdeApi);
      _aniosCargados.add(anio);
      await prefs.setString('$_clavePrefijo$anio', jsonEncode(desdeApi));
      _log('[Feriados] $anio: ${desdeApi.length} feriados cargados de la API.');
    } catch (e) {
      _log('[Feriados] No se pudieron cargar los de $anio: $e');
    } finally {
      _aniosEnCurso.remove(anio);
    }
  }

  void _agregar(Map<String, String> porFecha) {
    porFecha.forEach((texto, nombre) {
      final f = DateTime.tryParse(texto);
      if (f != null) _feriados[DateTime(f.year, f.month, f.day)] = nombre;
    });
    notifyListeners();
  }

  /// Devuelve {'2026-09-16': 'Día de la Independencia', ...} o vacío.
  Future<Map<String, String>> _pedirALaApi(int anio) async {
    final intentos = [
      Uri.parse('https://nagerholidays.com/api/v4/Holidays/$_pais/$anio'),
      Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$anio/$_pais'),
    ];
    for (final url in intentos) {
      try {
        final r = await http.get(url).timeout(const Duration(seconds: 10));
        if (r.statusCode != 200) {
          _log('[Feriados] ${url.host} respondió ${r.statusCode}');
          continue;
        }
        final datos = jsonDecode(r.body);
        if (datos is! List) continue;
        final resultado = <String, String>{};
        for (final item in datos.whereType<Map<String, dynamic>>()) {
          if (!_esNacional(item)) continue;
          final fecha = item['date'] as String?;
          if (fecha == null) continue;
          // v3 trae el nombre en español en 'localName'; v4 solo en inglés.
          final local = item['localName'] as String?;
          final ingles = item['name'] as String? ?? '';
          resultado[fecha.substring(0, 10)] =
              local ?? _nombresEnEspanol[ingles] ?? ingles;
        }
        if (resultado.isNotEmpty) return resultado;
      } catch (e) {
        _log('[Feriados] Falló ${url.host}: $e');
      }
    }
    return {};
  }

  /// Solo feriados oficiales de todo el país (no regionales ni de bancos).
  bool _esNacional(Map<String, dynamic> item) {
    // Formato v4
    if (item.containsKey('nationalHoliday')) {
      final tipos = (item['holidayTypes'] as List?)?.cast<Object?>() ?? const [];
      return item['nationalHoliday'] == true &&
          (tipos.isEmpty || tipos.contains('Public'));
    }
    // Formato v3
    final tipos = (item['types'] as List?)?.cast<Object?>() ?? const [];
    return item['global'] != false &&
        (tipos.isEmpty || tipos.contains('Public'));
  }
}
