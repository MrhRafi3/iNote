import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages app preferences: theme mode (System/Light/Dark), haptic preference, etc.
class PreferencesRepository extends ChangeNotifier {
  PreferencesRepository._();
  static final PreferencesRepository instance = PreferencesRepository._();

  static const String _kThemeMode = 'theme_mode_v2';
  static const String _kLegacyDarkMode = 'darkMode';
  static const String _kHapticsEnabled = 'haptics_enabled';

  ThemeMode _themeMode = ThemeMode.system;
  bool _hapticsEnabled = true;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  ThemeMode get themeMode => _themeMode;
  bool get hapticsEnabled => _hapticsEnabled;

  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Check v2 theme mode first
    final savedMode = prefs.getString(_kThemeMode);
    if (savedMode != null) {
      if (savedMode == 'light') _themeMode = ThemeMode.light;
      if (savedMode == 'dark') _themeMode = ThemeMode.dark;
      if (savedMode == 'system') _themeMode = ThemeMode.system;
    } else if (prefs.containsKey(_kLegacyDarkMode)) {
      // Migrate legacy boolean
      final legacyDark = prefs.getBool(_kLegacyDarkMode) ?? true;
      _themeMode = legacyDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    _hapticsEnabled = prefs.getBool(_kHapticsEnabled) ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await prefs.setString(_kThemeMode, val);
    // Keep legacy key in sync for backward compatibility
    await prefs.setBool(_kLegacyDarkMode, mode == ThemeMode.dark);
  }

  Future<void> toggleHaptics(bool enabled) async {
    _hapticsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHapticsEnabled, enabled);
  }
}
