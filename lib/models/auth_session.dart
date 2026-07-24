import 'package:equatable/equatable.dart';

/// Sesión de autenticación desacoplada de Firebase Auth.
///
/// En modo demo y en producción se usa el mismo tipo para que el router
/// y los providers no dependan de `firebase_auth.User`.
class AuthSession extends Equatable {
  const AuthSession({
    required this.uid,
    this.email = '',
    this.displayName = '',
  });

  final String uid;
  final String email;
  final String displayName;

  @override
  List<Object?> get props => [uid, email, displayName];
}
