enum Rol { estudiante, administrador, tutor }

enum Prioridad { alta, media, baja }

enum Estado { pendiente, completada }

extension RolTexto on Rol {
  String get etiqueta => switch (this) {
        Rol.estudiante => 'Estudiante',
        Rol.administrador => 'Administrador',
        Rol.tutor => 'Tutor',
      };

  String get descripcion => switch (this) {
        Rol.estudiante => 'Organiza tus tareas y fechas de entrega.',
        Rol.administrador => 'Gestiona las materias de la app.',
        Rol.tutor => 'Consulta el avance de un estudiante.',
      };
}
