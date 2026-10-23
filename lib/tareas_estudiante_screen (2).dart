import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/tarea.dart';
import '../../providers/auth_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/tarjeta_tarea.dart';
import 'detalle_tarea_screen.dart';

/// Pestaña Inicio: saludo y tareas pendientes (lista principal de la entrega).
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  static const _limiteInicial = 3;
  bool _verTodas = false;

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final materias = context.watch<MateriaProvider>();
    final pendientes = usuario == null
        ? <Tarea>[]
        : context.watch<TareaProvider>().tareasDe(usuario.id, estado: Estado.pendiente);

    final nombre = usuario?.nombre ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';
    final hayMas = pendientes.length > _limiteInicial;
    final visibles = (_verTodas || !hayMas)
        ? pendientes
        : pendientes.take(_limiteInicial).toList();

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
                  ],
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<String>(
                tooltip: 'Cuenta',
                onSelected: (_) => context.read<AuthProvider>().cerrarSesion(),
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'salir',
                    child: Text('Cerrar sesión'),
                  ),
                ],
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tareas pendientes (${pendientes.length})',
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
          else
            for (final tarea in visibles) ...[
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
}
