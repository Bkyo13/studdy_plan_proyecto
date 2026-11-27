import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/mensaje_chat.dart';
import '../../models/tarea.dart';
import '../../providers/asistente_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/materia_provider.dart';
import '../../providers/tarea_provider.dart';
import '../../theme/app_theme.dart';

/// Pestaña "Asistente": chat con la IA, que conoce las tareas pendientes del
/// estudiante.
class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  static const _sugerencias = [
    '¿Qué tarea hago primero hoy?',
    'Organiza mi semana',
    '¿Tengo algo atrasado?',
    'Divide mi tarea más próxima en pasos',
  ];

  final _textoCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _textoCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar(String texto) async {
    final usuario = context.read<AuthProvider>().usuarioActual;
    if (usuario == null || texto.trim().isEmpty) return;
    final materias = context.read<MateriaProvider>();
    final pendientes = context
        .read<TareaProvider>()
        .tareasDe(usuario.id, estado: Estado.pendiente);
    _textoCtrl.clear();
    _bajar();
    await context.read<AsistenteProvider>().enviar(
          texto,
          nombreEstudiante: usuario.nombre,
          pendientes: pendientes,
          materiaPorId: materias.porId,
        );
    _bajar();
  }

  /// Lleva la lista al último mensaje.
  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final asistente = context.watch<AsistenteProvider>();
    final mensajes = asistente.mensajes;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pantalla,
              AppSpacing.pantalla,
              AppSpacing.pantalla,
              8,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Asistente', style: AppText.tituloPantalla),
                ),
                if (mensajes.isNotEmpty)
                  TextButton.icon(
                    onPressed: asistente.escribiendo
                        ? null
                        : context.read<AsistenteProvider>().limpiar,
                    icon: const Icon(Icons.refresh, color: AppColors.verde),
                    label: const Text(
                      'Nueva',
                      style: TextStyle(
                        color: AppColors.verde,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: mensajes.isEmpty
                ? _bienvenida()
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.pantalla,
                      vertical: 8,
                    ),
                    itemCount: mensajes.length + (asistente.escribiendo ? 1 : 0),
                    itemBuilder: (_, i) => i == mensajes.length
                        ? _burbujaPensando()
                        : _burbuja(mensajes[i]),
                  ),
          ),
          _barraEscribir(asistente.escribiendo),
        ],
      ),
    );
  }

  Widget _bienvenida() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pantalla),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.verdeClaro,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 36,
              color: AppColors.verde,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '¿En qué te ayudo?',
          textAlign: TextAlign.center,
          style: AppText.tituloSeccion,
        ),
        const SizedBox(height: 8),
        const Text(
          'Conozco tus tareas pendientes. Puedo ayudarte a priorizar, '
          'organizar tu semana o explicarte un tema.',
          textAlign: TextAlign.center,
          style: AppText.cuerpo,
        ),
        const SizedBox(height: 24),
        for (final s in _sugerencias) ...[
          OutlinedButton(
            onPressed: () => _enviar(s),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.borde),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.campo),
              ),
              alignment: Alignment.centerLeft,
            ),
            child: Text(
              s,
              style: const TextStyle(color: AppColors.texto, fontSize: 15),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        const Text(
          'Las respuestas las genera una IA y pueden tener errores.',
          textAlign: TextAlign.center,
          style: AppText.pequeno,
        ),
      ],
    );
  }

  Widget _burbuja(MensajeChat m) {
    final deUsuario = m.deUsuario;
    final fondo = deUsuario
        ? AppColors.verde
        : (m.esError ? const Color(0xFFF6E9E7) : Colors.white);
    final colorTexto = deUsuario
        ? Colors.white
        : (m.esError ? AppColors.peligro : AppColors.texto);

    return Align(
      alignment: deUsuario ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        // Mantener presionado copia el texto (útil para pegar pasos en notas).
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: m.texto));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Texto copiado'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(deUsuario ? 18 : 4),
              bottomRight: Radius.circular(deUsuario ? 4 : 18),
            ),
            border: deUsuario ? null : Border.all(color: AppColors.borde),
          ),
          child: Text(
            m.texto,
            style: TextStyle(fontSize: 15, height: 1.35, color: colorTexto),
          ),
        ),
      ),
    );
  }

  Widget _burbujaPensando() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borde),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.verde,
              ),
            ),
            SizedBox(width: 10),
            Text('Pensando...', style: TextStyle(color: AppColors.textoSuave)),
          ],
        ),
      ),
    );
  }

  Widget _barraEscribir(bool escribiendo) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borde)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _textoCtrl,
              minLines: 1,
              maxLines: 4,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Escribe tu pregunta...',
                border: InputBorder.none,
                counterText: '',
              ),
              onSubmitted: escribiendo ? null : _enviar,
            ),
          ),
          IconButton(
            onPressed: escribiendo ? null : () => _enviar(_textoCtrl.text),
            icon: const Icon(Icons.send_rounded),
            color: AppColors.verde,
            tooltip: 'Enviar',
          ),
        ],
      ),
    );
  }
}
