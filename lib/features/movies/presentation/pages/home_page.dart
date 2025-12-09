import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'discover_page.dart';
import 'search_page.dart';
import 'package:cinescout/features/movies/presentation/pages/watchlist_page.dart';

import 'package:cinescout/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cinescout/features/auth/presentation/bloc/auth_event.dart';
import 'package:cinescout/features/auth/presentation/bloc/auth_state.dart';

import 'package:cinescout/features/movies/presentation/bloc/watchlist_bloc.dart';
import 'package:cinescout/features/movies/presentation/bloc/watchlist_event.dart';

import 'package:cinescout/core/language/language_cubit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    DiscoverPage(),
    SearchPage(),
    WatchlistPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageCubit>().state;
    final isFr = lang.isFrench;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous is Authenticated && current is Unauthenticated,
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CineScout'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: isFr ? 'Paramètres' : 'Settings',
              onPressed: () {
                // IMPORTANT : push pour pouvoir revenir en arrière
                context.push('/settings');
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: isFr ? 'Déconnexion' : 'Log out',
              onPressed: () {
                context.read<AuthBloc>().add(const LogoutRequested());
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);

            // Quand on va sur l’onglet Watchlist → rechargement
            if (index == 2) {
              context
                  .read<WatchlistBloc>()
                  .add(const WatchlistStarted());
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore),
              label: isFr ? 'Découvrir' : 'Discover',
            ),
            NavigationDestination(
              icon: const Icon(Icons.search),
              label: isFr ? 'Rechercher' : 'Search',
            ),
            const NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Watchlist',
            ),
          ],
        ),
      ),
    );
  }
}
