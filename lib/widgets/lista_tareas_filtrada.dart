import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tarea.dart';
import '../providers/tarea_provider.dart';
import '../screens/estudiante/detalle_tarea_screen.dart';
import '../theme/app_theme.dart';
import 'estado_vacio.dart';
import 'tarjeta_tarea.dart';
import 'tarjeta_tarea_completada.dart';

/// Filtro Pendientes / Completadas + lista de tarjetas (no desplazable por sí sola:
/// debe ir dentro de un scroll). En modo solo lectura (tutor) las tarjetas no abren detalle.
class ListaTareasFiltrada extends StatefulWidget {
  const ListaTareasFiltrada({
    super.key,
    required this.estudianteId,
    this.soloLectura = false,
  });

  final int estudianteId;
  final bool soloLectura;

  @override
  State<ListaTareasFiltrada> createState() => _ListaTareasFiltradaState();
}

class _ListaTareasFiltradaState extends State<ListaTareasFiltrada> {
  Estado _filtro = Estado.pendiente;

  Widget _chipFiltro(String texto, Estado estado) {
    final seleccionado = _filtro == estado;
    return Expanded(
      child: Material(
        color: seleccionado ? AppColors.verde : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(
            color: seleccionado ? AppColors.verde : AppColors.borde,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => setState(() => _filtro = estado),
          child: SizedBox(
            height: 44,
            child: Center(
              child: Text(
                texto,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: seleccionado ? Colors.white : AppColors.textoSuave,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filtros() {
    return Row(
      children: [
        _chipFiltro('Pendientes', Estado.pendiente),
        const SizedBox(width: 12),
        _chipFiltro('Completadas', Estado.completada),
      ],
    );
  }

  Widget _vacio() {
    final pendientes = _filtro == Estado.pendiente;
    return EstadoVacio(
      icono: pendientes ? Icons.inbox_outlined : Icons.check_circle_outline,
      titulo: pendientes ? 'No hay tareas pendientes' : 'No hay tareas completadas',
      texto: 'No hay elementos para mostrar.',
    );
  }

  Widget _tarjeta(Tarea tarea) {
    final Widget contenido = _filtro == Estado.pendiente
        ? TarjetaTarea(
            tarea: tarea,
            onTap: widget.soloLectura
                ? null
                : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetalleTareaScreen(tareaId: tarea.id),
                      ),
                    ),
          )
        : TarjetaTareaCompletada(tarea: tarea);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.entreTarjetas),
      child: contenido,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tareas = context
        .watch<TareaProvider>()
        .porEstudiante(widget.estudianteId, _filtro);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filtros(),
        const SizedBox(height: AppSpacing.entreSecciones),
        if (tareas.isEmpty) _vacio() else ...tareas.map(_tarjeta),
      ],
    );
  }
}