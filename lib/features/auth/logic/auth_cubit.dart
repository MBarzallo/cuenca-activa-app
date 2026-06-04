import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../data/auth_repository.dart';
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
