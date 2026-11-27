import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Buscador con lupa y botón para borrar lo escrito.
class CampoBusqueda extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const CampoBusqueda({
    super.key,
    required this.onChanged,
    this.hint = 'Buscar tarea',
  });

  @override
  State<CampoBusqueda> createState() => _CampoBusquedaState();
}

class _CampoBusquedaState extends State<CampoBusqueda> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _limpiar() {
    _ctrl.clear();
    widget.onChanged('');
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      textInputAction: TextInputAction.search,
      onChanged: (texto) {
        widget.onChanged(texto);
        setState(() {}); // para mostrar u ocultar la ×
      },
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      decoration: AppDecor.campo(
        hint: widget.hint,
        icono: Icons.search,
        sufijo: _ctrl.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Borrar búsqueda',
                icon: const Icon(Icons.close, color: AppColors.textoSuave),
                onPressed: _limpiar,
              ),
      ),
    );
  }
}
