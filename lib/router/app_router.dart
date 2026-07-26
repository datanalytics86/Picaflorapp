import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/nearby/nearby_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/splash/splash_screen.dart';

/// Rutas canónicas de Picaflor.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const home = '/home';
  static const chatList = '/chat-list';
  static const chat = '/chat/:id';
  static const profile = '/profile';
  static const settings = '/settings';

  static String chatPath(String chatId, {String? otherUid}) {
    final base = '/chat/$chatId';
    if (otherUid != null && otherUid.isNotEmpty) {
      return '$base?otherUid=$otherUid';
    }
    return base;
  }
}

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    _authSub = ref.listen(authStateProvider, (_, __) => notifyListeners());
    _onboardingSub =
        ref.listen(onboardingDoneProvider, (_, __) => notifyListeners());
  }

  late final ProviderSubscription<dynamic> _authSub;
  late final ProviderSubscription<dynamic> _onboardingSub;

  @override
  void dispose() {
    _authSub.close();
    _onboardingSub.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final onboardingDone = ref.read(onboardingDoneProvider);
      final loc = state.matchedLocation;

      final isSplash = loc == AppRoutes.splash || loc == '/';
      final isOnboarding = loc == AppRoutes.onboarding;
      final isLogin = loc == AppRoutes.login;

      // NUNCA atrapar al usuario en splash por un StreamProvider loading eterno.
      // Si aún no hay valor, tratamos como "sin sesión" y seguimos el flujo.
      final isLoggedIn = authAsync.hasValue && authAsync.requireValue != null;

      // Onboarding pendiente.
      if (!onboardingDone) {
        if (isOnboarding) return null;
        return AppRoutes.onboarding;
      }

      // Sin sesión → login (salvo que ya esté ahí).
      if (!isLoggedIn) {
        if (isLogin) return null;
        if (isSplash) return AppRoutes.login;
        return AppRoutes.login;
      }

      // Con sesión: salir de flows de auth.
      if (isLogin || isOnboarding || isSplash) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      // Compat: / → splash
      GoRoute(
        path: '/',
        redirect: (_, __) => AppRoutes.splash,
      ),
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Shell: Home (Nearby) · Chats · Perfil
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const NearbyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chatList,
                name: 'chat-list',
                builder: (context, state) => const ChatListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: '/chat/:id',
        name: 'chat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final chatId = state.pathParameters['id'] ?? '';
          final otherUid = state.uri.queryParameters['otherUid'];
          return ChatScreen(chatId: chatId, otherUid: otherUid);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.explore_off_outlined, size: 48),
              const SizedBox(height: 16),
              Text(
                'Esta página no existe',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Volvamos al inicio.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Ir al inicio'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
