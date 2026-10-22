import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/logo_app.dart';
import 'auth_gate.dart';

/// Pantalla de carga inicial. Después de 2.5 segundos pasa al login (o al
/// dashboard si ya hay sesión) con una transición suave.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), _irAlInicio);
  }

  void _irAlInicio() {
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
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          builder: (context, valor, child) =>
              Opacity(opacity: valor, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              LogoApp(tamano: 88),
              SizedBox(height: 24),
              Text('StudyPlan', style: AppText.tituloPantalla),
              SizedBox(height: 8),
              Text(
                'Tu compañero de estudio',
                style: AppText.cuerpo,
              ),
              SizedBox(height: 40),
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.verde,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
