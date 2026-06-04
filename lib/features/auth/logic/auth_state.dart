import 'package:equatable/equatable.dart';

import '../data/auth_user_model.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  final AuthUserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthNeedsInternalRegister extends AuthState {
  final String message;

  const AuthNeedsInternalRegister(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {
  final String email;

  const AuthPasswordResetSent(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthFailure extends AuthState {
  final String code;
  final String message;

  const AuthFailure({required this.code, required this.message});

  @override
  List<Object?> get props => [code, message];
}
