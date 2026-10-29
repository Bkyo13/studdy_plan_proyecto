import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_app.dart';
import 'auth_gate.dart';

/// Pantalla de carga inicial. Verifica si existe una sesión activa y válida
/// mediante el token guardado y después pasa al dashboard (si la hay) o al
/// login (si no), con una transición suave.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _duracionMinima = Duration(milliseconds: 3000);

  String _mensaje = 'Verificando sesión...';
  bool? _sesionValida;

  @override
  void initState() {
    super.initState();
    _verificarSesionYContinuar();
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

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const AuthGate(),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cargando = _sesionValida == null;
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          builder: (context, valor, child) =>
              Opacity(opacity: valor, child: child),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pantalla),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoApp(tamano: 88),
                const SizedBox(height: 24),
                const Text('StudyPlan', style: AppText.tituloPantalla),
                const SizedBox(height: 8),
                const Text('Tu compañero de estudio', style: AppText.cuerpo),
                const SizedBox(height: 40),
                if (cargando)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.verde,
                    ),
                  )
                else
                  Icon(
                    _sesionValida! ? Icons.verified_outlined : Icons.lock_outline,
                    color: AppColors.verde,
                    size: 28,
                  ),
                const SizedBox(height: 16),
                Text(
                  _mensaje,
                  textAlign: TextAlign.center,
                  style: AppText.pequeno,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}