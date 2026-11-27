/// Un paso dentro de una tarea ("Buscar fuentes", "Hacer el borrador"...).
/// Se guarda dentro del documento de la tarea, en la lista `subtareas`.
class Subtarea {
  final String texto;
  final bool hecha;

  const Subtarea({required this.texto, this.hecha = false});

  Subtarea alternada() => Subtarea(texto: texto, hecha: !hecha);

  factory Subtarea.desdeMapa(Map<String, dynamic> datos) => Subtarea(
        texto: datos['texto'] as String? ?? '',
        hecha: datos['hecha'] as bool? ?? false,
      );

  Map<String, dynamic> aMapa() => {'texto': texto, 'hecha': hecha};
}
