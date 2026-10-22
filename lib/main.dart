import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/materia_provider.dart';
// import 'providers/tarea_provider.dart';
// import 'providers/vinculo_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() => runApp(const StudyPlanApp());

class StudyPlanApp extends StatelessWidget {
  const StudyPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MateriaProvider()),
        // ChangeNotifierProvider(create: (_) => TareaProvider()),
        // ChangeNotifierProvider(create: (_) => VinculoProvider()),
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