import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/materia.dart';
import '../../models/tarea.dart';
import '../../providers/auth_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/acciones_tarea.dart';
import '../../utils/color_hex.dart';
import '../../utils/mensajes.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_xp.dart';
import '../../widgets/tarjeta_deslizable.dart';
import 'detalle_tarea_screen.dart';
import 'perfil_screen.dart';

/// Pestaña Inicio: saludo y tareas pendientes (lista principal de la entrega).
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  static const _limiteInicial = 3;
  bool _verTodas = false;

  // Filtros (null = sin filtro). Se pueden combinar materia y prioridad.
  String? _filtroMateria;
  Prioridad? _filtroPrioridad;

  bool get _hayFiltros => _filtroMateria != null || _filtroPrioridad != null;

  bool _pasaFiltros(Tarea t) =>
      (_filtroMateria == null || t.materiaId == _filtroMateria) &&
      (_filtroPrioridad == null || t.prioridad == _filtroPrioridad);

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final materias = context.watch<MateriaProvider>();
    final tareas = context.watch<TareaProvider>();
    final pendientes = usuario == null
        ? <Tarea>[]
        : tareas.tareasDe(usuario.id, estado: Estado.pendiente);
    final xp = usuario == null ? 0 : tareas.xpDe(usuario.id);

    final nombre = usuario?.nombre ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    // Materias que aparecen en las pendientes del alumno (para los chips).
    final idsMaterias = pendientes.map((t) => t.materiaId).toSet();
    final materiasConTareas = materias.materias
        .where((m) => idsMaterias.contains(m.id))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    // Si la materia filtrada ya no tiene pendientes, el filtro se ignora.
    if (_filtroMateria != null && !idsMaterias.contains(_filtroMateria)) {
      _filtroMateria = null;
    }

    final filtradas = pendientes.where(_pasaFiltros).toList();
    // Las vencidas van en su propia sección, arriba y siempre completas.
    final atrasadas = filtradas.where((t) => t.vencida).toList();
    final aTiempo = filtradas.where((t) => !t.vencida).toList();
    final hayMas = aTiempo.length > _limiteInicial;
    final visibles = (_verTodas || !hayMas)
        ? aTiempo
        : aTiempo.take(_limiteInicial).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pantalla,
          AppSpacing.pantalla,
          AppSpacing.pantalla,
          96,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('StudyPlan', style: AppText.tituloPantalla),
                    const SizedBox(height: 4),
                    Text(
                      '¡Hola, $nombre! Organiza tu día.',
                      style: AppText.cuerpo,
                    ),
                    const SizedBox(height: 10),
                    // Al completar deslizando, el número sube contando.
                    InsigniaXp(xp: xp),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PerfilScreen()),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.verdeClaro,
                  child: Text(
                    inicial,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.verde,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.entreSecciones),
          if (pendientes.length >= 2) ...[
            _filtros(materiasConTareas),
            const SizedBox(height: AppSpacing.entreSecciones),
          ],
          if (atrasadas.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.peligro),
                const SizedBox(width: 8),
                Text(
                  'Atrasadas (${atrasadas.length})',
                  style: AppText.tituloSeccion.copyWith(color: AppColors.peligro),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final tarea in atrasadas) ...[
              _tarjeta(tarea, materias),
              const SizedBox(height: AppSpacing.entreTarjetas),
            ],
            const SizedBox(height: AppSpacing.entreSecciones - AppSpacing.entreTarjetas),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tareas pendientes (${aTiempo.length})',
                  style: AppText.tituloSeccion,
                ),
              ),
              if (hayMas)
                TextButton(
                  onPressed: () => setState(() => _verTodas = !_verTodas),
                  child: Text(
                    _verTodas ? 'Ver menos' : 'Ver todas',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.verde,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (pendientes.isEmpty)
            const EstadoVacio(
              titulo: 'No hay tareas pendientes',
              mensaje: 'Toca el botón + para agregar tu primera tarea.',
            )
          else if (filtradas.isEmpty)
            const EstadoVacio(
              icono: Icons.filter_alt_off_outlined,
              titulo: 'Ninguna tarea coincide',
              mensaje: 'Prueba con otros filtros o quítalos.',
            )
          else if (aTiempo.isEmpty)
            const EstadoVacio(
              titulo: 'Nada más por ahora',
              mensaje: 'Ponte al día con las atrasadas y vas perfecto.',
            )
          else
            for (final tarea in visibles) ...[
              _tarjeta(tarea, materias),
              const SizedBox(height: AppSpacing.entreTarjetas),
            ],
        ],
      ),
    );
  }

  /// Tarjeta que se desliza: → completar, ← eliminar. Usa el contexto de
  /// esta pantalla (no el de la tarjeta, que desaparece al deslizarla).
  Widget _tarjeta(Tarea tarea, MateriaProvider materias) {
    return TarjetaDeslizable(
      key: ValueKey(tarea.id),
      tarea: tarea,
      materia: materias.porId(tarea.materiaId),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DetalleTareaScreen(tareaId: tarea.id),
        ),
      ),
      onCompletar: () => completarTarea(context, tarea),
      onEliminar: () {
        context.read<TareaProvider>().eliminar(tarea.id);
        mostrarMensaje(context, 'Tarea eliminada');
      },
    );
  }

  /// Fila de chips: prioridades, materias y "Quitar filtros".
  Widget _filtros(List<Materia> materiasConTareas) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (_hayFiltros) ...[
            ActionChip(
              avatar: const Icon(Icons.close, size: 18, color: AppColors.peligro),
              label: const Text('Quitar filtros'),
              labelStyle: const TextStyle(
                color: AppColors.peligro,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.borde),
              onPressed: () => setState(() {
                _filtroMateria = null;
                _filtroPrioridad = null;
              }),
            ),
            const SizedBox(width: 8),
          ],
          for (final p in Prioridad.values) ...[
            _chip(
              texto: p.name[0].toUpperCase() + p.name.substring(1),
              color: AppColors.paraPrioridad(p),
              seleccionado: _filtroPrioridad == p,
              onTap: () => setState(
                () => _filtroPrioridad = _filtroPrioridad == p ? null : p,
              ),
            ),
            const SizedBox(width: 8),
          ],
          for (final m in materiasConTareas) ...[
            _chip(
              texto: m.nombre,
              color: colorDesdeHex(m.color),
              seleccionado: _filtroMateria == m.id,
              onTap: () => setState(
                () => _filtroMateria = _filtroMateria == m.id ? null : m.id,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _chip({
    required String texto,
    required Color color,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      avatar: CircleAvatar(radius: 6, backgroundColor: color),
      label: Text(texto),
      labelStyle: TextStyle(
        color: seleccionado ? AppColors.verde : AppColors.textoSuave,
        fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w500,
      ),
      selected: seleccionado,
      showCheckmark: false,
      selectedColor: AppColors.verdeClaro,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: seleccionado ? AppColors.verde : AppColors.borde,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
