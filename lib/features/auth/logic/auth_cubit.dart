import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/points_movement_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;

  AuthCubit(this._authRepository) : super(const AuthInitial());

  Future<void> checkSession() async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.checkSession();

      if (user == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      emit(AuthAuthenticated(user));
    } on ApiException catch (error) {
      if (error.code == 'PERFIL_NO_REGISTRADO') {
        emit(
          const AuthNeedsInternalRegister(
            'Tu cuenta de Firebase existe, pero aún no completaste tu registro.',
          ),
        );
        return;
      }

      emit(AuthFailure(code: error.code, message: error.message));
    } catch (error) {
      emit(AuthFailure(code: 'UNKNOWN_ERROR', message: error.toString()));
    }
  }

  Future<void> refreshCurrentUser() async {
    if (state is! AuthAuthenticated) {
      return;
    }

    try {
      final user = await _authRepository.getMe();
      emit(AuthAuthenticated(user));
    } catch (_) {
      // La recarga silenciosa no debe bloquear la pantalla actual.
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );

      emit(AuthAuthenticated(user));
    } on ApiException catch (error) {
      if (error.code == 'PERFIL_NO_REGISTRADO') {
        emit(
          const AuthNeedsInternalRegister(
            'Tu cuenta existe, pero todavía no completaste tu perfil.',
          ),
        );
        return;
      }

      emit(AuthFailure(code: error.code, message: error.message));
    } catch (error) {
      emit(
        AuthFailure(
          code: 'LOGIN_ERROR',
          message: _mapFirebaseAuthMessage(error),
        ),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String nombres,
    required String apellidos,
    required String aliasPublico,
    required String telefono,
  }) async {
    emit(const AuthLoading());

    try {
      final user = await _authRepository.register(
        email: email,
        password: password,
        nombres: nombres,
        apellidos: apellidos,
        aliasPublico: aliasPublico,
        telefono: telefono,
      );

      emit(AuthAuthenticated(user));
    } on ApiException catch (error) {
      emit(AuthFailure(code: error.code, message: error.message));
    } catch (error) {
      emit(
        AuthFailure(
          code: 'REGISTER_ERROR',
          message: _mapFirebaseAuthMessage(error),
        ),
      );
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<String?> updateProfile({
    required String nombres,
    required String apellidos,
    required String aliasPublico,
    String? telefono,
    String? fotoPerfilUrl,
  }) async {
    if (state is! AuthAuthenticated) {
      return 'Inicia sesión para editar tu perfil.';
    }

    try {
      final updatedUser = await _authRepository.updateProfile(
        nombres: nombres,
        apellidos: apellidos,
        aliasPublico: aliasPublico,
        telefono: telefono,
        fotoPerfilUrl: fotoPerfilUrl,
      );
      emit(AuthAuthenticated(updatedUser));
      return null;
    } on ApiException catch (error) {
      return error.message;
    } catch (_) {
      return 'No se pudo actualizar el perfil.';
    }
  }

  Future<String?> uploadProfilePhoto(XFile image) async {
    try {
      return await _authRepository.uploadProfilePhoto(image);
    } on ApiException catch (error) {
      throw Exception(error.message);
    } catch (_) {
      throw Exception('No se pudo subir la foto de perfil.');
    }
  }

  Future<List<PointsMovementModel>> getPointsMovements() {
    return _authRepository.getPointsMovements();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    emit(const AuthLoading());

    try {
      await _authRepository.sendPasswordResetEmail(email);
      emit(AuthPasswordResetSent(email.trim()));
    } catch (error) {
      emit(
        AuthFailure(
          code: 'PASSWORD_RESET_ERROR',
          message: _mapFirebaseAuthMessage(error),
        ),
      );
    }
  }

  String _mapFirebaseAuthMessage(Object error) {
    final text = error.toString();

    if (text.contains('invalid-email')) {
      return 'Ingresa un correo electrónico válido.';
    }

    if (text.contains('user-not-found')) {
      return 'No encontramos una cuenta registrada con ese correo.';
    }

    if (text.contains('wrong-password') ||
        text.contains('invalid-credential')) {
      return 'El correo o la contraseña no son correctos.';
    }

    if (text.contains('email-already-in-use')) {
      return 'Ese correo ya está registrado.';
    }

    if (text.contains('weak-password')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }

    if (text.contains('network-request-failed')) {
      return 'No se pudo conectar. Revisa tu conexión a internet.';
    }

    return 'Ocurrió un problema. Inténtalo nuevamente.';
  }
}
