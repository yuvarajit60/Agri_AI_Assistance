import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Authenticated farmer profile. Deliberately minimal for the MVP —
/// mirrors the User/Farm Registry service's core fields (see
/// docs/architecture/ARCHITECTURE.md §3) so the shape doesn't need to
/// change when this repository is swapped for a real backend client.
class AppUser {
  const AppUser({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.state,
    this.district,
    this.preferredLanguage = 'en',
    this.backendUserId,
  });

  final String id;
  final String phoneNumber;
  final String? name;
  final String? state;
  final String? district;
  final String preferredLanguage;

  /// farm_registry's UUID for this phone number, once PostgreSQL sync has
  /// succeeded — see farm_sync_repository.dart. Null means "not synced
  /// yet" (offline, or backend unreachable); farms stay local-only until
  /// this resolves.
  final String? backendUserId;

  bool get hasCompletedProfile => name != null && name!.trim().isNotEmpty;

  AppUser copyWith({
    String? name,
    String? state,
    String? district,
    String? preferredLanguage,
    String? backendUserId,
  }) {
    return AppUser(
      id: id,
      phoneNumber: phoneNumber,
      name: name ?? this.name,
      state: state ?? this.state,
      district: district ?? this.district,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      backendUserId: backendUserId ?? this.backendUserId,
    );
  }
}

/// Contract the real backend (Firebase Auth / gateway-issued JWT, per
/// ARCHITECTURE.md §10) will implement. Screens and providers only ever
/// depend on this interface, never on the mock directly.
abstract class AuthRepository {
  Future<AppUser?> restoreSession();
  Future<void> sendOtp(String phoneNumber);
  Future<AppUser> verifyOtp(String phoneNumber, String code);
  Future<AppUser> updateProfile(AppUser user);
  Future<void> signOut();
}

/// Session + profile persisted on-device (SharedPreferences), keyed by
/// phone number, so a returning farmer isn't asked to re-enter their name
/// every launch — only the OTP step (matching a real SMS-auth flow) and
/// only if they've signed out. Any 4+ digit code is accepted; the OTP is
/// printed as a `debugPrint` "SMS" for now, since no SMS provider is wired
/// up yet.
class MockAuthRepository implements AuthRepository {
  final Map<String, String> _pendingOtps = {};
  static const _sessionPhoneKey = 'auth_session_phone_v1';
  static const _profilesKey = 'auth_profiles_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<Map<String, dynamic>> _loadProfiles() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_profilesKey);
    if (raw == null) return {};
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _saveProfiles(Map<String, dynamic> profiles) async {
    final prefs = await _prefs;
    await prefs.setString(_profilesKey, jsonEncode(profiles));
  }

  AppUser _userFromProfile(String phoneNumber, Map<String, dynamic>? profile) {
    return AppUser(
      id: 'mock-${phoneNumber.hashCode}',
      phoneNumber: phoneNumber,
      name: profile?['name'] as String?,
      state: profile?['state'] as String?,
      district: profile?['district'] as String?,
      preferredLanguage: profile?['preferredLanguage'] as String? ?? 'en',
      backendUserId: profile?['backendUserId'] as String?,
    );
  }

  @override
  Future<AppUser?> restoreSession() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final prefs = await _prefs;
    final phone = prefs.getString(_sessionPhoneKey);
    if (phone == null) return null;
    final profiles = await _loadProfiles();
    return _userFromProfile(phone, profiles[phone] as Map<String, dynamic>?);
  }

  @override
  Future<void> sendOtp(String phoneNumber) async {
    await Future.delayed(const Duration(milliseconds: 700));
    const code = '123456';
    _pendingOtps[phoneNumber] = code;
    // ignore: avoid_print
    print('[MockAuthRepository] OTP for $phoneNumber is $code');
  }

  @override
  Future<AppUser> verifyOtp(String phoneNumber, String code) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final expected = _pendingOtps[phoneNumber];
    if (expected == null || code != expected) {
      throw AuthException('Incorrect code. Please try again.');
    }
    final prefs = await _prefs;
    await prefs.setString(_sessionPhoneKey, phoneNumber);
    final profiles = await _loadProfiles();
    return _userFromProfile(phoneNumber, profiles[phoneNumber] as Map<String, dynamic>?);
  }

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final profiles = await _loadProfiles();
    profiles[user.phoneNumber] = {
      'name': user.name,
      'state': user.state,
      'district': user.district,
      'preferredLanguage': user.preferredLanguage,
      'backendUserId': user.backendUserId,
    };
    await _saveProfiles(profiles);
    return user;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final prefs = await _prefs;
    await prefs.remove(_sessionPhoneKey);
  }
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
