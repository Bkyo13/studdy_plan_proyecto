/// Nivel del estudiante según su XP total. Es solo cálculo (no se guarda en
/// Firestore): si el XP baja al deshacer una tarea, el nivel baja también.
class Nivel {
  final int numero;
  final String nombre;
  final int xpMinimo;

  const Nivel(this.numero, this.nombre, this.xpMinimo);

  /// Todos los niveles, de menor a mayor. Una tarea típica da 15 XP, así
  /// que Aprendiz llega con unas 4 tareas y Maestro con unas 80.
  static const lista = [
    Nivel(1, 'Novato', 0),
    Nivel(2, 'Aprendiz', 50),
    Nivel(3, 'Constante', 150),
    Nivel(4, 'Organizado', 300),
    Nivel(5, 'Dedicado', 500),
    Nivel(6, 'Experto', 800),
    Nivel(7, 'Maestro', 1200),
  ];

  /// Nivel que corresponde a [xp].
  static Nivel de(int xp) {
    var actual = lista.first;
    for (final n in lista) {
      if (xp >= n.xpMinimo) actual = n;
    }
    return actual;
  }

  /// El nivel que sigue, o null si ya está en el máximo.
  Nivel? get siguiente => numero < lista.length ? lista[numero] : null;

  bool get esMaximo => siguiente == null;

  /// Avance de 0 a 1 dentro de este nivel (1 en el nivel máximo).
  double avance(int xp) {
    final sig = siguiente;
    if (sig == null) return 1;
    final avanzado = (xp - xpMinimo).clamp(0, sig.xpMinimo - xpMinimo);
    return avanzado / (sig.xpMinimo - xpMinimo);
  }

  /// XP que le faltan para el siguiente nivel (0 en el máximo).
  int faltan(int xp) {
    final sig = siguiente;
    if (sig == null) return 0;
    return (sig.xpMinimo - xp).clamp(0, sig.xpMinimo);
  }
}
