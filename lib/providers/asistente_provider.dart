import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../models/materia.dart';
import '../models/mensaje_chat.dart';
import '../models/tarea.dart';
import '../utils/formato_fecha.dart';

/// Asistente de estudio con IA (Gemini), a través de Firebase AI Logic.
///
/// No hay ninguna clave de API dentro de la app: las peticiones pasan por
/// Firebase, que usa la configuración del proyecto. En cada mensaje se le
/// manda a la IA la lista de tareas pendientes del estudiante, para que sus
/// respuestas tengan en cuenta lo que realmente tiene que entregar.
class AsistenteProvider extends ChangeNotifier {
  /// Modelo de Gemini. Los nombres cambian con el tiempo: si Firebase deja de
  /// aceptar este, se cambia aquí por el que recomiende su documentación.
  static const modelo = 'gemini-3.5-flash-lite';

  /// Cuántos mensajes anteriores se mandan como contexto (para no gastar de
  /// más la cuota gratis).
  static const _maxHistorial = 20;

  static void _log(String mensaje) {
    if (kDebugMode) debugPrint(mensaje);
  }

  final List<MensajeChat> _mensajes = [];
  bool _escribiendo = false;

  List<MensajeChat> get mensajes => List.unmodifiable(_mensajes);

  /// True mientras la IA está respondiendo.
  bool get escribiendo => _escribiendo;

  /// Borra la conversación (botón "Nueva conversación" o al cerrar sesión).
  void limpiar() {
    _mensajes.clear();
    _escribiendo = false;
    notifyListeners();
  }

  /// Manda la pregunta del estudiante y agrega la respuesta a la conversación.
  Future<void> enviar(
    String texto, {
    required String nombreEstudiante,
    required List<Tarea> pendientes,
    required Materia? Function(String id) materiaPorId,
  }) async {
    final pregunta = texto.trim();
    if (pregunta.isEmpty || _escribiendo) return;

    // Historial válido (sin avisos de error) ANTES de agregar la pregunta.
    final anteriores = _mensajes.where((m) => !m.esError).toList();
    final historial = anteriores.length > _maxHistorial
        ? anteriores.sublist(anteriores.length - _maxHistorial)
        : anteriores;

    _mensajes.add(MensajeChat(texto: pregunta, deUsuario: true));
    _escribiendo = true;
    notifyListeners();

    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: modelo,
        systemInstruction: Content.system(
          _instrucciones(nombreEstudiante, pendientes, materiaPorId),
        ),
      );
      final chat = model.startChat(
        history: [
          for (final m in historial)
            m.deUsuario
                ? Content.text(m.texto)
                : Content.model([TextPart(m.texto)]),
        ],
      );
      final respuesta = await chat.sendMessage(Content.text(pregunta));
      final textoRespuesta = respuesta.text?.trim();
      _mensajes.add(MensajeChat(
        texto: (textoRespuesta == null || textoRespuesta.isEmpty)
            ? 'No tengo una respuesta para eso. ¿Puedes preguntarlo de otra forma?'
            : textoRespuesta,
        deUsuario: false,
      ));
    } catch (e) {
      _log('[Asistente] Error al consultar la IA: $e');
      _mensajes.add(MensajeChat(
        texto: 'No pude responder en este momento. Revisa tu conexión a '
            'internet e intenta de nuevo.',
        deUsuario: false,
        esError: true,
      ));
    } finally {
      _escribiendo = false;
      notifyListeners();
    }
  }

  /// Instrucciones para la IA: quién es, cómo responder y las tareas
  /// pendientes del estudiante en este momento.
  String _instrucciones(
    String nombre,
    List<Tarea> pendientes,
    Materia? Function(String id) materiaPorId,
  ) {
    final ahora = DateTime.now();
    final lista = pendientes.isEmpty
        ? '(No tiene tareas pendientes.)'
        : pendientes.map((t) {
            final materia = materiaPorId(t.materiaId)?.nombre ?? 'Sin materia';
            final estado = t.vencida ? ' | YA VENCIDA' : '';
            final descripcion = t.descripcion.trim().isEmpty
                ? ''
                : ' | Descripción: ${t.descripcion.trim()}';
            return '- ${t.nombre} | Materia: $materia | Entrega: '
                '${formatoFechaLarga(t.fechaEntrega)} | Prioridad: '
                '${t.prioridad.name}$estado$descripcion';
          }).join('\n');

    return '''
Eres el asistente de estudio de StudyPlan, una app para que estudiantes del norte de Guanajuato, México, organicen sus tareas y entregas.
Hablas con $nombre. Fecha y hora actual: ${formatoFechaLarga(ahora)}.

Tareas pendientes de $nombre:
$lista

Cómo responder:
- Responde siempre en español de México, en tono amable, cercano y breve (máximo unos 150 palabras, salvo que te pidan más detalle).
- Usa la lista de tareas de arriba para ayudar a priorizar, organizar la semana o dividir una tarea en pasos. No inventes tareas, fechas ni materias que no estén en la lista.
- Tú no puedes crear, editar ni completar tareas; si te lo piden, explica que eso se hace desde la app.
- Si preguntan sobre un tema escolar, explícalo para que el estudiante aprenda; guíalo con pasos y ejemplos en lugar de hacerle la tarea completa.
- Escribe en texto plano: no uses Markdown, asteriscos ni encabezados. Para listas usa guiones al inicio de cada línea.
- Si te preguntan algo que no tiene que ver con la escuela o la organización, responde brevemente y regresa al tema.
''';
  }
}
