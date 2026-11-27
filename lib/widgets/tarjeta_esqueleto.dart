import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Lista de tarjetas "esqueleto": la forma de las tarjetas reales, en gris,
/// con un parpadeo suave mientras llegan los datos de Firestore. Así la
/// pantalla no se ve vacía ni salta cuando aparecen las tareas.
/// Con "Reducir movimiento" se queda quieta.
class ListaEsqueleto extends StatefulWidget {
  final int cantidad;

  /// Alto de cada tarjeta (las de tarea miden unos 120).
  final double alto;

  const ListaEsqueleto({super.key, this.cantidad = 3, this.alto = 120});

  @override
  State<ListaEsqueleto> createState() => _ListaEsqueletoState();
}

class _ListaEsqueletoState extends State<ListaEsqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _parpadeo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.55,
    upperBound: 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _parpadeo.stop();
      _parpadeo.value = 1;
    } else if (!_parpadeo.isAnimating) {
      _parpadeo.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _parpadeo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando',
      child: FadeTransition(
        opacity: _parpadeo,
        child: Column(
          children: [
            for (var i = 0; i < widget.cantidad; i++) ...[
              _TarjetaEsqueleto(alto: widget.alto),
              if (i < widget.cantidad - 1)
                const SizedBox(height: AppSpacing.entreTarjetas),
            ],
          ],
        ),
      ),
    );
  }
}

class _TarjetaEsqueleto extends StatelessWidget {
  final double alto;

  const _TarjetaEsqueleto({required this.alto});

  @override
  Widget build(BuildContext context) {
    Widget barra(double ancho, double grosor) => Container(
          width: ancho,
          height: grosor,
          decoration: BoxDecoration(
            color: AppColors.borde,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Container(
      height: alto,
      padding: const EdgeInsets.all(AppSpacing.interiorTarjeta),
      decoration: AppDecor.tarjeta(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              barra(90, 12),
              const Spacer(),
              barra(50, 20),
            ],
          ),
          barra(200, 16),
          barra(140, 12),
        ],
      ),
    );
  }
}
