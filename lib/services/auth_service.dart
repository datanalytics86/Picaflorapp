import 'package:flutter/foundation.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../data/demo_store.dart';
import '../models/auth_session.dart';
import '../models/user_model.dart';
import 'user_service.dart';

// Firebase Auth / Google / Apple SOLO fuera de DEMO.
import 'auth_service_live.dart' deferred as live;

/// Autenticación.
///
/// **DEMO_MODE:** 100% [DemoStore], sin firebase_auth / google_sign_in.
class AuthService {
  AuthService({
    UserService? userService,
    bool? demoMode,
  })  : _isDemo = demoMode ?? AppConfig.demoMode,
        _userService = userService ?? UserService();

  final bool _isDemo;
  final UserService _userService;
  bool _liveLoaded = false;
  String? _pendingPhoneVerificationId;

  static const String demoSmsCode = '123456';

  Future<void> _ensureLive() async {
    if (_isDemo) throw StateError('Auth live no se carga en DEMO');
    if (_liveLoaded) return;
    if (kDebugMode) debugPrint('🔐 loading auth_service_live…');
    await live.loadLibrary().timeout(const Duration(seconds: 6));
    _liveLoaded = true;
  }

  Stream<AuthSession?> get authStateChanges {
    if (_isDemo) return DemoStore.instance.authStateChanges;
    return Stream.multi((listener) async {
      try {
        await _ensureLive();
        final sub = live.authStateChanges().listen(
          listener.add,
          onError: listener.addError,
          onDone: listener.close,
        );
        listener.onCancel = () => sub.cancel();
      } catch (e) {
        listener.add(null);
        listener.close();
      }
    });
  }

  AuthSession? get currentSession {
    if (_isDemo) return DemoStore.instance.session;
    // Lectura síncrona solo si live ya cargó; si no, null (router espera login).
    if (!_liveLoaded) return null;
    try {
      return live.currentSessionSync();
    } catch (_) {
      return null;
    }
  }

  String? get currentUid => currentSession?.uid;

  bool get isSignedIn => currentUid != null;

  String? get pendingPhoneVerificationId => _pendingPhoneVerificationId;

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _validateCredentials(
      email: email,
      password: password,
      displayName: displayName,
    );

    if (_isDemo) {
      return DemoStore.instance.signInDemo(
        email: email.trim().toLowerCase(),
        displayName: displayName.trim(),
      );
    }

