import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../providers/auth_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato_fecha.dart';
import '../../widgets/boton_circular.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/tarjeta_tarea.dart';
import 'detalle_tarea_screen.dart';

/// Pestaña Calendario: vista del mes con puntitos en los días que tienen
/// entregas, y abajo la lista de tareas del día elegido. Hecho con widgets
/// de Flutter, sin paquetes extra.
class CalendarioScreen extends StatefulWidget {
  const CalendarioScreen({super.key});

  @override
  State<CalendarioScreen> createState() => _CalendarioScreenState();
}

class _CalendarioScreenState extends State<CalendarioScreen> {
  static const _iniciales = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  /// Primer día del mes que se está viendo.
  late DateTime _mes;

  /// Día elegido (sin hora).
  late DateTime _diaElegido;

  @override
  void initState() {
    super.initState();
    final hoy = _soloDia(DateTime.now());
    _mes = DateTime(hoy.year, hoy.month);
    _diaElegido = hoy;
  }

  DateTime _soloDia(DateTime f) => DateTime(f.year, f.month, f.day);

  void _cambiarMes(int delta) {
    setState(() => _mes = DateTime(_mes.year, _mes.month + delta));
  }

  void _irAHoy() {
    final hoy = _soloDia(DateTime.now());
    setState(() {
      _mes = DateTime(hoy.year, hoy.month);
      _diaElegido = hoy;
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final materias = context.watch<MateriaProvider>();
    final tareas = usuario == null
        ? <Tarea>[]
        : context.watch<TareaProvider>().tareasDe(usuario.id);

    // Tareas agrupadas por día de entrega.
    final porDia = <DateTime, List<Tarea>>{};
    for (final t in tareas) {
      porDia.putIfAbsent(_soloDia(t.fechaEntrega), () => []).add(t);
    }
    final delDia = List<Tarea>.of(porDia[_diaElegido] ?? const <Tarea>[])
      ..sort((a, b) {
        // Primero las pendientes, luego por hora de entrega.
        if (a.estado != b.estado) {
          return a.estado == Estado.pendiente ? -1 : 1;
        }
        return a.fechaEntrega.compareTo(b.fechaEntrega);
      });

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pantalla),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Calendario', style: AppText.tituloPantalla),
              ),
              TextButton(
                onPressed: _irAHoy,
                child: const Text(
                  'Hoy',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.verde,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.entreSecciones),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppDecor.tarjeta(),
            child: Column(
              children: [
                _encabezadoMes(),
                const SizedBox(height: 16),
                _filaIniciales(),
                const SizedBox(height: 8),
                ..._semanas(porDia),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.entreSecciones),
          Text(formatoDiaLargo(_diaElegido), style: AppText.tituloSeccion),
          const SizedBox(height: 12),
          if (delDia.isEmpty)
            const EstadoVacio(
              icono: Icons.event_available_outlined,
              titulo: 'Sin entregas este día',
              mensaje: 'Elige otro día o agrega una tarea desde Inicio.',
            )
          else
            for (final tarea in delDia) ...[
              TarjetaTarea(
                tarea: tarea,
                materia: materias.porId(tarea.materiaId),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DetalleTareaScreen(tareaId: tarea.id),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.entreTarjetas),
            ],
        ],
      ),
    );
  }

  Widget _encabezadoMes() {
    return Row(
      children: [
        BotonCircular(
          icono: Icons.chevron_left,
          onPressed: () => _cambiarMes(-1),
        ),
        Expanded(
          child: Text(
            formatoMesAnio(_mes),
            textAlign: TextAlign.center,
            style: AppText.tituloTarjeta,
          ),
        ),
        BotonCircular(
          icono: Icons.chevron_right,
          onPressed: () => _cambiarMes(1),
        ),
      ],
    );
  }

  Widget _filaIniciales() {
    return Row(
      children: [
        for (final inicial in _iniciales)
          Expanded(
            child: Text(
              inicial,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textoTenue,
              ),
            ),
          ),
      ],
    );
  }

  /// Filas de 7 días. Los huecos antes del día 1 y después del último quedan vacíos.
  List<Widget> _semanas(Map<DateTime, List<Tarea>> porDia) {
    final diasEnMes = DateTime(_mes.year, _mes.month + 1, 0).day;
    final huecosInicio = _mes.weekday - 1; // lunes = 0
    final totalCeldas = ((huecosInicio + diasEnMes + 6) ~/ 7) * 7;

    final filas = <Widget>[];
    for (var inicio = 0; inicio < totalCeldas; inicio += 7) {
      filas.add(
        Row(
          children: [
            for (var i = inicio; i < inicio + 7; i++)
              Expanded(
                child: (i < huecosInicio || i >= huecosInicio + diasEnMes)
                    ? const SizedBox(height: 52)
                    : _celdaDia(
                        DateTime(_mes.year, _mes.month, i - huecosInicio + 1),
                        porDia,
                      ),
              ),
          ],
        ),
      );
    }
    return filas;
  }

  Widget _celdaDia(DateTime dia, Map<DateTime, List<Tarea>> porDia) {
    final hoy = _soloDia(DateTime.now());
    final esHoy = dia == hoy;
    final elegido = dia == _diaElegido;
    final tareasDia = porDia[dia] ?? const <Tarea>[];

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _diaElegido = dia),
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: elegido ? AppColors.verde : Colors.transparent,
                shape: BoxShape.circle,
                border: (esHoy && !elegido)
                    ? Border.all(color: AppColors.verde, width: 1.5)
                    : null,
              ),
              child: Text(
                '${dia.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: (elegido || esHoy) ? FontWeight.w700 : FontWeight.w500,
                  color: elegido ? Colors.white : AppColors.texto,
                ),
              ),
            ),
            const SizedBox(height: 3),
            _puntos(tareasDia),
          ],
        ),
      ),
    );
  }

  /// Hasta 3 puntitos: color de prioridad si está pendiente, gris si ya se completó.
  Widget _puntos(List<Tarea> tareasDia) {
    if (tareasDia.isEmpty) return const SizedBox(height: 6);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final t in tareasDia.take(3))
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: t.estado == Estado.completada
                  ? AppColors.textoTenue
                  : AppColors.paraPrioridad(t.prioridad),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}
