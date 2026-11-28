import 'package:flutter/widgets.dart';

/// Baja el teclado (quita el foco del campo que se está escribiendo).
/// Se llama al enviar o guardar, para que el teclado no se quede abierto
/// tapando el resultado.
void ocultarTeclado() => FocusManager.instance.primaryFocus?.unfocus();

/// Envuelve toda la app: tocar cualquier parte vacía de la pantalla baja el
/// teclado. Los botones y campos siguen recibiendo sus toques normal.
class CerrarTecladoAlTocar extends StatelessWidget {
  final Widget child;

  const CerrarTecladoAlTocar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: ocultarTeclado,
      child: child,
    );
  }
}
