// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await _authRepository.hasSession();
    if (isLoggedIn) {
      final email = _authRepository.getCurrentEmail();
      emit(Authenticated(email: email ?? ''));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final email = event.email.trim();
    final password = event.password.trim();

    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      emit(const Unauthenticated(message: 'Invalid email address'));
      return;
    }

    if (password.length < 6) {
      emit(
        const Unauthenticated(
          message: 'The password must contain at least 6 characters',
        ),
      );
      return;
    }

    final hasUser = await _authRepository.hasRegisteredUser();
    if (!hasUser) {
      emit(const Unauthenticated(message: 'No account found. Please register'));
      return;
    }

    final isValid = await _authRepository.validateCredentials(
      email: email,
      password: password,
    );

    if (!isValid) {
      emit(const Unauthenticated(message: 'Incorrect email or password'));
      return;
    }

    await _authRepository.login(email: email, password: password);

    emit(Authenticated(email: email));
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final email = event.email.trim();
    final password = event.password.trim();

    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      emit(const Unauthenticated(message: 'Invalid email address'));
      return;
    }

    if (password.length < 6) {
      emit(
        const Unauthenticated(
          message: 'The password must contain at least 6 characters',
        ),
      );
      return;
    }

    await _authRepository.register(email: email, password: password);
    await _authRepository.login(email: email, password: password);

    emit(Authenticated(email: email));
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const Unauthenticated());
  }
}
