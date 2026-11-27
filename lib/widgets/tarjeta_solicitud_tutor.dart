import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/vinculo.dart';
import '../providers/auth_provider.dart';
import '../providers/vinculo_provider.dart';
import '../theme/app_theme.dart';
import '../utils/mensajes.dart';

/// Aviso en Inicio del estudiante: "Ana quiere ver tu avance", con los
/// botones Rechazar y Aceptar.
class TarjetaSolicitudTutor extends StatefulWidget {
  final Vinculo solicitud;

  const TarjetaSolicitudTutor({super.key, required this.solicitud});

  @override
  State<TarjetaSolicitudTutor> createState() => _TarjetaSolicitudTutorState();
}

class _TarjetaSolicitudTutorState extends State<TarjetaSolicitudTutor> {
  bool _enviando = false;

  Future<void> _responder({required bool aceptar}) async {
    setState(() => _enviando = true);
    final vinculos = context.read<VinculoProvider>();
    final tutorId = widget.solicitud.tutorId;
    final ok = aceptar
        ? await vinculos.aceptar(tutorId)
        : await vinculos.rechazar(tutorId);
    if (!mounted) return;
    setState(() => _enviando = false);
    if (!ok) {
      mostrarMensaje(
        context,
        'No se pudo responder. Revisa tu conexión.',
        error: true,
      );
      return;
    }
    mostrarMensaje(
      context,
      aceptar ? 'Listo, tu tutor ya puede ver tu avance' : 'Solicitud rechazada',
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutor = context.watch<AuthProvider>().porId(widget.solicitud.tutorId);
    final nombre = tutor?.nombre ?? 'Un tutor';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.verdeClaro,
        borderRadius: BorderRadius.circular(AppRadius.campo),
        border: Border.all(color: AppColors.verde.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.supervisor_account_outlined, color: AppColors.verde),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$nombre quiere ver tu avance',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.texto,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tutor == null
                          ? 'Podrá ver tus tareas y tu XP (no puede editarlas).'
                          : '${tutor.correo} podrá ver tus tareas y tu XP (no puede editarlas).',
                      style: AppText.pequeno,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _enviando ? null : () => _responder(aceptar: false),
                child: const Text(
                  'Rechazar',
                  style: TextStyle(color: AppColors.textoSuave),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _enviando ? null : () => _responder(aceptar: true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.verde),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
