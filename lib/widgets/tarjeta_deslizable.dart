import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/materia.dart';
import '../models/tarea.dart';
import '../theme/app_theme.dart';
import '../utils/animaciones.dart';
import 'tarjeta_tarea.dart';

/// Tarjeta de tarea pendiente que se puede deslizar:
///   → a la derecha: completar (fondo verde con palomita).
///   ← a la izquierda: borrar (fondo rojo suave, pide confirmación).
/// Al pasar el punto en que se activa, el ícono crece un poco y el teléfono
/// vibra ligeramente, para que se sienta cuándo "ya cuenta".
class TarjetaDeslizable extends StatefulWidget {
  final Tarea tarea;
  final Materia? materia;
  final VoidCallback onTap;
  final VoidCallback onCompletar;
  final VoidCallback onEliminar;

  const TarjetaDeslizable({
    super.key,
    required this.tarea,
    required this.materia,
    required this.onTap,
    required this.onCompletar,
    required this.onEliminar,
  });

  @override
  State<TarjetaDeslizable> createState() => _TarjetaDeslizableState();
}

class _TarjetaDeslizableState extends State<TarjetaDeslizable> {
  bool _alcanzado = false;

  Future<bool> _confirmarBorrado() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Seguro que quieres eliminar "${widget.tarea.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: AppColors.peligro,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmado != true) setState(() => _alcanzado = false);
    return confirmado == true;
  }

  Widget _fondo({
    required Color color,
    required IconData icono,
    required String texto,
    required Alignment alineacion,
  }) {
    final duracion = Animaciones.duracion(context, Animaciones.rapida);
    final contenido = [
      AnimatedScale(
        scale: _alcanzado ? 1.2 : 1,
        duration: duracion,
        curve: Animaciones.curva,
        child: Icon(icono, color: Colors.white, size: 26),
      ),
      const SizedBox(width: 8),
      Text(
        texto,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ];
    return Container(
      alignment: alineacion,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.tarjeta),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alineacion == Alignment.centerLeft
            ? contenido
            : contenido.reversed.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('deslizable-${widget.tarea.id}'),
      direction: DismissDirection.horizontal,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.35,
        DismissDirection.endToStart: 0.35,
      },
      movementDuration: Animaciones.duracion(context, Animaciones.normal),
      onUpdate: (detalles) {
        if (detalles.reached != _alcanzado) {
          if (detalles.reached) HapticFeedback.selectionClick();
          setState(() => _alcanzado = detalles.reached);
        }
      },
      confirmDismiss: (direccion) async {
        if (direccion == DismissDirection.endToStart) {
          return _confirmarBorrado();
        }
        return true;
      },
      onDismissed: (direccion) {
        if (direccion == DismissDirection.startToEnd) {
          widget.onCompletar();
        } else {
          widget.onEliminar();
        }
      },
      background: _fondo(
        color: AppColors.verde,
        icono: Icons.check_circle_rounded,
        texto: 'Completar',
        alineacion: Alignment.centerLeft,
      ),
      secondaryBackground: _fondo(
        color: AppColors.peligro,
        icono: Icons.delete_outline_rounded,
        texto: 'Eliminar',
        alineacion: Alignment.centerRight,
      ),
      child: TarjetaTarea(
        tarea: widget.tarea,
        materia: widget.materia,
        onTap: widget.onTap,
      ),
    );
  }
}
