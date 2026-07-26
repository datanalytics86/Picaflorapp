import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../data/demo_store.dart';
import '../models/auth_session.dart';
import '../models/user_model.dart';
import 'user_service.dart';

/// Autenticación: email, Google, Apple y teléfono.
///
/// En [AppConfig.demoMode] no toca Firebase: sesión local vía [DemoStore].
class AuthService {
  AuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    UserService? userService,
    bool? demoMode,
  })  : _isDemo = demoMode ?? AppConfig.demoMode,
        _userService = userService ?? UserService() {
    if (!_isDemo) {
      _auth = auth ?? FirebaseAuth.instance;
      _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: const ['email']);
    }
  }

  final bool _isDemo;
  final UserService _userService;

  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;

  /// VerificationId pendiente de SMS (flujo teléfono · producción).
  String? _pendingPhoneVerificationId;

  /// En demo el código "SMS" simulado.
  static const String demoSmsCode = '123456';

  Stream<AuthSession?> get authStateChanges {
    if (_isDemo) return DemoStore.instance.authStateChanges;
    return _auth!.authStateChanges().map(_sessionFromFirebaseUser);
  }

  /// Lectura síncrona de la sesión (para el router, sin race con streams).
  AuthSession? get currentSession {
    if (_isDemo) return DemoStore.instance.session;
    return _sessionFromFirebaseUser(_auth?.currentUser);
  }

  String? get currentUid => currentSession?.uid;

  bool get isSignedIn => currentUid != null;

  AuthSession? _sessionFromFirebaseUser(User? u) {
    if (u == null) return null;
    return AuthSession(
      uid: u.uid,
      email: u.email ?? '',
      displayName: u.displayName ?? '',
    );
  }

  String? get pendingPhoneVerificationId => _pendingPhoneVerificationId;

  // ── Email ──────────────────────────────────────────────────────────────

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

    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AuthException('No se pudo crear la cuenta. Inténtalo de nuevo.');
      }

      await user.updateDisplayName(displayName.trim());
      return _upsertProfile(
        uid: user.uid,
        email: email.trim().toLowerCase(),
        displayName: displayName.trim(),
        photoUrl: user.photoURL,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('signUpWithEmail error: $e');
      throw AuthException('Algo salió mal al registrarte. Inténtalo otra vez.');
    }
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw AuthException('Ingresa tu correo y contraseña.');
    }

    if (_isDemo) {
      // Cualquier correo/clave válida en formato abre la sesión demo.
      if (!_isValidEmail(email) || password.length < 6) {
        throw AuthException('Correo o contraseña incorrectos.');
      }
      return DemoStore.instance.signInDemo(
        email: email.trim().toLowerCase(),
        displayName: email.split('@').first,
      );
    }

    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw AuthException('No se pudo iniciar sesión.');

      return _upsertProfile(
        uid: user.uid,
        email: user.email ?? email.trim().toLowerCase(),
        displayName: user.displayName ?? 'Usuario',
        photoUrl: user.photoURL,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('signInWithEmail error: $e');
      throw AuthException('No pudimos iniciar sesión. Revisa tu conexión.');
    }
  }

  /// Entrada rápida al modo demo (un toque).
  Future<UserModel> signInAsDemoGuest() async {
    if (!_isDemo) {
      throw AuthException('El modo demo no está activo.');
    }
    return DemoStore.instance.signInDemo();
  }

  // ── Google ─────────────────────────────────────────────────────────────

  Future<UserModel> signInWithGoogle() async {
    if (_isDemo) {
      return DemoStore.instance.signInDemo(
        email: 'google.demo@picaflor.cl',
        displayName: 'Demo Google',
      );
    }

    try {
      final googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        throw AuthException('Cancelaste el inicio con Google.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth!.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AuthException('No se pudo entrar con Google.');
      }

      return _upsertProfile(
        uid: user.uid,
        email: user.email ?? googleUser.email,
        displayName: user.displayName ?? googleUser.displayName ?? 'Usuario',
        photoUrl: user.photoURL ?? googleUser.photoUrl,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('signInWithGoogle error: $e');
      throw AuthException('Falló el inicio con Google. Inténtalo de nuevo.');
    }
  }

  // ── Apple ──────────────────────────────────────────────────────────────

  Future<UserModel> signInWithApple() async {
    if (_isDemo) {
      return DemoStore.instance.signInDemo(
        email: 'apple.demo@picaflor.cl',
        displayName: 'Demo Apple',
      );
    }

    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null) {
        throw AuthException('Apple no devolvió el token. Inténtalo de nuevo.');
      }

      final oauth = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth!.signInWithCredential(oauth);
      final user = userCredential.user;
      if (user == null) {
        throw AuthException('No se pudo entrar con Apple.');
      }

      final given = appleCredential.givenName;
      final family = appleCredential.familyName;
      final composedName = [
        if (given != null && given.isNotEmpty) given,
        if (family != null && family.isNotEmpty) family,
      ].join(' ');

      final displayName = (user.displayName != null &&
              user.displayName!.trim().isNotEmpty)
          ? user.displayName!
          : (composedName.isNotEmpty ? composedName : 'Usuario');

      if (user.displayName == null && composedName.isNotEmpty) {
        await user.updateDisplayName(composedName);
      }

      return _upsertProfile(
        uid: user.uid,
        email: user.email ?? appleCredential.email ?? '',
        displayName: displayName,
        photoUrl: user.photoURL,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException('Cancelaste el inicio con Apple.');
      }
      throw AuthException('No se pudo entrar con Apple.');
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('signInWithApple error: $e');
      throw AuthException('Falló el inicio con Apple. Inténtalo de nuevo.');
    }
  }

  Future<bool> get isAppleSignInAvailable async {
    if (_isDemo) return true;
    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }

  // ── Teléfono ───────────────────────────────────────────────────────────

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
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _pendingPhoneVerificationId = 'demo_vid_$normalized';
      return PhoneCodeResult.codeSent(_pendingPhoneVerificationId!);
    }

    final completer = Completer<PhoneCodeResult>();

    try {
      await _auth!.verifyPhoneNumber(
        phoneNumber: normalized,
        timeout: timeout,
        verificationCompleted: (credential) async {
          try {
            final profile = await _signInWithPhoneCredential(credential);
            if (!completer.isCompleted) {
              completer.complete(PhoneCodeResult.autoVerified(profile));
            }
          } catch (e) {
            debugPrint('auto phone verify error: $e');
            if (!completer.isCompleted) {
              completer.completeError(
                AuthException(
                  'No se pudo verificar el teléfono automáticamente.',
                ),
              );
            }
          }
        },
        verificationFailed: (e) {
          if (!completer.isCompleted) {
            completer.completeError(AuthException(_mapFirebaseError(e)));
          }
        },
        codeSent: (verificationId, _) {
          _pendingPhoneVerificationId = verificationId;
          if (!completer.isCompleted) {
            completer.complete(PhoneCodeResult.codeSent(verificationId));
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _pendingPhoneVerificationId = verificationId;
        },
      );

      return await completer.future.timeout(
        timeout + const Duration(seconds: 5),
        onTimeout: () {
          throw AuthException(
            'Se demoró mucho el SMS. Revisa el número e inténtalo de nuevo.',
          );
        },
      );
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('sendPhoneCode error: $e');
      throw AuthException('No pudimos enviar el SMS. Inténtalo de nuevo.');
    }
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

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: smsCode.trim(),
      );
      return _signInWithPhoneCredential(
        credential,
        displayName: displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    } catch (e) {
      if (e is AuthException) rethrow;
      debugPrint('confirmPhoneCode error: $e');
      throw AuthException('Código incorrecto o expirado.');
    }
  }

  Future<UserModel> _signInWithPhoneCredential(
    PhoneAuthCredential credential, {
    String? displayName,
  }) async {
    final userCredential = await _auth!.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw AuthException('No se pudo verificar el teléfono.');
    }

    final name = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : (user.displayName?.trim().isNotEmpty == true
            ? user.displayName!
            : 'Usuario');

    if (user.displayName == null || user.displayName!.isEmpty) {
      await user.updateDisplayName(name);
    }

    return _upsertProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: name,
      photoUrl: user.photoURL,
    );
  }

  // ── Sesión ─────────────────────────────────────────────────────────────

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

    await Future.wait([
      _auth!.signOut(),
      _googleSignIn!.signOut(),
    ]);
  }

  Future<void> sendPasswordReset(String email) async {
    if (email.trim().isEmpty) {
      throw AuthException('Escribe tu correo para enviarte el enlace.');
    }
    if (_isDemo) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return;
    }
    try {
      await _auth!.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<UserModel> _upsertProfile({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) async {
    final existing = await _userService.getUser(uid);
    if (existing != null) {
      await _userService.setOnlineStatus(uid, true);
      if ((existing.displayName.isEmpty || existing.displayName == 'Usuario') &&
          displayName.isNotEmpty &&
          displayName != 'Usuario') {
        await _userService.updateProfile(uid: uid, displayName: displayName);
      }
      if ((existing.photoUrl == null || existing.photoUrl!.isEmpty) &&
          photoUrl != null) {
        await _userService.updateProfile(uid: uid, photoUrl: photoUrl);
      }
      return (await _userService.getUser(uid)) ?? existing;
    }

    final profile = UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
    );
    await _userService.createUser(profile);
    return profile;
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

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Ese correo ya está registrado. Prueba iniciando sesión.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'weak-password':
        return 'Esa contraseña es muy débil. Prueba con una más larga.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un rato.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet.';
      case 'operation-not-allowed':
        return 'Este método de acceso no está habilitado.';
      case 'invalid-verification-code':
        return 'Código incorrecto. Revisa el SMS.';
      case 'invalid-verification-id':
        return 'El código expiró. Pide uno nuevo.';
      case 'session-expired':
        return 'La sesión del SMS expiró. Pide otro código.';
      case 'invalid-phone-number':
        return 'Número de teléfono inválido.';
      case 'quota-exceeded':
        return 'Límite de SMS alcanzado. Prueba más tarde.';
      case 'account-exists-with-different-credential':
        return 'Ya tienes cuenta con otro método. Prueba Google o correo.';
      default:
        return e.message ?? 'Error de autenticación. Inténtalo de nuevo.';
    }
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
