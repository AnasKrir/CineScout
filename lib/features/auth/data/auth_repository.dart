import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  AuthRepository({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _keyEmail = 'auth_email';
  static const _keyPassword = 'auth_password';
  static const _keySessionEmail = 'auth_session_email';

  // ───────────────────── Sessions ─────────────────────

  Future<bool> hasSession() async {
    return _prefs.getString(_keySessionEmail) != null;
  }

  String? getCurrentEmail() {
    return _prefs.getString(_keySessionEmail);
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    // 👉 À ce stade, le BLoC a déjà validé les credentials.
    await _prefs.setString(_keySessionEmail, email);
  }

  Future<void> logout() async {
    await _prefs.remove(_keySessionEmail);
  }

  // ───────────────────── Compte enregistré ─────────────────────

  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _prefs.setString(_keyEmail, email);
    await _prefs.setString(_keyPassword, password);
  }

  Future<bool> hasRegisteredUser() async {
    final email = _prefs.getString(_keyEmail);
    final password = _prefs.getString(_keyPassword);
    return email != null && password != null;
  }

  Future<bool> validateCredentials({
    required String email,
    required String password,
  }) async {
    final storedEmail = _prefs.getString(_keyEmail);
    final storedPassword = _prefs.getString(_keyPassword);
    return storedEmail == email && storedPassword == password;
  }

  // ───────────────────── Update / Delete ─────────────────────

  /// Met à jour email et/ou mot de passe.
  /// - `newEmail` ou `newPassword` peuvent être null → on garde l’ancienne valeur.
  Future<void> updateAccount({
    String? newEmail,
    String? newPassword,
  }) async {
    final currentEmail = _prefs.getString(_keyEmail);
    final currentPassword = _prefs.getString(_keyPassword);

    final updatedEmail = newEmail ?? currentEmail;
    final updatedPassword = newPassword ?? currentPassword;

    if (updatedEmail == null || updatedPassword == null) {
      // Cas théorique : aucun compte enregistré.
      return;
    }

    await _prefs.setString(_keyEmail, updatedEmail);
    await _prefs.setString(_keyPassword, updatedPassword);

    // Si une session existe, on garde l’email de session aligné.
    if (_prefs.getString(_keySessionEmail) != null) {
      await _prefs.setString(_keySessionEmail, updatedEmail);
    }
  }

  Future<void> deleteAccount() async {
    await _prefs.remove(_keyEmail);
    await _prefs.remove(_keyPassword);
    await _prefs.remove(_keySessionEmail);
  }
}
