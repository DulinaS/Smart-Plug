import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/auth_repo.dart';

class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool requiresEmailVerification;
  final String? pendingEmail; // Store email for verification flow

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.requiresEmailVerification = false,
    this.pendingEmail,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? requiresEmailVerification,
    String? pendingEmail,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      requiresEmailVerification:
          requiresEmailVerification ?? this.requiresEmailVerification,
      pendingEmail: pendingEmail ?? this.pendingEmail,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AuthState()) {
    _checkAuthStatus();
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
        requiresEmailVerification: false,
        pendingEmail: null,
      );
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('UserNotConfirmedException') ||
          errorMessage.contains('not verified')) {
        state = state.copyWith(
          error: 'Please verify your email before logging in',
          isLoading: false,
          requiresEmailVerification: true,
          pendingEmail: email,
        );
      } else {
        state = state.copyWith(error: errorMessage, isLoading: false);
      }
    }
  }

  // UPDATED: include billingType
  Future<void> register(
    String email,
    String password,
    String fullName, {
    BillingType billingType = BillingType.general,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authRepository.signUp(
        email,
        password,
        fullName,
        billingType: billingType,
      );

      if (response['requiresEmailVerification'] == true) {
        state = state.copyWith(
          isLoading: false,
          requiresEmailVerification: true,
          pendingEmail: email,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> confirmEmail(String email, String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final confirmed = await _authRepository.confirmSignUp(email, code);
      if (confirmed) {
        state = state.copyWith(
          isLoading: false,
          requiresEmailVerification: false,
          pendingEmail: null,
        );
      } else {
        state = state.copyWith(
          error: 'Invalid verification code. Please try again.',
          isLoading: false,
        );
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

  void resetVerificationState() {
    state = state.copyWith(
      requiresEmailVerification: false,
      pendingEmail: null,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authRepository = ref.read(authRepositoryProvider);
    return AuthController(authRepository);
  },
);
