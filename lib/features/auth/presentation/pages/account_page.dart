
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cinescout/core/language/language_cubit.dart';
import 'package:cinescout/features/auth/data/auth_repository.dart';
import 'package:cinescout/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cinescout/features/auth/presentation/bloc/auth_event.dart';
import 'package:cinescout/features/auth/presentation/bloc/auth_state.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmController;

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final authRepo = context.read<AuthRepository>();
    final initialEmail = authRepo.getCurrentEmail() ?? '';

    _emailController = TextEditingController(text: initialEmail);
    _passwordController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveChanges() async {
    final lang = context.read<LanguageCubit>().state;
    final isFr = lang.isFrench;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty) {
      _showSnack(isFr ? 'Email requis.' : 'Email is required.');
      return;
    }

    if (password.isNotEmpty && password.length < 6) {
      _showSnack(isFr
          ? 'Le mot de passe doit contenir au moins 6 caractères.'
          : 'Password must be at least 6 characters.');
      return;
    }

    if (password.isNotEmpty && password != confirm) {
      _showSnack(isFr
          ? 'Les mots de passe ne correspondent pas.'
          : 'Passwords do not match.');
      return;
    }

    if (password.isEmpty) {
      _showSnack(isFr
          ? 'Veuillez saisir un nouveau mot de passe.'
          : 'Please enter a new password.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.updateAccount(
        newEmail: email,
        newPassword: password,
      );

      // Recalcule l’état d’authentification (met à jour l’email dans AuthBloc)
      context.read<AuthBloc>().add(const AuthCheckRequested());

      _showSnack(isFr
          ? 'Compte mis à jour avec succès.'
          : 'Account updated successfully.');

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final lang = context.read<LanguageCubit>().state;
    final isFr = lang.isFrench;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isFr ? 'Supprimer le compte' : 'Delete account'),
            content: Text(isFr
                ? 'Es-tu sûr de vouloir supprimer ton compte ? Cette action est définitive.'
                : 'Are you sure you want to delete your account? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(isFr ? 'Annuler' : 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(isFr ? 'Supprimer' : 'Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isDeleting = true);

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.deleteAccount();

      context.read<AuthBloc>().add(const LogoutRequested());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageCubit>().state;
    final isFr = lang.isFrench;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFr ? 'Mon compte' : 'My account'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoggedIn = state is Authenticated;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isLoggedIn)
                  Text(
                    isFr
                        ? 'Aucun compte connecté.'
                        : 'No account is currently signed in.',
                  ),
                if (isLoggedIn) ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText:
                          isFr ? 'exemple@mail.com' : 'example@mail.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText:
                          isFr ? 'Nouveau mot de passe' : 'New password',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: isFr
                          ? 'Confirmer le mot de passe'
                          : 'Confirm password',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isFr ? 'Enregistrer' : 'Save changes',
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isFr ? 'Danger zone' : 'Danger zone',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.errorContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    onPressed: _isDeleting ? null : _deleteAccount,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(
                      isFr ? 'Supprimer mon compte' : 'Delete my account',
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
