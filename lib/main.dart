import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/app_theme.dart';
import 'database/app_database.dart';
import 'providers/app_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/pending_provider.dart';
import 'providers/trigger_provider.dart';
import 'screens/fake_call_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/trigger_watcher_service.dart';

// Clé globale du Navigator → permet de pousser des écrans (ex: FakeCallScreen)
// depuis n'importe où, sans dépendre d'un BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await AppDatabase.instance.init();
  await NotificationService.instance.init();

  // Démarrage du watcher au niveau global, indépendant des écrans.
  // La callback push le FakeCallScreen via le navigatorKey, donc le
  // déclenchement fonctionne même quand le HomeScreen est recréé.
  TriggerWatcherService.instance.onTrigger = (id, label) {
    final navState = navigatorKey.currentState;
    if (navState == null) return;
    navState.push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => FakeCallScreen(triggerId: id, triggerLabel: label),
    ));
  };
  TriggerWatcherService.instance.start();

  runApp(const PauseApp());
}

class PauseApp extends StatelessWidget {
  const PauseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => TriggerProvider()..load()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()..load()),
        ChangeNotifierProvider(
          create: (_) => PendingProvider()
            ..load()
            ..startTicker(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PAUSE',
        theme: AppTheme.darkTheme,
        navigatorKey: navigatorKey,
        home: const SplashScreen(),
      ),
    );
  }
}