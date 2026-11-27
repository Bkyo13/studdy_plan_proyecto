import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/tarea.dart';
import '../providers/tarea_provider.dart';
import '../theme/app_theme.dart';
import '../utils/animaciones.dart';
import '../utils/mensajes.dart';
import '../utils/validadores.dart';

/// Checklist de pasos de una tarea, con barra de avance. Con [editable] en
/// false (tarea completada o vista del tutor) solo se muestra.
class ListaSubtareas extends StatefulWidget {
  final Tarea tarea;
  final bool editable;

  const ListaSubtareas({super.key, required this.tarea, this.editable = true});

  @override
  State<ListaSubtareas> createState() => _ListaSubtareasState();
}

class _ListaSubtareasState extends State<ListaSubtareas> {
  final _ctrl = TextEditingController();
  final _foco = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _agregar() {
    final texto = _ctrl.text.trim();
    if (texto.isEmpty) return;
    if (widget.tarea.subtareas.length >= Limites.subtareasPorTarea) {
      mostrarMensaje(
        context,
        'Máximo ${Limites.subtareasPorTarea} pasos por tarea',
        error: true,
      );
      return;
    }
    context.read<TareaProvider>().agregarSubtarea(widget.tarea.id, texto);
    _ctrl.clear();
    // Se queda en el campo para escribir el siguiente paso.
    _foco.requestFocus();
  }

  void _alternar(int indice) {
    final tarea = widget.tarea;
    final antes = tarea.subtareasHechas;
    context.read<TareaProvider>().alternarSubtarea(tarea.id, indice);
    // Aviso sencillo cuando se marca el último paso.
    if (antes == tarea.subtareas.length - 1 &&
        tarea.subtareasHechas == tarea.subtareas.length) {
      mostrarMensaje(
        context,
        'Terminaste todos los pasos. Ya puedes marcar la tarea como completada.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarea = widget.tarea;
    final pasos = tarea.subtareas;
    final total = pasos.length;

    if (total == 0 && !widget.editable) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'PASOS',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AppColors.textoTenue,
                ),
              ),
            ),
            if (total > 0)
              Text(
                '${tarea.subtareasHechas} de $total',
                style: AppText.pequeno,
              ),
          ],
        ),
        if (total > 0) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: tarea.avanceSubtareas),
              duration: Animaciones.duracion(context, Animaciones.normal),
              curve: Animaciones.curva,
              builder: (context, valor, child) => LinearProgressIndicator(
                value: valor,
                minHeight: 6,
                backgroundColor: AppColors.verdeClaro,
                color: AppColors.verde,
              ),
            ),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < total; i++) _fila(i, pasos[i]),
        ],
        if (widget.editable && total < Limites.subtareasPorTarea) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            focusNode: _foco,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(Limites.textoSubtarea),
            ],
            onSubmitted: (_) => _agregar(),
            decoration: AppDecor.campo(
              hint: total == 0
                  ? 'Divide tu tarea en pasos (ej. "Buscar fuentes")'
                  : 'Agregar otro paso',
              sufijo: IconButton(
                tooltip: 'Agregar paso',
                icon: const Icon(Icons.add, color: AppColors.verde),
                onPressed: _agregar,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _fila(int indice, Subtarea paso) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: widget.editable ? () => _alternar(indice) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Checkbox(
                value: paso.hecha,
                activeColor: AppColors.verde,
                onChanged: widget.editable ? (_) => _alternar(indice) : null,
              ),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: Animaciones.duracion(context, Animaciones.rapida),
                  style: TextStyle(
                    fontSize: 15,
                    color: paso.hecha ? AppColors.textoTenue : AppColors.texto,
                    decoration: paso.hecha
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  child: Text(paso.texto),
                ),
              ),
              if (widget.editable)
                IconButton(
                  tooltip: 'Quitar paso',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.textoTenue,
                  ),
                  onPressed: () => context
                      .read<TareaProvider>()
                      .eliminarSubtarea(widget.tarea.id, indice),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
