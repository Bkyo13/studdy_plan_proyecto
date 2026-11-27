import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/animaciones.dart';
import '../widgets/logo_app.dart';
import 'auth_gate.dart';

/// Pantalla de carga inicial. Verifica si existe una sesión activa y válida
/// mediante el token de Firebase y después pasa al dashboard (si la hay) o al
/// login (si no), con una transición suave.
///
/// Entrada escalonada y discreta: primero el logo, luego el nombre y al final
/// el lema. Respeta "Reducir movimiento".
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Tiempo mínimo en pantalla, para que el mensaje de sesión se alcance a leer.
  static const _duracionMinima = Duration(milliseconds: 2200);

  late final AnimationController _entrada;
  String _mensaje = 'Verificando sesión...';
  bool? _sesionValida;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _entrada.value = 1;
      } else {
        _entrada.forward();
      }
    });
    _verificarSesionYContinuar();
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  Future<void> _verificarSesionYContinuar() async {
    final auth = context.read<AuthProvider>();
    final inicio = DateTime.now();
    final valida = await auth.restaurarSesion();
    if (!mounted) return;
    setState(() {
      _sesionValida = valida;
      _mensaje = valida
          ? 'Sesión activa y válida · Bienvenido, ${auth.usuarioActual?.nombre ?? ''}'
          : 'No hay una sesión activa';
    });

    // El splash se queda visible al menos _duracionMinima en total.
    final restante = _duracionMinima - DateTime.now().difference(inicio);
    await Future.delayed(restante.isNegative ? Duration.zero : restante);
    if (!mounted) return;
    final salida = Animaciones.duracion(
      context,
      const Duration(milliseconds: 400),
    );
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: salida,
        pageBuilder: (_, _, _) => const AuthGate(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Animaciones.curva),
          child: child,
        ),
      ),
    );
  }

  /// Fundido + pequeño desplazamiento hacia arriba, en un tramo de la entrada.
  Widget _aparecer({
    required double desde,
    required double hasta,
    double desplazamiento = 10,
    double escalaInicial = 1,
    required Widget child,
  }) {
    final curva = CurvedAnimation(
      parent: _entrada,
      curve: Interval(desde, hasta, curve: Animaciones.curva),
    );
    return AnimatedBuilder(
      animation: curva,
      builder: (_, hijo) => Opacity(
        opacity: curva.value,
        child: Transform.translate(
          offset: Offset(0, desplazamiento * (1 - curva.value)),
          child: Transform.scale(
            scale: escalaInicial + (1 - escalaInicial) * curva.value,
            child: hijo,
          ),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cargando = _sesionValida == null;
    final cambio = Animaciones.duracion(context, Animaciones.normal);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _aparecer(
                desde: 0,
                hasta: 0.6,
                desplazamiento: 0,
                escalaInicial: 0.92,
                child: const LogoApp(tamano: 88),
              ),
              const SizedBox(height: 24),
              _aparecer(
                desde: 0.25,
                hasta: 0.8,
                child: const Text('StudyPlan', style: AppText.tituloPantalla),
              ),
              const SizedBox(height: 8),
              _aparecer(
                desde: 0.4,
                hasta: 1,
                child: const Text('Tu compañero de estudio', style: AppText.cuerpo),
              ),
              const SizedBox(height: 40),
              _aparecer(
                desde: 0.5,
                hasta: 1,
                desplazamiento: 0,
                child: Column(
                  children: [
                    // Del circulito de carga al ícono del resultado, sin saltos.
                    AnimatedSwitcher(
                      duration: cambio,
                      switchInCurve: Animaciones.curva,
                      child: cargando
                          ? const SizedBox(
                              key: ValueKey('cargando'),
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.verde,
                              ),
                            )
                          : Icon(
                              _sesionValida!
                                  ? Icons.verified_outlined
                                  : Icons.lock_outline,
                              key: ValueKey(_sesionValida),
                              color: AppColors.verde,
                              size: 28,
                            ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: cambio,
                      child: Text(
                        _mensaje,
                        key: ValueKey(_mensaje),
                        textAlign: TextAlign.center,
                        style: AppText.pequeno,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
