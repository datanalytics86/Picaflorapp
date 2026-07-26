import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nunca bloquear el primer frame esperando fonts de red.
  GoogleFonts.config.allowRuntimeFetching = false;

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
  } catch (e) {
    debugPrint('SystemChrome skip: $e');
  }

  try {
    await initializeDateFormatting('es');
  } catch (e) {
    debugPrint('date formatting skip: $e');
  }

  late final SharedPreferences prefs;
  try {
    prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 3),
    );
  } catch (e) {
    debugPrint('SharedPreferences retry: $e');
    prefs = await SharedPreferences.getInstance();
  }

  if (kDebugMode) {
    debugPrint(
      '🐦 boot demo=${AppConfig.demoMode} web=$kIsWeb',
    );
  }

  if (AppConfig.demoMode) {
    debugPrint('🐦 Picaflor en MODO DEMO (sin Firebase)');
  } else if (!DefaultFirebaseOptions.isConfigured) {
    debugPrint(
      '⚠️ DEMO_MODE=false pero firebase_options.dart aún es placeholder. '
      'Corre: flutterfire configure',
    );
  } else {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('🐦 Picaflor · Firebase listo');
    } catch (e, st) {
      debugPrint('Firebase no inicializado: $e');
      debugPrint('$st');
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const PicaflorApp(),
    ),
  );
}

class PicaflorApp extends ConsumerWidget {
  const PicaflorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      // Banner solo en debug + demo; release siempre limpio.
      debugShowCheckedModeBanner: AppConfig.demoMode && !AppConfig.isRelease,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('es', 'CL'),
      supportedLocales: const [
        Locale('es', 'CL'),
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
