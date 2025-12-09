// lib/features/auth/presentation/pages/manage_account_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/language/language_cubit.dart';

class ManageAccountPage extends StatefulWidget {
  const ManageAccountPage({super.key});

  @override
  State<ManageAccountPage> createState() => _ManageAccountPageState();
}

class _ManageAccountPageState extends State<ManageAccountPage> {
  late final TextEditingController _emailController;
  final TextEditingController _passwordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    final authRepo = context.read<AuthRepository>();
    final initialEmail = authRepo.getCurrentEmail() ?? '';
    _emailController = TextEditingController(text: initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    final confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty) {
      _showSnack(isFr ? 'L’e-mail est requis' : 'E-mail is required');
      return;
    }

    if (password.isNotEmpty && password != confirmPassword) {
      _showSnack(
        isFr
            ? 'Les mots de passe ne correspondent pas'
            : 'Passwords do not match',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final authRepo = context.read<AuthRepository>();

      await authRepo.updateAccount(
        newEmail: email,
        // si password vide → on garde l’ancien
        newPassword: password.isEmpty ? null : password,
      );

      // Recalcule l’état d’authentification
      context.read<AuthBloc>().add(const AuthCheckRequested());

      _passwordController.clear();
      _confirmPasswordController.clear();

      _showSnack(
        isFr
            ? 'Compte mis à jour avec succès'
            : 'Account updated successfully',
      );
    } catch (_) {
      _showSnack(
        isFr
            ? 'Erreur lors de la mise à jour du compte'
            : 'Error while updating account',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAccount() async {
    final lang = context.read<LanguageCubit>().state;
    final isFr = lang.isFrench;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isFr ? 'Supprimer le compte' : 'Delete account'),
        content: Text(
          isFr
              ? 'Êtes-vous sûr de vouloir supprimer votre compte ? '
                'Cette action est irréversible.'
              : 'Are you sure you want to delete your account? '
                'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isFr ? 'Annuler' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isFr ? 'Supprimer' : 'Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.deleteAccount();

      // Met AuthBloc à jour et renvoie vers login
      context.read<AuthBloc>().add(const LogoutRequested());
      context.read<AuthBloc>().add(const AuthCheckRequested());

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (_) {
      _showSnack(
        isFr
            ? 'Erreur lors de la suppression du compte'
            : 'Error while deleting account',
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageCubit>().state;
    final isFr = lang.isFrench;
    final isAuthenticated =
        context.watch<AuthBloc>().state is Authenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFr ? 'Mon compte' : 'My account'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.person,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFr ? 'Informations du compte' : 'Account information',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAuthenticated
                          ? (isFr
                              ? 'Vous êtes actuellement connecté.'
                              : 'You are currently signed in.')
                          : (isFr
                              ? 'Vous n’êtes pas connecté.'
                              : 'You are not signed in.'),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color:
                                colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // EMAIL
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: isFr ? 'E-mail' : 'E-mail',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // NEW PASSWORD
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText:
                  isFr ? 'Nouveau mot de passe' : 'New password',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // CONFIRM PASSWORD
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: isFr
                  ? 'Confirmer le nouveau mot de passe'
                  : 'Confirm new password',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _isSaving ? null : _saveChanges,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isFr ? 'Enregistrer les modifications' : 'Save changes'),
          ),

          const SizedBox(height: 32),

          Text(
            isFr ? 'Zone dangereuse' : 'Danger zone',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: colorScheme.error),
          ),
          const SizedBox(height: 8),

          OutlinedButton.icon(
            icon: const Icon(Icons.delete_outline),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
            ),
            onPressed: _isDeleting ? null : _deleteAccount,
            label: _isDeleting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    isFr ? 'Supprimer mon compte' : 'Delete my account',
                  ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: () {
              context
                  .read<AuthBloc>()
                  .add(const LogoutRequested());
            },
            icon: const Icon(Icons.logout),
            label: Text(isFr ? 'Se déconnecter' : 'Log out'),
          ),
        ],
      ),
    );
  }
}
