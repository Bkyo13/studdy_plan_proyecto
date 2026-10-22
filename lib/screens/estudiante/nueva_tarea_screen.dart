import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../providers/auth_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formato_fecha.dart';
import '../../utils/mensajes.dart';
import '../../widgets/encabezado_interno.dart';

/// Formulario de nueva tarea. Si recibe [tarea], funciona en modo edición.
class NuevaTareaScreen extends StatefulWidget {
  const NuevaTareaScreen({super.key, this.tarea});

  final Tarea? tarea;

  @override
  State<NuevaTareaScreen> createState() => _NuevaTareaScreenState();
}

class _NuevaTareaScreenState extends State<NuevaTareaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _fechaCtrl = TextEditingController();

  int? _materiaId;
  DateTime? _fecha;
  Prioridad _prioridad = Prioridad.alta;

  bool get _editando => widget.tarea != null;

  @override
  void initState() {
    super.initState();
    final materias = context.read<MateriaProvider>().materias;
    final t = widget.tarea;
    if (t != null) {
      _nombreCtrl.text = t.nombre;
      _descripcionCtrl.text = t.descripcion;
      _fecha = t.fechaEntrega;
      _fechaCtrl.text = FormatoFecha.entrega(t.fechaEntrega);
      _prioridad = t.prioridad;
      _materiaId = t.materiaId;
    } else if (materias.isNotEmpty) {
      _materiaId = materias.first.id;
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
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fecha != null && _fecha!.isAfter(hoy) ? _fecha! : hoy,
      firstDate: hoy,
      lastDate: DateTime(ahora.year + 2, 12, 31),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: _fecha != null
          ? TimeOfDay(hour: _fecha!.hour, minute: _fecha!.minute)
          : const TimeOfDay(hour: 23, minute: 59),
    );
    if (!mounted) return;
    final h = hora ?? const TimeOfDay(hour: 23, minute: 59);
    final elegida = DateTime(fecha.year, fecha.month, fecha.day, h.hour, h.minute);
    setState(() {
      _fecha = elegida;
      _fechaCtrl.text = FormatoFecha.entrega(elegida);
    });
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;
    final usuario = context.read<AuthProvider>().usuarioActual;
    final materiaId = _materiaId;
    final fecha = _fecha;
    if (usuario == null || materiaId == null || fecha == null) return;

    final tareas = context.read<TareaProvider>();
    if (_editando) {
      tareas.actualizar(
        id: widget.tarea!.id,
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        fechaEntrega: fecha,
        prioridad: _prioridad,
        materiaId: materiaId,
      );
    } else {
      tareas.agregar(
        nombre: _nombreCtrl.text.trim(),
        descripcion: _descripcionCtrl.text.trim(),
        fechaEntrega: fecha,
        prioridad: _prioridad,
        materiaId: materiaId,
        estudianteId: usuario.id,
      );
    }
    mostrarConfirmacion(
      context,
      _editando ? 'Cambios guardados' : 'Tarea guardada',
    );
    Navigator.of(context).pop();
  }

  Widget _campo(String etiqueta, Widget campo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta, style: AppText.labelCampo),
        const SizedBox(height: 8),
        campo,
      ],
    );
  }

  Widget _campoNombre() {
    return _campo(
      'Nombre de la tarea',
      TextFormField(
        controller: _nombreCtrl,
        textCapitalization: TextCapitalization.sentences,
        decoration: AppDecor.campo(
          hint: 'Ej. Resolver problemario',
          icono: Icons.edit_note_outlined,
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
      ),
    );
  }

  Widget _campoMateria() {
    final materias = context.watch<MateriaProvider>().materias;
    return _campo(
      'Materia',
      DropdownButtonFormField<int>(
        initialValue: _materiaId,
        isExpanded: true,
        decoration: AppDecor.campo(
          hint: 'Selecciona una materia',
          icono: Icons.menu_book_outlined,
        ),
        items: materias
            .map(
              (m) => DropdownMenuItem<int>(
                value: m.id,
                child: Text(m.nombre, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (v) => setState(() => _materiaId = v),
        validator: (v) => v == null ? 'Selecciona una materia' : null,
      ),
    );
  }

  Widget _campoDescripcion() {
    return _campo(
      'Descripción',
      TextFormField(
        controller: _descripcionCtrl,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        decoration: AppDecor.campo(hint: 'Instrucciones o notas de la tarea'),
      ),
    );
  }

  Widget _campoFecha() {
    return _campo(
      'Fecha y hora de entrega',
      TextFormField(
        controller: _fechaCtrl,
        readOnly: true,
        onTap: _elegirFecha,
        decoration: AppDecor.campo(
          hint: 'Selecciona fecha y hora',
          icono: Icons.calendar_today_outlined,
          sufijo: const Icon(Icons.edit_outlined, color: AppColors.textoSuave),
        ),
        validator: (v) =>
            (_fecha == null) ? 'Selecciona la fecha de entrega' : null,
      ),
    );
  }

  Widget _chipPrioridad(Prioridad prioridad, String texto) {
    final seleccionado = _prioridad == prioridad;
    final color = AppColors.paraPrioridad(prioridad);
    return Expanded(
      child: Material(
        color: seleccionado ? color : Colors.white,
        shape: StadiumBorder(
          side: BorderSide(color: seleccionado ? color : AppColors.borde),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => setState(() => _prioridad = prioridad),
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                texto,
                style: TextStyle(
                  fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w400,
                  color: seleccionado ? Colors.white : AppColors.textoSuave,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectorPrioridad() {
    return _campo(
      'Prioridad',
      Row(
        children: [
          _chipPrioridad(Prioridad.alta, 'Alta'),
          const SizedBox(width: 12),
          _chipPrioridad(Prioridad.media, 'Media'),
          const SizedBox(width: 12),
          _chipPrioridad(Prioridad.baja, 'Baja'),
        ],
      ),
    );
  }

  Widget _formulario() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _campoNombre(),
          const SizedBox(height: 20),
          _campoMateria(),
          const SizedBox(height: 20),
          _campoDescripcion(),
          const SizedBox(height: 20),
          _campoFecha(),
          const SizedBox(height: 20),
          _selectorPrioridad(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _botonGuardar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pantalla,
        8,
        AppSpacing.pantalla,
        24,
      ),
      child: ElevatedButton(
        onPressed: _guardar,
        style: AppDecor.botonPrimario(),
        child: Text(
          _editando ? 'Guardar cambios' : 'Guardar tarea',
          style: AppText.boton,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      body: SafeArea(
        child: Column(
          children: [
            EncabezadoInterno(titulo: _editando ? 'Editar tarea' : 'Nueva tarea'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
                child: _formulario(),
              ),
            ),
            _botonGuardar(),
          ],
        ),
      ),
    );
  }
}