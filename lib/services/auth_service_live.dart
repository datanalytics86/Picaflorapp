import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/auth_session.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'user_service.dart';

FirebaseAuth get _auth => FirebaseAuth.instance;
final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: const ['email']);

Stream<AuthSession?> authStateChanges() {
  return _auth.authStateChanges().map(_sessionFromUser);
}

AuthSession? currentSessionSync() => _sessionFromUser(_auth.currentUser);

AuthSession? _sessionFromUser(User? u) {
  if (u == null) return null;
  return AuthSession(
    uid: u.uid,
    email: u.email ?? '',
    displayName: u.displayName ?? '',
  );
}

Future<UserModel> signUpWithEmail({
  required String email,
  required String password,
  required String displayName,
  required UserService userService,
}) async {
  try {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw AuthException('No se pudo crear la cuenta. Inténtalo de nuevo.');
    }
    await user.updateDisplayName(displayName.trim());
    return _upsertProfile(
      userService: userService,
      uid: user.uid,
      email: email.trim().toLowerCase(),
      displayName: displayName.trim(),
      photoUrl: user.photoURL,
    );
  } on FirebaseAuthException catch (e) {
    throw AuthException(_mapFirebaseError(e));
  } catch (e) {
    if (e is AuthException) rethrow;
    throw AuthException('Algo salió mal al registrarte. Inténtalo otra vez.');
  }
}

Future<UserModel> signInWithEmail({
  required String email,
  required String password,
  required UserService userService,
}) async {
  try {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) throw AuthException('No se pudo iniciar sesión.');
    return _upsertProfile(
      userService: userService,
      uid: user.uid,
      email: user.email ?? email.trim().toLowerCase(),
      displayName: user.displayName ?? 'Usuario',
      photoUrl: user.photoURL,
    );
  } on FirebaseAuthException catch (e) {
    throw AuthException(_mapFirebaseError(e));
  } catch (e) {
    if (e is AuthException) rethrow;
    throw AuthException('No pudimos iniciar sesión. Revisa tu conexión.');
  }
}

Future<UserModel> signInWithGoogle({required UserService userService}) async {
  try {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw AuthException('Cancelaste el inicio con Google.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) {
      throw AuthException('No se pudo entrar con Google.');
    }
    return _upsertProfile(
      userService: userService,
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
    throw AuthException('Falló el inicio con Google. Inténtalo de nuevo.');
  }
}

Future<UserModel> signInWithApple({required UserService userService}) async {
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
    final userCredential = await _auth.signInWithCredential(oauth);
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
    final displayName =
        (user.displayName != null && user.displayName!.trim().isNotEmpty)
            ? user.displayName!
            : (composedName.isNotEmpty ? composedName : 'Usuario');
    if (user.displayName == null && composedName.isNotEmpty) {
      await user.updateDisplayName(composedName);
    }
    return _upsertProfile(
      userService: userService,
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
    throw AuthException('Falló el inicio con Apple. Inténtalo de nuevo.');
  }
}

Future<bool> isAppleSignInAvailable() async {
  try {
    return await SignInWithApple.isAvailable();
  } catch (_) {
    return false;
  }
}

Future<PhoneCodeResult> sendPhoneCode({
  required String phoneNumber,
  required Duration timeout,
  required UserService userService,
}) async {
  final completer = Completer<PhoneCodeResult>();
  try {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: (credential) async {
        try {
          final profile = await _signInWithPhoneCredential(
            credential,
            userService: userService,
          );
          if (!completer.isCompleted) {
            completer.complete(PhoneCodeResult.autoVerified(profile));
          }
        } catch (e) {
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
        if (!completer.isCompleted) {
          completer.complete(PhoneCodeResult.codeSent(verificationId));
        }
      },
      codeAutoRetrievalTimeout: (_) {},
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
    throw AuthException('No pudimos enviar el SMS. Inténtalo de nuevo.');
  }
}

Future<UserModel> confirmPhoneCode({
  required String smsCode,
  required String verificationId,
  String? displayName,
  required UserService userService,
}) async {
  try {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    return _signInWithPhoneCredential(
      credential,
      displayName: displayName,
      userService: userService,
    );
  } on FirebaseAuthException catch (e) {
    throw AuthException(_mapFirebaseError(e));
  } catch (e) {
    if (e is AuthException) rethrow;
    throw AuthException('Código incorrecto o expirado.');
  }
}

Future<UserModel> _signInWithPhoneCredential(
  PhoneAuthCredential credential, {
  String? displayName,
  required UserService userService,
}) async {
  final userCredential = await _auth.signInWithCredential(credential);
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
    userService: userService,
    uid: user.uid,
    email: user.email ?? '',
    displayName: name,
    photoUrl: user.photoURL,
  );
}

Future<void> signOut() async {
  await Future.wait([
    _auth.signOut(),
    _googleSignIn.signOut(),
  ]);
}

Future<void> sendPasswordReset(String email) async {
  try {
    await _auth.sendPasswordResetEmail(email: email.trim());
  } on FirebaseAuthException catch (e) {
    throw AuthException(_mapFirebaseError(e));
  }
}

Future<UserModel> _upsertProfile({
  required UserService userService,
  required String uid,
  required String email,
  required String displayName,
  String? photoUrl,
}) async {
  final existing = await userService.getUser(uid);
  if (existing != null) {
    await userService.setOnlineStatus(uid, true);
    if ((existing.displayName.isEmpty || existing.displayName == 'Usuario') &&
        displayName.isNotEmpty &&
        displayName != 'Usuario') {
      await userService.updateProfile(uid: uid, displayName: displayName);
    }
    if ((existing.photoUrl == null || existing.photoUrl!.isEmpty) &&
        photoUrl != null) {
      await userService.updateProfile(uid: uid, photoUrl: photoUrl);
    }
    return (await userService.getUser(uid)) ?? existing;
  }

  final profile = UserModel(
    uid: uid,
    email: email,
    displayName: displayName,
    photoUrl: photoUrl,
  );
  await userService.createUser(profile);
  return profile;
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
