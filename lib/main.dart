import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'data/demo_store.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';

import 'firebase_boot.dart' deferred as fb;

Future<void> main() async {
  final bootSw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrint('🐦 boot demo=${AppConfig.demoMode} web=$kIsWeb');
  }

  if (!kIsWeb) {
    unawaited(_safeSystemChrome());
  }

  final prefs = await _loadPrefsFast();

  // DEMO: onboarding ya hecho + sesión lista ANTES de runApp.
  // Evita: splash → onboarding → login → freeze percibido.
  final List<Override> overrides = [
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];

  if (AppConfig.demoMode) {
    // Marca onboarding en prefs (sync write best-effort).
    try {
      await prefs
          .setBool(AppConstants.keyOnboardingDone, true)
          .timeout(const Duration(milliseconds: 200));
    } catch (_) {}

    // Sesión demo en memoria ANTES del primer frame.
    try {
      await DemoStore.instance
          .signInDemo()
          .timeout(const Duration(milliseconds: 500));
      if (kDebugMode) {
        debugPrint('🐦 DEMO pre-login uid=${DemoStore.instance.currentUid}');
      }
    } catch (e) {
      debugPrint('DEMO pre-login skip: $e');
    }

    overrides.add(
      onboardingDoneProvider.overrideWith((ref) {
        return _AlwaysDoneOnboarding(prefs);
      }),
    );
  }

  if (kDebugMode) {
    debugPrint('🐦 prefs+demo ${bootSw.elapsedMilliseconds}ms');
  }

  if (!AppConfig.demoMode) {
    unawaited(_bootFirebaseDeferred());
  }

  runApp(
    ProviderScope(
      overrides: overrides,
      child: const PicaflorApp(),
    ),
  );

  if (kDebugMode) {
    debugPrint('🐦 runApp ${bootSw.elapsedMilliseconds}ms');
  }

  // Sincroniza SessionNotifier tras el primer frame (demo ya tiene sesión).
  if (AppConfig.demoMode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // No-op placeholder: el SessionNotifier lee currentSession al crearse.
      if (kDebugMode) {
        debugPrint(
          '🐦 first-frame session=${DemoStore.instance.session?.uid}',
        );
      }
    });
  }
}

/// Onboarding forzado a true (DEMO).
class _AlwaysDoneOnboarding extends OnboardingNotifier {
  _AlwaysDoneOnboarding(super.prefs) {
    // Fuerza estado true aunque prefs diga false.
    if (!state) {
      state = true;
    }
  }
}

Future<void> _safeSystemChrome() async {
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).timeout(const Duration(milliseconds: 400));
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  } catch (e) {
    debugPrint('SystemChrome skip: $e');
  }
}

Future<SharedPreferences> _loadPrefsFast() async {
  try {
    return await SharedPreferences.getInstance()
        .timeout(const Duration(milliseconds: 500));
  } catch (e) {
    debugPrint('prefs timeout: $e');
    try {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingDone: true,
      });
      return await SharedPreferences.getInstance()
          .timeout(const Duration(milliseconds: 300));
    } catch (e2) {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({
        AppConstants.keyOnboardingDone: true,
      });
      return SharedPreferences.getInstance();
    }
  }
}

Future<void> _bootFirebaseDeferred() async {
  try {
    await fb.loadLibrary().timeout(const Duration(seconds: 6));
    await fb.initFirebase().timeout(const Duration(seconds: 8));
  } catch (e) {
    debugPrint('Firebase deferred skip: $e');
  }
}

class PicaflorApp extends ConsumerStatefulWidget {
  const PicaflorApp({super.key});

  @override
  ConsumerState<PicaflorApp> createState() => _PicaflorAppState();
}

class _PicaflorAppState extends ConsumerState<PicaflorApp> {
  @override
  void initState() {
    super.initState();
    if (AppConfig.demoMode) {
      // Asegura que el SessionNotifier vea la sesión de DemoStore.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(sessionProvider.notifier).sync();
        if (kDebugMode) {
          debugPrint(
            '🐦 session sync → ${ref.read(sessionProvider)?.uid}',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
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
