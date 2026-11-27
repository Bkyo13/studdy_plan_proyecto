import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/materia.dart';

/// Catálogo de materias, guardado en Firestore (`materias/{id}`). Todos los
/// usuarios con sesión lo leen; solo el administrador lo modifica (lo exigen
/// las reglas de Firestore).
///
/// Empieza a escuchar solo cuando hay una sesión y se detiene al cerrarla.
class MateriaProvider extends ChangeNotifier {
  static void _log(String mensaje) {
    if (kDebugMode) debugPrint(mensaje);
  }

  /// Catálogo inicial que el admin puede cargar con un botón. Se usan los
  /// mismos ids que tenían en la versión en memoria ('1' a '6'), para que las
  /// tareas creadas antes sigan mostrando su materia.
  static const catalogoInicial = [
    Materia(id: '1', nombre: 'Cálculo de Varias Variables', color: '#758B75'),
    Materia(id: '2', nombre: 'Aplicaciones Web', color: '#C0807A'),
    Materia(id: '3', nombre: 'Estructura de Datos', color: '#D4B483'),
    Materia(id: '4', nombre: 'Literatura', color: '#8FA68A'),
    Materia(id: '5', nombre: 'Biología', color: '#7D8FA6'),
    Materia(id: '6', nombre: 'Física I', color: '#A68FA6'),
  ];

  final CollectionReference<Map<String, dynamic>> _coleccion =
      FirebaseFirestore.instance.collection('materias');

  List<Materia> _materias = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<User?>? _subSesion;

  MateriaProvider() {
    _subSesion = FirebaseAuth.instance.authStateChanges().listen((usuario) {
      _sub?.cancel();
      _sub = null;
      _materias = [];
      notifyListeners();
      if (usuario == null) return;
      _sub = _coleccion.snapshots().listen(
        (snap) {
          _materias = snap.docs
              .map((d) => Materia.desdeMapa(d.id, d.data()))
              .toList()
            ..sort((a, b) => a.nombre.compareTo(b.nombre));
          notifyListeners();
        },
        onError: (Object e) => _log('[Materias] No se pudieron leer: $e'),
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _subSesion?.cancel();
    super.dispose();
  }

  List<Materia> get materias => List.unmodifiable(_materias);

  Materia? porId(String id) {
    for (final m in _materias) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Revisa nombre vacío, largo y repetido. [idActual] es la materia que se
  /// está editando (para que no choque consigo misma).
  String? _validar(String nombre, {String? idActual}) {
    final limpio = nombre.trim();
    if (limpio.isEmpty) return 'Escribe el nombre de la materia';
    if (limpio.length < 3) return 'Mínimo 3 caracteres';
    if (limpio.length > 60) return 'Máximo 60 caracteres';
    final repetida = _materias.any(
      (m) => m.id != idActual && m.nombre.toLowerCase() == limpio.toLowerCase(),
    );
    if (repetida) return 'Esa materia ya existe';
    return null;
  }

  /// Devuelve null si se guardó, o el mensaje de error. La lista se
  /// actualiza sola cuando Firestore confirma el cambio (al instante, aun
  /// sin internet).
  String? agregar(String nombre, String color) {
    final error = _validar(nombre);
    if (error != null) return error;
    _escribir(_coleccion.add({'nombre': nombre.trim(), 'color': color}));
    return null;
  }

  /// Cambia nombre y color. Las tareas guardan solo el id de la materia, así
  /// que todas ven el cambio al instante. Devuelve null si se guardó.
  String? actualizar({
    required String id,
    required String nombre,
    required String color,
  }) {
    if (porId(id) == null) return 'La materia ya no existe';
    final error = _validar(nombre, idActual: id);
    if (error != null) return error;
    _escribir(
      _coleccion.doc(id).update({'nombre': nombre.trim(), 'color': color}),
    );
    return null;
  }

  /// Carga las materias de ejemplo (solo el admin; no borra las que ya hay).
  Future<void> cargarCatalogoInicial() async {
    final lote = FirebaseFirestore.instance.batch();
    for (final m in catalogoInicial) {
      lote.set(_coleccion.doc(m.id), m.aMapa());
    }
    await _escribir(lote.commit());
  }

  Future<void> _escribir(Future<Object?> operacion) async {
    try {
      await operacion;
    } catch (e) {
      _log('[Materias] No se pudo guardar: $e');
    }
  }
}
