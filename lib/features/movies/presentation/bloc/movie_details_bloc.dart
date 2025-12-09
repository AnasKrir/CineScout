import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/movies_repository.dart';
import 'movie_details_event.dart';
import 'movie_details_state.dart';
import '../../domain/entities/cast_member.dart';
import '../../domain/entities/video.dart';
import '/core/language/language_cubit.dart';

class MovieDetailsBloc extends Bloc<MovieDetailsEvent, MovieDetailsState> {
  MovieDetailsBloc({
    required MoviesRepository moviesRepository,
    required LanguageCubit languageCubit,
  })  : _moviesRepository = moviesRepository,
        _languageCubit = languageCubit,
        super(const MovieDetailsLoading()) {
    on<MovieDetailsRequested>(_onRequested);
    on<MovieDetailsRetryRequested>(_onRetryRequested);
    on<MovieDetailsWatchlistToggled>(_onWatchlistToggled);
  }

  final MoviesRepository _moviesRepository;
  final LanguageCubit _languageCubit;

  int? _lastMovieId;

  // 🔹 Quand on ouvre les détails d’un film
  Future<void> _onRequested(
    MovieDetailsRequested event,
    Emitter<MovieDetailsState> emit,
  ) async {
    _lastMovieId = event.movieId;

    final lang = _languageCubit.state;
    final languageCode = lang.isFrench ? 'fr-FR' : 'en-US';

    await _loadDetails(
      movieId: event.movieId,
      languageCode: languageCode,
      emit: emit,
    );
  }

  // 🔹 Bouton "Réessayer"
  Future<void> _onRetryRequested(
    MovieDetailsRetryRequested event,
    Emitter<MovieDetailsState> emit,
  ) async {
    final id = _lastMovieId;
    if (id == null) return;

    final lang = _languageCubit.state;
    final languageCode = lang.isFrench ? 'fr-FR' : 'en-US';

    await _loadDetails(
      movieId: id,
      languageCode: languageCode,
      emit: emit,
    );
  }

  // 🔹 Toggle "Ajouter / Retirer de la Watchlist"
  Future<void> _onWatchlistToggled(
    MovieDetailsWatchlistToggled event,
    Emitter<MovieDetailsState> emit,
  ) async {
    final current = state;
    if (current is! MovieDetailsLoaded) return;

    final movie = current.movie;
    final isInWatchlist = current.isInWatchlist;

    try {
      if (isInWatchlist) {
        await _moviesRepository.removeFromWatchlist(movie.id);
      } else {
        await _moviesRepository.addToWatchlist(movie);
      }

      // Met à jour le label + l’icône
      emit(current.copyWith(isInWatchlist: !isInWatchlist));
    } catch (_) {
      emit(current); // on garde l’état actuel en cas d’erreur
    }
  }

  // 🔹 Chargement complet des détails (dans la bonne langue)
  Future<void> _loadDetails({
    required int movieId,
    required String languageCode,
    required Emitter<MovieDetailsState> emit,
  }) async {
    emit(const MovieDetailsLoading());

    try {
      // Détails dans la bonne langue
      final movie = await _moviesRepository.getMovieDetails(
        movieId,
        languageCode: languageCode,
      );

      var cast = <CastMember>[];
      var videos = <Video>[];
      var castError = false;
      var videosError = false;

      try {
        cast = await _moviesRepository.getMovieCredits(movieId);
      } catch (_) {
        castError = true;
      }

      try {
        videos = await _moviesRepository.getMovieVideos(movieId);
      } catch (_) {
        videosError = true;
      }

      // 🔹 Valeur réelle dans la watchlist (Sqflite)
      final isInWatchlist =
          await _moviesRepository.isInWatchlist(movie.id);

      emit(
        MovieDetailsLoaded(
          movie: movie,
          cast: cast,
          videos: videos,
          hasCastError: castError,
          hasVideosError: videosError,
          isInWatchlist: isInWatchlist,
        ),
      );
    } catch (_) {
      emit(
        const MovieDetailsError(
          'Impossible de charger les détails du film. Vérifiez votre connexion et réessayez.',
        ),
      );
    }
  }
}
