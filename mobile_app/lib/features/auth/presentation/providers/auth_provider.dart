import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../farms/data/farm_sync_repository.dart';
import '../../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());
final farmSyncRepositoryProvider = Provider<FarmSyncRepository>((ref) => FarmSyncRepository());

enum AuthStatus { unknown, unauthenticated, otpSent, authenticatedIncompleteProfile, authenticated }

class AuthState {
  const AuthState({required this.status, this.user, this.pendingPhoneNumber, this.errorMessage});

  final AuthStatus status;
  final AppUser? user;
  final String? pendingPhoneNumber;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? pendingPhoneNumber,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      pendingPhoneNumber: pendingPhoneNumber ?? this.pendingPhoneNumber,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository, this._farmSync) : super(const AuthState(status: AuthStatus.unknown)) {
    _restore();
  }

  final AuthRepository _repository;
  final FarmSyncRepository _farmSync;

  Future<void> _restore() async {
    final user = await _repository.restoreSession();
    if (user == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } else {
      state = state.copyWith(
        status: user.hasCompletedProfile ? AuthStatus.authenticated : AuthStatus.authenticatedIncompleteProfile,
        user: user,
      );
      _syncBackendUserId(user);
    }
  }

  /// Best-effort, fire-and-forget: resolves this phone number to a real
  /// farm_registry (PostgreSQL) user UUID so farms created this session
  /// can sync server-side. Never blocks login — see
  /// farm_sync_repository.dart for the offline-tolerant reasoning.
  void _syncBackendUserId(AppUser user) {
    if (user.backendUserId != null) return;
    _farmSync.ensureBackendUser(user.phoneNumber).then((backendId) async {
      if (backendId == null) return;
      final updated = await _repository.updateProfile(user.copyWith(backendUserId: backendId));
      if (state.user?.phoneNumber == updated.phoneNumber) {
        state = state.copyWith(user: updated);
      }
    });
  }

  Future<bool> sendOtp(String phoneNumber) async {
    state = state.copyWith(clearError: true);
    try {
      await _repository.sendOtp(phoneNumber);
      state = state.copyWith(status: AuthStatus.otpSent, pendingPhoneNumber: phoneNumber);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String code) async {
    final phone = state.pendingPhoneNumber;
    if (phone == null) return false;
    state = state.copyWith(clearError: true);
    try {
      final user = await _repository.verifyOtp(phone, code);
      state = state.copyWith(
        status: user.hasCompletedProfile ? AuthStatus.authenticated : AuthStatus.authenticatedIncompleteProfile,
        user: user,
      );
      _syncBackendUserId(user);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<void> completeProfile({required String name, String? stateName, String? district}) async {
    final current = state.user;
    if (current == null) return;
    final updated = await _repository.updateProfile(
      current.copyWith(name: name, state: stateName, district: district),
    );
    state = state.copyWith(status: AuthStatus.authenticated, user: updated);
  }

  /// For editing an already-complete profile (name/state/district) or
  /// changing the language preference — distinct from [completeProfile]
  /// only in that it doesn't force a specific name (callers already have
  /// one) and never changes [AuthStatus].
  Future<void> updateProfile({String? name, String? stateName, String? district, String? preferredLanguage}) async {
    final current = state.user;
    if (current == null) return;
    final updated = await _repository.updateProfile(
      current.copyWith(name: name, state: stateName, district: district, preferredLanguage: preferredLanguage),
    );
    state = state.copyWith(user: updated);
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref.watch(farmSyncRepositoryProvider));
});