    await _ensureLive();
    return live.signUpWithEmail(
      email: email,
      password: password,
      displayName: displayName,
      userService: _userService,
    );
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw AuthException('Ingresa tu correo y contraseña.');
    }

    if (_isDemo) {
      if (!_isValidEmail(email) || password.length < 6) {
        throw AuthException('Correo o contraseña incorrectos.');
      }
      return DemoStore.instance.signInDemo(
        email: email.trim().toLowerCase(),
        displayName: email.split('@').first,
      );
    }

    await _ensureLive();
    return live.signInWithEmail(
      email: email,
      password: password,
      userService: _userService,
    );
  }

  /// Entrada demo — síncrona (Future.value inmediato).
  Future<UserModel> signInAsDemoGuest() async {
    if (!_isDemo) {
      throw AuthException('El modo demo no está activo.');
    }
    // Sin await artificial: devuelve altiro.
    return DemoStore.instance.signInDemo();
  }

  Future<UserModel> signInWithGoogle() async {
    if (_isDemo) {
      return DemoStore.instance.signInDemo(
        email: 'google.demo@picaflor.cl',
        displayName: 'Demo Google',
      );
    }
    await _ensureLive();
    return live.signInWithGoogle(userService: _userService);
  }

  Future<UserModel> signInWithApple() async {
    if (_isDemo) {
      return DemoStore.instance.signInDemo(
        email: 'apple.demo@picaflor.cl',
        displayName: 'Demo Apple',
      );
    }
    await _ensureLive();
    return live.signInWithApple(userService: _userService);
  }

  Future<bool> get isAppleSignInAvailable async {
    if (_isDemo) return true;
    try {
      await _ensureLive();
      return await live.isAppleSignInAvailable();
    } catch (_) {
      return false;
    }
  }

  Future<PhoneCodeResult> sendPhoneCode({
    required String phoneNumber,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final normalized = _normalizeChilePhone(phoneNumber);
    if (normalized == null) {
      throw AuthException(
        'Número inválido. Usa formato chileno: +56 9 1234 5678',
      );
    }

    if (_isDemo) {
      // Sin delay artificial (antes 400ms se sentía como freeze).
      _pendingPhoneVerificationId = 'demo_vid_$normalized';
      return PhoneCodeResult.codeSent(_pendingPhoneVerificationId!);
    }

    await _ensureLive();
    final result = await live.sendPhoneCode(
      phoneNumber: normalized,
      timeout: timeout,
      userService: _userService,
    );
    _pendingPhoneVerificationId = result.verificationId;
    return result;
  }

  Future<UserModel> confirmPhoneCode({
    required String smsCode,
    String? verificationId,
    String? displayName,
  }) async {
    final vid = verificationId ?? _pendingPhoneVerificationId;
    if (vid == null || vid.isEmpty) {
      throw AuthException('Primero pide el código por SMS.');
    }
    if (smsCode.trim().length < 4) {
      throw AuthException('Ingresa el código que te llegó por SMS.');
    }

    if (_isDemo) {
      if (smsCode.trim() != demoSmsCode) {
        throw AuthException('En demo el código es $demoSmsCode');
      }
      return DemoStore.instance.signInDemo(
        email: '',
        displayName: displayName?.trim().isNotEmpty == true
            ? displayName!.trim()
            : 'Demo Teléfono',
      );
    }

    await _ensureLive();
    return live.confirmPhoneCode(
      smsCode: smsCode,
      verificationId: vid,
      displayName: displayName,
      userService: _userService,
    );
  }

  Future<void> signOut() async {
    final uid = currentUid;
    try {
      if (uid != null) {
        await _userService.setOnlineStatus(uid, false);
      }
    } catch (_) {}

    _pendingPhoneVerificationId = null;

    if (_isDemo) {
      await DemoStore.instance.signOut();
      return;
    }

    if (_liveLoaded) {
      await live.signOut();
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      throw AuthException('Escribe tu correo para enviarte el enlace.');
    }
    if (_isDemo) return;
    await _ensureLive();
    await live.sendPasswordReset(email);
  }

  String? _normalizeChilePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+56') && digits.length >= 12) return digits;
    if (digits.startsWith('56') && digits.length >= 11) return '+$digits';
    if (digits.startsWith('9') && digits.length == 9) return '+56$digits';
    if (digits.startsWith('+') && digits.length >= 10) return digits;
    return null;
  }

  void _validateCredentials({
    required String email,
    required String password,
    required String displayName,
  }) {
    if (displayName.trim().length < AppConstants.minDisplayNameLength) {
      throw AuthException('Tu nombre debe tener al menos 2 caracteres.');
    }
    if (displayName.trim().length > AppConstants.maxDisplayNameLength) {
      throw AuthException('Tu nombre es demasiado largo.');
    }
    if (!_isValidEmail(email)) {
      throw AuthException('Ese correo no se ve bien. ¿Lo revisas?');
    }
    if (password.length < AppConstants.minPasswordLength) {
      throw AuthException(
        'La contraseña debe tener al menos ${AppConstants.minPasswordLength} caracteres.',
      );
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PhoneCodeResult {
  const PhoneCodeResult._({
    required this.isAutoVerified,
    this.verificationId,
    this.profile,
  });

  factory PhoneCodeResult.codeSent(String verificationId) => PhoneCodeResult._(
        isAutoVerified: false,
        verificationId: verificationId,
      );

  factory PhoneCodeResult.autoVerified(UserModel profile) => PhoneCodeResult._(
        isAutoVerified: true,
        profile: profile,
      );

  final bool isAutoVerified;
  final String? verificationId;
  final UserModel? profile;
}
