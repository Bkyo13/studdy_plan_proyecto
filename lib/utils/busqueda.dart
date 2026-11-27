import '../models/tarea.dart';

/// Quita acentos y mayúsculas para comparar ("Matemáticas" = "matematicas").
String normalizar(String texto) {
  const con = 'áéíóúüñ';
  const sin = 'aeiouun';
  final minusculas = texto.toLowerCase().trim();
  final buffer = StringBuffer();
  for (final letra in minusculas.split('')) {
    final i = con.indexOf(letra);
    buffer.write(i == -1 ? letra : sin[i]);
  }
  return buffer.toString();
}

/// ¿La tarea coincide con lo que se escribió en el buscador? Busca en el
/// nombre, la descripción, los pasos y el nombre de la materia. Con la
/// búsqueda vacía, todas coinciden. Cada palabra debe aparecer en algún lado
/// ("ensayo historia" encuentra "Ensayo" de la materia "Historia").
bool coincideBusqueda(Tarea tarea, String busqueda, {String? materia}) {
  final palabras =
      normalizar(busqueda).split(' ').where((p) => p.isNotEmpty).toList();
  if (palabras.isEmpty) return true;
  final texto = normalizar([
    tarea.nombre,
    tarea.descripcion,
    materia ?? '',
    ...tarea.subtareas.map((s) => s.texto),
  ].join(' '));
  return palabras.every(texto.contains);
}
