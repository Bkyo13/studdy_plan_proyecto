import 'package:firebase_core/firebase_core.dart';
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
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
