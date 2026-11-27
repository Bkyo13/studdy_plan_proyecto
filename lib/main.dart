import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/asistente_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/feriado_provider.dart';
import 'providers/logro_provider.dart';
import 'providers/materia_provider.dart';
import 'providers/tarea_provider.dart';
import 'providers/vinculo_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notificaciones_service.dart';
import 'theme/app_theme.dart';

/// Antes de dibujar la app se conecta con Firebase (proyecto StudyPlan).
/// `firebase_options.dart` lo generó `flutterfire configure` con los datos de
/// Android, iOS y web; no se edita a mano.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // App Check: comprueba que las peticiones a la IA vienen de esta app.
  // - Al desarrollar (flutter run): proveedor de depuración. Su token se
  //   registra en la consola de Firebase (App Check -> Administrar tokens).
  // - En la versión release: Play Integrity / App Attest. Solo funcionan si
  //   la app está en Google Play / App Store; con el APK compartido directo
  //   el asistente deja de responder cuando Firebase exija App Check.
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? AndroidDebugProvider()
          : AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? AppleDebugProvider()
          : AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (e) {
    if (kDebugMode) debugPrint('[AppCheck] No se pudo activar: $e');
  }
  await NotificacionesService.instancia.inicializar();
  runApp(const StudyPlanApp());
}

class StudyPlanApp extends StatelessWidget {
  const StudyPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MateriaProvider()),
        ChangeNotifierProvider(create: (_) => TareaProvider()),
        ChangeNotifierProvider(create: (_) => VinculoProvider()),
        ChangeNotifierProvider(create: (_) => LogroProvider()),
        ChangeNotifierProvider(create: (_) => AsistenteProvider()),
        ChangeNotifierProvider(create: (_) => FeriadoProvider()),
      ],
      child: MaterialApp(
        title: 'StudyPlan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.fondo,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.verde),
          // Barra inferior: ícono y texto verdes en la pestaña activa.
          navigationBarTheme: NavigationBarThemeData(
            iconTheme: WidgetStateProperty.resolveWith(
              (estados) => IconThemeData(
                color: estados.contains(WidgetState.selected)
                    ? AppColors.verde
                    : AppColors.textoSuave,
              ),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (estados) => TextStyle(
                fontSize: 12,
                fontWeight: estados.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: estados.contains(WidgetState.selected)
                    ? AppColors.verde
                    : AppColors.textoSuave,
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}