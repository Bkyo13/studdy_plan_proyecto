import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/registro_xp.dart';
import '../../providers/auth_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/animaciones.dart';
import '../../utils/color_hex.dart';
import '../../widgets/boton_circular.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/tarjeta_dato.dart';

/// "Mi progreso": estadísticas del estudiante a partir de su historial de XP
/// (RegistroXP). Las gráficas están hechas con widgets de Flutter (sin
/// paquetes) y crecen una sola vez, suave, al abrir la pantalla.
class ProgresoScreen extends StatelessWidget {
  const ProgresoScreen({super.key});

  static const _semanas = 6;
  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// Lunes (sin hora) de la semana de [f].
  static DateTime _lunesDe(DateTime f) {
    final dia = DateTime(f.year, f.month, f.day);
    return dia.subtract(Duration(days: dia.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final materias = context.watch<MateriaProvider>();
    final registros = usuario == null
        ? const <RegistroXP>[]
        : context.watch<TareaProvider>().registrosXP(usuario.id);

    final xpTotal = registros.fold<int>(0, (t, r) => t + r.puntos);
    final aTiempo = registros.where((r) => r.motivo == 'a_tiempo').length;
    final tarde = registros.where((r) => r.motivo == 'tarde').length;
    final rapidas = registros.where((r) => r.motivo == 'muy_rapido').length;
    final conFecha = aTiempo + tarde;
    final porcentaje = conFecha == 0 ? 0 : (aTiempo * 100 / conFecha).round();

    // XP de las últimas 6 semanas (de la más vieja a la actual).
    final lunesActual = _lunesDe(DateTime.now());
    final semanas = [
      for (var i = _semanas - 1; i >= 0; i--)
        lunesActual.subtract(Duration(days: 7 * i)),
    ];
    final xpPorSemana = {for (final s in semanas) s: 0};
    for (final r in registros) {
      final lunes = _lunesDe(r.fecha);
      if (xpPorSemana.containsKey(lunes)) {
        xpPorSemana[lunes] = xpPorSemana[lunes]! + r.puntos;
      }
    }

    // Tareas completadas por materia (de más a menos).
    final porMateria = <String, int>{};
    for (final r in registros) {
      porMateria[r.materiaId] = (porMateria[r.materiaId] ?? 0) + 1;
    }
    final materiasOrdenadas = porMateria.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.pantalla),
          children: [
            Row(
              children: [
                BotonCircular(
                  icono: Icons.arrow_back_ios_new,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Mi progreso', style: AppText.tituloPantalla),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.entreSecciones),
            if (registros.isEmpty)
              const EstadoVacio(
                icono: Icons.insights_outlined,
                titulo: 'Todavía no hay datos',
                mensaje: 'Completa tus primeras tareas y aquí verás tu avance.',
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TarjetaDato(
                      icono: Icons.military_tech_outlined,
                      valor: '$xpTotal',
                      etiqueta: 'XP total',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.entreTarjetas),
                  Expanded(
                    child: TarjetaDato(
                      icono: Icons.schedule_outlined,
                      valor: '$porcentaje%',
                      etiqueta: 'A tiempo',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.entreSecciones),
              _Tarjeta(
                titulo: 'XP por semana',
                child: _GraficaSemanas(
                  semanas: semanas,
                  valores: [for (final s in semanas) xpPorSemana[s]!],
                  etiqueta: (s) => '${s.day} ${_meses[s.month - 1]}',
                ),
              ),
              const SizedBox(height: AppSpacing.entreTarjetas),
              _Tarjeta(
                titulo: 'Entregas',
                child: _BarraEntregas(
                  aTiempo: aTiempo,
                  tarde: tarde,
                  rapidas: rapidas,
                ),
              ),
              const SizedBox(height: AppSpacing.entreTarjetas),
              _Tarjeta(
                titulo: 'Completadas por materia',
                child: Column(
                  children: [
                    for (final e in materiasOrdenadas)
                      _FilaMateria(
                        nombre: materias.porId(e.key)?.nombre ?? 'Sin materia',
                        color: colorDesdeHex(
                          materias.porId(e.key)?.color ?? '#9A9992',
                        ),
                        cantidad: e.value,
                        maximo: materiasOrdenadas.first.value,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tarjeta blanca con título, igual a las demás de la app.
class _Tarjeta extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _Tarjeta({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
      decoration: AppDecor.tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AppText.tituloTarjeta),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Valor de 0 a 1 que crece una vez al abrir (para que las barras "se
/// llenen"). Con "Reducir movimiento" aparece completo de inmediato.
class _Crecer extends StatelessWidget {
  final Widget Function(double t) builder;

  const _Crecer({required this.builder});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Animaciones.duracion(context, const Duration(milliseconds: 600)),
      curve: Animaciones.curva,
      builder: (_, t, _) => builder(t),
    );
  }
}

class _GraficaSemanas extends StatelessWidget {
  final List<DateTime> semanas;
  final List<int> valores;
  final String Function(DateTime) etiqueta;

  const _GraficaSemanas({
    required this.semanas,
    required this.valores,
    required this.etiqueta,
  });

  @override
  Widget build(BuildContext context) {
    const alto = 120.0;
    final maximo = valores.fold<int>(0, (m, v) => v > m ? v : m);
    return _Crecer(
      builder: (t) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < semanas.length; i++)
            Expanded(
              child: Column(
                children: [
                  Text(
                    valores[i] == 0 ? '' : '${valores[i]}',
                    style: AppText.pequeno,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: maximo == 0
                        ? 4
                        : 4 + (alto - 4) * (valores[i] / maximo) * t,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      // La semana actual en verde; las anteriores, más claras.
                      color: i == semanas.length - 1
                          ? AppColors.verde
                          : AppColors.verde.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    etiqueta(semanas[i]),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textoTenue,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BarraEntregas extends StatelessWidget {
  final int aTiempo;
  final int tarde;
  final int rapidas;

  const _BarraEntregas({
    required this.aTiempo,
    required this.tarde,
    required this.rapidas,
  });

  @override
  Widget build(BuildContext context) {
    final total = aTiempo + tarde;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total > 0)
          _Crecer(
            builder: (t) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: [
                    if (aTiempo > 0)
                      Expanded(
                        flex: (aTiempo * 1000 * t).round() + 1,
                        child: Container(color: AppColors.verde),
                      ),
                    if (tarde > 0)
                      Expanded(
                        flex: (tarde * 1000 * t).round() + 1,
                        child: Container(color: AppColors.peligro),
                      ),
                    Expanded(
                      flex: (total * 1000 * (1 - t)).round() + 1,
                      child: Container(color: AppColors.borde),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        _leyenda(AppColors.verde, 'A tiempo', aTiempo),
        _leyenda(AppColors.peligro, 'Tarde', tarde),
        if (rapidas > 0)
          _leyenda(AppColors.textoTenue, 'Sin XP (muy rápidas)', rapidas),
      ],
    );
  }

  Widget _leyenda(Color color, String texto, int cantidad) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: AppText.cuerpo)),
          Text(
            '$cantidad',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.texto,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaMateria extends StatelessWidget {
  final String nombre;
  final Color color;
  final int cantidad;
  final int maximo;

  const _FilaMateria({
    required this.nombre,
    required this.color,
    required this.cantidad,
    required this.maximo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nombre,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cuerpo,
                ),
              ),
              Text(
                '$cantidad',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.texto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Crecer(
            builder: (t) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: maximo == 0 ? 0 : cantidad / maximo * t,
                minHeight: 8,
                backgroundColor: AppColors.verdeClaro,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
