import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/logging/app_logger.dart';
import 'features/auth/providers/auth_provider.dart';
import 'shared/widgets/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Kunci orientasi layar hanya portrait untuk mobile
  // Skip di web/desktop karena tidak relevan dan bisa menyebabkan masalah
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  await initializeDateFormatting('id', null);

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
  };

  // App langsung dirender, auto-login berjalan async di AuthGate.
  // Tidak ada lagi blocking sebelum frame pertama, jadi layar loading
  // "Memuat aplikasi..." tidak akan menggantung saat jaringan lambat.
  runZonedGuarded(() {
    runApp(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MtsGarutApp(),
      ),
    );
  }, (error, stack) {
    AppLogger.error('[ZonedError] $error');
    debugPrint('[ZonedError] $error');
  });
}

class MtsGarutApp extends StatelessWidget {
  const MtsGarutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MA PERSIS GARUT',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}