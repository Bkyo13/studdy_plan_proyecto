import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/logro_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/mensajes.dart';
import '../../widgets/estado_vacio.dart';
import '../../widgets/insignia_xp.dart';
import '../../widgets/tarjeta_logro.dart';
import 'logro_detalle_screen.dart';

/// Lista de logros: obtenidos y bloqueados, con su XP requerido y su progreso.
class LogrosScreen extends StatefulWidget {
  const LogrosScreen({super.key});

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  @override
  void initState() {
    super.initState();
    // Al abrir la pestaña se revisa si ya se alcanzó algún logro (por ejemplo,
    // uno nuevo que creó el administrador).
    WidgetsBinding.instance.addPostFrameCallback((_) => _sincronizar());
  }

  void _sincronizar() {
    if (!mounted) return;
    final usuario = context.read<AuthProvider>().usuarioActual;
    if (usuario == null) return;
    final xp = context.read<TareaProvider>().xpDe(usuario.id);
    final nuevos = context.read<LogroProvider>().evaluar(usuario.id, xp);
    if (nuevos.isNotEmpty) {
      final nombres = nuevos.map((l) => l.nombre).join(', ');
      mostrarMensaje(context, '🏆 ¡Logro desbloqueado: $nombres!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthProvider>().usuarioActual;
    final logrosProvider = context.watch<LogroProvider>();
    final tareas = context.watch<TareaProvider>();

    final estudianteId = usuario?.id ?? -1;
    final xp = usuario == null ? 0 : tareas.xpDe(estudianteId);
    final todos = logrosProvider.logros;
    final obtenidos = todos
        .where((l) => logrosProvider.obtenido(estudianteId, l.id) != null)
        .toList();
    final bloqueados = todos
        .where((l) => logrosProvider.obtenido(estudianteId, l.id) == null)
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.pantalla),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Logros', style: AppText.tituloPantalla),
                    const SizedBox(height: 4),
                    Text(
                      '${obtenidos.length} de ${todos.length} desbloqueados',
                      style: AppText.cuerpo,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InsigniaXp(xp: xp),
            ],
          ),
          const SizedBox(height: AppSpacing.entreSecciones),
          if (todos.isEmpty)
            const EstadoVacio(
              icono: Icons.emoji_events_outlined,
              titulo: 'No hay logros disponibles',
              mensaje: 'El administrador todavía no ha creado logros.',
            )
          else ...[
            _seccion('Obtenidos (${obtenidos.length})'),
            if (obtenidos.isEmpty)
              const EstadoVacio(
                icono: Icons.emoji_events_outlined,
                titulo: 'Aún no tienes logros',
                mensaje: 'Completa tareas para ganar XP y desbloquearlos.',
              )
            else
              ..._tarjetas(obtenidos, estudianteId, xp, logrosProvider),
            const SizedBox(height: AppSpacing.entreSecciones),
            _seccion('Bloqueados (${bloqueados.length})'),
            if (bloqueados.isEmpty)
              const EstadoVacio(
                icono: Icons.verified_outlined,
                titulo: '¡Los tienes todos!',
                mensaje: 'Desbloqueaste todos los logros disponibles.',
              )
            else
              ..._tarjetas(bloqueados, estudianteId, xp, logrosProvider),
          ],
        ],
      ),
    );
  }

  Widget _seccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(titulo, style: AppText.tituloSeccion),
    );
  }

  List<Widget> _tarjetas(
    List logros,
    int estudianteId,
    int xp,
    LogroProvider provider,
  ) {
    return [
      for (final logro in logros) ...[
        TarjetaLogro(
          logro: logro,
          obtenido: provider.obtenido(estudianteId, logro.id),
          xpActual: xp,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LogroDetalleScreen(logroId: logro.id),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.entreTarjetas),
      ],
    ];
  }
}
