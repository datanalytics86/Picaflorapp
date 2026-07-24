import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider<UserService>((ref) => UserService());

final userByIdProvider =
    StreamProvider.family<UserModel?, String>((ref, uid) {
  if (uid.isEmpty) return Stream.value(null);
  // Demo y perfiles reales se resuelven por el mismo UserService.
  return ref.watch(userServiceProvider).watchUser(uid);
});

final userFutureProvider =
    FutureProvider.family<UserModel?, String>((ref, uid) {
  if (uid.isEmpty) return Future.value(null);
  return ref.watch(userServiceProvider).getUser(uid);
});

class ProfileEditState {
  const ProfileEditState({
    this.isSaving = false,
    this.error,
    this.success = false,
  });

  final bool isSaving;
  final String? error;
  final bool success;

  ProfileEditState copyWith({
    bool? isSaving,
    String? error,
    bool? success,
    bool clearError = false,
  }) {
    return ProfileEditState(
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      success: success ?? this.success,
    );
  }
}

class ProfileController extends StateNotifier<ProfileEditState> {
  ProfileController(this._users) : super(const ProfileEditState());

  final UserService _users;

  Future<bool> save({
    required String uid,
    required String displayName,
    required String bio,
    List<String>? interests,
    bool? isVisible,
  }) async {
    if (displayName.trim().length < 2) {
      state = state.copyWith(error: 'El nombre es muy corto.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true, success: false);
    try {
      await _users.updateProfile(
        uid: uid,
        displayName: displayName,
        bio: bio,
        interests: interests,
        isVisible: isVisible,
      );
      state = state.copyWith(isSaving: false, success: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        error: 'No se pudo guardar. Revisa tu conexión.',
      );
      return false;
    }
  }

  Future<void> setVisibility(String uid, bool isVisible) async {
    try {
      await _users.setVisibility(uid, isVisible);
    } catch (_) {
      state = state.copyWith(error: 'No se pudo actualizar la visibilidad.');
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileEditState>((ref) {
  return ProfileController(ref.watch(userServiceProvider));
});
