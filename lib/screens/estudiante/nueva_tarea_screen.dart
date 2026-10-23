import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/materia.dart';
import '../../models/tarea.dart';
import '../../providers/auth_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato_fecha.dart';
import '../../utils/mensajes.dart';
import '../../widgets/boton_circular.dart';

/// Formulario del Estudiante: crea una tarea nueva o edita una existente.
class NuevaTareaScreen extends StatefulWidget {
  /// Si se pasa una tarea, la pantalla funciona como "Editar tarea".
  final Tarea? tarea;

  const NuevaTareaScreen({super.key, this.tarea});

  @override
  State<NuevaTareaScreen> createState() => _NuevaTareaScreenState();
}

class _NuevaTareaScreenState extends State<NuevaTareaScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _fechaCtrl;

  int? _materiaId;
  DateTime? _fecha;
  Prioridad _prioridad = Prioridad.alta;

  bool get _editando => widget.tarea != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tarea;
    _nombreCtrl = TextEditingController(text: t?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: t?.descripcion ?? '');
    _fechaCtrl = TextEditingController(
      text: t == null ? '' : formatoEntrega(t.fechaEntrega),
    );
    if (t != null) {
      _materiaId = t.materiaId;
      _fecha = t.fechaEntrega;
      _prioridad = t.prioridad;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _fechaCtrl.dispose();
    super.dispose();
  }

  Future<void> _elegirFecha() async {
    FocusScope.of(context).unfocus();
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final dia = await showDatePicker(
      context: context,
      initialDate: (_fecha != null && !_fecha!.isBefore(hoy)) ? _fecha! : hoy,
      firstDate: hoy,
      lastDate: DateTime(ahora.year + 2),
    );
    if (dia == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _fecha ?? DateTime(ahora.year, ahora.month, ahora.day, 23, 59),
      ),
    );
    if (hora == null || !mounted) return;

    final elegida = DateTime(dia.year, dia.month, dia.day, hora.hour, hora.minute);
    setState(() {
      _fecha = elegida;
      _fechaCtrl.text = formatoEntrega(elegida);
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final usuario = context.read<AuthProvider>().usuarioActual;
    if (usuario == null) return;
    final provider = context.read<TareaProvider>();

    if (_editando) {
      provider.actualizar(
        id: widget.tarea!.id,
        nombre: _nombreCtrl.text,
        descripcion: _descripcionCtrl.text,
        fechaEntrega: _fecha!,
        prioridad: _prioridad,
        materiaId: _materiaId!,
      );
    } else {
      provider.agregar(
        nombre: _nombreCtrl.text,
        descripcion: _descripcionCtrl.text,
        fechaEntrega: _fecha!,
        prioridad: _prioridad,
        materiaId: _materiaId!,
        estudianteId: usuario.id,
      );
    }
    mostrarMensaje(context, _editando ? 'Tarea actualizada' : 'Tarea guardada');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final materias = context.watch<MateriaProvider>().materias;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pantalla),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  BotonCircular(
                    icono: Icons.arrow_back_ios_new,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _editando ? 'Editar tarea' : 'Nueva Tarea',
                    style: AppText.tituloSeccion,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.entreSecciones),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Nombre de la tarea', style: AppText.labelCampo),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nombreCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? 'Escribe el nombre de la tarea'
                              : null,
                          decoration: AppDecor.campo(
                            hint: 'Ej: Preparar presentación final',
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Materia', style: AppText.labelCampo),
                        const SizedBox(height: 8),
                        _campoMateria(materias),
                        const SizedBox(height: 20),
                        const Text('Descripción', style: AppText.labelCampo),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _descripcionCtrl,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: AppDecor.campo(
                            hint: 'Detalla los requerimientos o apuntes importantes...',
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Fecha de entrega', style: AppText.labelCampo),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _fechaCtrl,
                          readOnly: true,
                          onTap: _elegirFecha,
                          validator: (_) =>
                              _fecha == null ? 'Elige la fecha de entrega' : null,
                          decoration: AppDecor.campo(
                            hint: 'Selecciona fecha y hora',
                            icono: Icons.calendar_today_outlined,
                            sufijo: const Icon(
                              Icons.edit_outlined,
                              color: AppColors.textoSuave,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Prioridad', style: AppText.labelCampo),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final p in Prioridad.values) ...[
                              Expanded(child: _chipPrioridad(p)),
                              if (p != Prioridad.values.last) const SizedBox(width: 12),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _guardar,
                style: AppDecor.botonPrimario(),
                child: Text(
                  _editando ? 'Guardar cambios' : 'Guardar tarea',
                  style: AppText.boton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Selector de materia con validación (usa FormField para poder validar).
  Widget _campoMateria(List<Materia> materias) {
    return FormField<int>(
      initialValue: _materiaId,
      validator: (v) => v == null ? 'Selecciona una materia' : null,
      builder: (state) {
        return InputDecorator(
          decoration: AppDecor.campo(
            hint: '',
            icono: Icons.menu_book_outlined,
          ).copyWith(
            errorText: state.errorText,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          isEmpty: state.value == null,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: state.value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(AppRadius.campo),
              hint: const Text(
                'Selecciona la materia',
                style: TextStyle(color: AppColors.textoSuave, fontSize: 16),
              ),
              items: [
                for (final m in materias)
                  DropdownMenuItem<int>(
                    value: m.id,
                    child: Text(m.nombre, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                state.didChange(v);
                setState(() => _materiaId = v);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _chipPrioridad(Prioridad p) {
    final seleccionado = p == _prioridad;
    final color = AppColors.paraPrioridad(p);
    final etiqueta = '${p.name[0].toUpperCase()}${p.name.substring(1)}';
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => setState(() => _prioridad = p),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: seleccionado ? color : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: seleccionado ? color : AppColors.borde),
        ),
        child: Text(
          etiqueta,
          style: TextStyle(
            fontSize: 15,
            fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
            color: seleccionado ? Colors.white : AppColors.textoSuave,
          ),
        ),
      ),
    );
  }
}
