/// Materia del catálogo común que administra el Administrador. Se guarda en
/// Firestore en `materias/{id}`.
class Materia {
  final String id;
  final String nombre;
  final String color; // formato '#RRGGBB'

  const Materia({
    required this.id,
    required this.nombre,
    required this.color,
  });

  factory Materia.desdeMapa(String id, Map<String, dynamic> datos) {
    return Materia(
      id: id,
      nombre: datos['nombre'] as String? ?? '',
      color: datos['color'] as String? ?? '#758B75',
    );
  }

  Map<String, dynamic> aMapa() => {'nombre': nombre, 'color': color};
}
