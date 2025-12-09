// lib/core/language/language_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Deux langues possibles : français / anglais
enum AppLanguage { fr, en }

extension AppLanguageX on AppLanguage {
  bool get isFrench => this == AppLanguage.fr;
  bool get isEnglish => this == AppLanguage.en;

  /// Code TMDB correspondant
  String get tmdbCode => isFrench ? 'fr-FR' : 'en-US';
}

class LanguageCubit extends Cubit<AppLanguage> {
  LanguageCubit({required SharedPreferences prefs})
      : _prefs = prefs,
        super(_loadInitial(prefs));

  static const _prefsKey = 'app_language';
  final SharedPreferences _prefs;

  static AppLanguage _loadInitial(SharedPreferences prefs) {
    final stored = prefs.getString(_prefsKey);
    switch (stored) {
      case 'fr':
        return AppLanguage.fr;
      case 'en':
      default:
        return AppLanguage.en;
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    emit(language);
    await _prefs.setString(
      _prefsKey,
      language == AppLanguage.fr ? 'fr' : 'en',
    );
  }

  /// Inverse FR ↔ EN
  Future<void> toggle() async {
    final next =
        state == AppLanguage.fr ? AppLanguage.en : AppLanguage.fr;
    await setLanguage(next);
  }
}
