import 'package:go_router/go_router.dart';

import 'package:cinescout/features/movies/presentation/pages/splash_page.dart';
import 'package:cinescout/features/auth/presentation/pages/login_page.dart';
import 'package:cinescout/features/auth/presentation/pages/register_page.dart';
import 'package:cinescout/features/movies/presentation/pages/home_page.dart';
import 'package:cinescout/features/movies/presentation/pages/movie_details_page.dart';
import 'package:cinescout/features/settings/presentation/pages/settings_page.dart';
import 'package:cinescout/features/movies/domain/entities/movie.dart';

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/movie/:id',
        name: 'movieDetails',
        builder: (context, state) {
          final movieId = int.parse(state.pathParameters['id']!);

          Movie? movie;
          String? heroTag;

          final extra = state.extra;
          if (extra is Map) {
            final maybeMovie = extra['movie'];
            final maybeHero = extra['heroTag'];
            if (maybeMovie is Movie) {
              movie = maybeMovie;
            }
            if (maybeHero is String) {
              heroTag = maybeHero;
            }
          }

          return MovieDetailsPage(
            movieId: movieId,
            initialMovie: movie,
            heroTag: heroTag,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}
