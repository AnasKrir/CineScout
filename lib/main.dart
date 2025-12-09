import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app/app.dart';
import 'core/bloc/app_bloc_observer.dart';
import 'core/network/tmdb_client.dart';
import 'core/db/app_database.dart';

import 'core/theme/theme_cubit.dart';
import 'core/language/language_cubit.dart';

import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

import 'features/movies/domain/repositories/movies_repository.dart';
import 'features/movies/data/datasources/movies_remote_data_source.dart';
import 'features/movies/data/datasources/movies_local_data_source.dart';
import 'features/movies/data/repositories/movies_repository_impl.dart';
import 'features/movies/presentation/bloc/watchlist_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  final sharedPreferences = await SharedPreferences.getInstance();

  Bloc.observer = AppBlocObserver();

  final authRepository = AuthRepository(
    prefs: sharedPreferences,
  );

  // TMDB client
  final tmdbClient = TmdbClient();
  final moviesRemoteDataSource = MoviesRemoteDataSource(
    client: tmdbClient,
  );

  // DB locale Sqflite
  final appDatabase = AppDatabase.instance;
  final watchlistLocalDataSource = WatchlistLocalDataSource(appDatabase);
  final moviesCacheLocalDataSource = MoviesCacheLocalDataSource(appDatabase);

  final moviesRepository = MoviesRepositoryImpl(
    remoteDataSource: moviesRemoteDataSource,
    watchlistLocalDataSource: watchlistLocalDataSource,
    cacheLocalDataSource: moviesCacheLocalDataSource,
  );

  runApp(
  MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>.value(value: authRepository),
      RepositoryProvider<MoviesRepository>.value(value: moviesRepository),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) =>
              AuthBloc(authRepository: authRepository)..add(const AuthCheckRequested()),
        ),
        BlocProvider<WatchlistBloc>(
          create: (_) => WatchlistBloc(moviesRepository: moviesRepository),
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit(prefs: sharedPreferences),
        ),
        BlocProvider<LanguageCubit>(
          create: (_) => LanguageCubit(prefs: sharedPreferences),
        ),
      ],
      child: CineScoutApp(),
    ),
  ),
);
}
