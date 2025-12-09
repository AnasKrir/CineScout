import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:cinescout/core/theme/theme_cubit.dart';
import 'package:cinescout/core/language/language_cubit.dart';
import 'package:cinescout/features/auth/presentation/pages/account_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lang = context.watch<LanguageCubit>().state;
    final isFr = lang.isFrench;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFr ? 'Paramètres' : 'Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Thème clair/sombre
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              final isDark = themeMode == ThemeMode.dark;

              return SwitchListTile(
                title: Text(isFr ? 'Thème' : 'Theme'),
                subtitle: Text(
                  isDark
                      ? (isFr ? 'Mode sombre activé' : 'Dark mode enabled')
                      : (isFr ? 'Mode clair activé' : 'Light mode enabled'),
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                value: isDark,
                onChanged: (_) {
                  context.read<ThemeCubit>().toggleLightDark();
                },
              );
            },
          ),

          const Divider(),

          // Langue FR / EN
          BlocBuilder<LanguageCubit, AppLanguage>(
            builder: (context, langState) {
              final isEnglish = langState.isEnglish;

              return SwitchListTile(
                title: Text(isFr ? 'Langue' : 'Language'),
                subtitle: Text(
                  isEnglish ? 'English (EN)' : 'Français (FR)',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                value: isEnglish,
                onChanged: (_) {
                  context.read<LanguageCubit>().toggle();
                },
              );
            },
          ),

          const Divider(),

          // Gestion du compte utilisateur
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: Text(
              isFr ? 'Gérer mon compte' : 'Manage my account',
            ),
            subtitle: Text(
              isFr
                  ? 'Voir les informations du compte et se déconnecter'
                  : 'View account info and log out',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AccountPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
