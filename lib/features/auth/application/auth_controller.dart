import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repo.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthState()) {
    //_checkAuthStatus();
    // For testing purposes, we can mock a login
    _mockLogin();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authRepository.getCurrentUser();
      state = state.copyWith(
        user: user,
        isAuthenticated: user != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authRepository.login(email, password);
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authRepository.signUp(email, password, fullName);
      state = state.copyWith(isLoading: false);
      // User needs to verify email before logging in
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // ALSO ADD THIS METHOD for email confirmation:
  Future<void> confirmEmail(String email, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final confirmed = await _authRepository.confirmSignUp(email, code);
      if (confirmed) {
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(error: 'Verification failed', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authRepository.logout();
      state = const AuthState();
    } catch (e) {
      state = const AuthState();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void _mockLogin() {
    // Create a fake user for testing
    final mockUser = User(
      id: 'mock-user-123',
      email: 'dulina@gmail.com',
      username: 'testuser',
      displayName: 'Dulina User',
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      user: mockUser,
      isAuthenticated: true,
      isLoading: false,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    return AuthController(authRepository);
  },
);
