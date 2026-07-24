import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/auth_session.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'user_provider.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(userService: ref.watch(userServiceProvider));
});

/// Sesión autenticada (demo o Firebase), desacoplada de `firebase_auth.User`.
final authStateProvider = StreamProvider<AuthSession?>((ref) {
  try {
    return ref.watch(authServiceProvider).authStateChanges;
  } catch (e) {
    return Stream.value(null);
  }
});

/// Perfil del usuario autenticado (DemoStore o Firestore).
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final session = ref.watch(authStateProvider).valueOrNull;
  if (session == null) return Stream.value(null);
  return ref.watch(userServiceProvider).watchUser(session.uid);
});

enum AuthMethod { email, google, apple, phone }

class AuthFormState {
  const AuthFormState({
    this.isLoading = false,
    this.error,
    this.isRegisterMode = false,
    this.phoneStep = PhoneAuthStep.idle,
    this.phoneVerificationId,
    this.lastMethod,
  });

  final bool isLoading;
  final String? error;
  final bool isRegisterMode;
  final PhoneAuthStep phoneStep;
  final String? phoneVerificationId;
  final AuthMethod? lastMethod;

  AuthFormState copyWith({
    bool? isLoading,
    String? error,
    bool? isRegisterMode,
    PhoneAuthStep? phoneStep,
    String? phoneVerificationId,
    AuthMethod? lastMethod,
    bool clearError = false,
    bool clearPhone = false,
  }) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isRegisterMode: isRegisterMode ?? this.isRegisterMode,
      phoneStep: clearPhone ? PhoneAuthStep.idle : (phoneStep ?? this.phoneStep),
      phoneVerificationId: clearPhone
          ? null
          : (phoneVerificationId ?? this.phoneVerificationId),
      lastMethod: lastMethod ?? this.lastMethod,
    );
  }
}

enum PhoneAuthStep { idle, codeSent, verifying }

class AuthController extends StateNotifier<AuthFormState> {
  AuthController(this._auth) : super(const AuthFormState());

  final AuthService _auth;

  void toggleMode() {
    state = state.copyWith(
      isRegisterMode: !state.isRegisterMode,
      clearError: true,
    );
  }

  void clearError() => state = state.copyWith(clearError: true);

  void resetPhoneFlow() {
    state = state.copyWith(clearPhone: true, clearError: true);
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastMethod: AuthMethod.email,
    );
    try {
      await _auth.signInWithEmail(email: email, password: password);
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Algo salió mal. Inténtalo de nuevo.',
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastMethod: AuthMethod.email,
    );
    try {
      await _auth.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos crear tu cuenta.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastMethod: AuthMethod.google,
    );
    try {
      await _auth.signInWithGoogle();
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Falló el inicio con Google.',
      );
      return false;
    }
  }

  Future<bool> signInWithApple() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastMethod: AuthMethod.apple,
    );
    try {
      await _auth.signInWithApple();
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Falló el inicio con Apple.',
      );
      return false;
    }
  }

  /// Paso 1 teléfono: envía SMS.
  ///
  /// Retorna `true` si hay que mostrar el input de código,
  /// o si Android auto-verificó (sesión lista).
  Future<bool> sendPhoneCode(String phone) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastMethod: AuthMethod.phone,
    );
    try {
      final result = await _auth.sendPhoneCode(phoneNumber: phone);

      if (result.isAutoVerified) {
        state = state.copyWith(isLoading: false, clearPhone: true);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        phoneStep: PhoneAuthStep.codeSent,
        phoneVerificationId: result.verificationId,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No pudimos enviar el SMS.',
      );
      return false;
    }
  }

  /// Paso 2 teléfono: confirma código.
  Future<bool> confirmPhoneCode({
    required String smsCode,
    String? displayName,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      phoneStep: PhoneAuthStep.verifying,
      lastMethod: AuthMethod.phone,
    );
    try {
      await _auth.confirmPhoneCode(
        smsCode: smsCode,
        verificationId: state.phoneVerificationId,
        displayName: displayName,
      );
      state = state.copyWith(
        isLoading: false,
        clearPhone: true,
      );
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        phoneStep: PhoneAuthStep.codeSent,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Código incorrecto o expirado.',
        phoneStep: PhoneAuthStep.codeSent,
      );
      return false;
    }
  }

  /// Entrada rápida al modo demo (sin formularios).
  Future<bool> enterDemo() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastMethod: AuthMethod.email,
    );
    try {
      await _auth.signInAsDemoGuest();
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo entrar al modo demo.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.signOut();
    } finally {
      state = state.copyWith(isLoading: false, clearPhone: true);
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthFormState>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});

final appleSignInAvailableProvider = FutureProvider<bool>((ref) {
  return ref.watch(authServiceProvider).isAppleSignInAvailable;
});
