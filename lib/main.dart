import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'theme.dart';
import 'ui/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation du gestionnaire de fenêtre pour les dimensions minimales
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'AGEPA App',
  );
  
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    // Définir la taille minimale égale à la taille idéale pour éviter tout débordement
    await windowManager.setMinimumSize(const Size(1280, 800));
  });

  runApp(
    const ProviderScope(
      child: AgepaApp(),
    ),
  );
}

class AgepaApp extends StatelessWidget {
  const AgepaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AGEPA App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainLayout(),
    );
  }
}
