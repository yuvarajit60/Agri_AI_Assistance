import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-level language setting — deliberately independent of AppUser.
/// preferredLanguage (which only exists after login) so the UI can render
/// in the chosen language from the very first screen, not just after
/// authentication.
class LanguageController extends StateNotifier<String> {
  LanguageController() : super('en') {
    _load();
  }

  static const _key = 'app_language_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) state = saved;
  }

  Future<void> setLanguage(String code) async {
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}

final languageProvider = StateNotifierProvider<LanguageController, String>((ref) => LanguageController());
