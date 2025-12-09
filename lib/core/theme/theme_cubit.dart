import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({required SharedPreferences prefs})
      : _prefs = prefs,
        super(_loadInitialTheme(prefs));

  static const _prefsKey = 'theme_mode';
  final SharedPreferences _prefs;

  static ThemeMode _loadInitialTheme(SharedPreferences prefs) {
    final value = prefs.getString(_prefsKey);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_prefsKey, value);
  }

  Future<void> toggleLightDark() async {
    if (state == ThemeMode.light) {
      await setTheme(ThemeMode.dark);
    } else {
      await setTheme(ThemeMode.light);
    }
  }
}
