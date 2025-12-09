import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
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

class Authenticated extends AuthState {
  const Authenticated({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

class Unauthenticated extends AuthState {
  const Unauthenticated({this.message});

  final String? message;

  @override
  List<Object?> get props => [message];
}