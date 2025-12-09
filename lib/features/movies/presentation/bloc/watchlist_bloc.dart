import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/movies_repository.dart';
import '../../domain/entities/movie.dart';
import 'watchlist_event.dart';
import 'watchlist_state.dart';

class WatchlistBloc extends Bloc<WatchlistEvent, WatchlistState> {
  WatchlistBloc({required MoviesRepository moviesRepository})
      : _moviesRepository = moviesRepository,
        super(const WatchlistInitial()) {
    on<WatchlistStarted>(_onLoad);
    on<WatchlistRefreshed>(_onLoad);
    on<WatchlistItemRemoved>(_onRemove);
  }

  final MoviesRepository _moviesRepository;

  Future<void> _onLoad(
    WatchlistEvent event,
    Emitter<WatchlistState> emit,
  ) async {
    emit(const WatchlistLoading());
    try {
      final List<Movie> movies =
          await _moviesRepository.getWatchlist();
      if (movies.isEmpty) {
        emit(const WatchlistEmpty());
      } else {
        emit(WatchlistLoaded(movies));
      }
    } catch (_) {
      emit(const WatchlistError(
        'Impossible de charger la watchlist.',
      ));
    }
  }

  Future<void> _onRemove(
    WatchlistItemRemoved event,
    Emitter<WatchlistState> emit,
  ) async {
    final current = state;
    if (current is! WatchlistLoaded) return;

    await _moviesRepository.removeFromWatchlist(event.movieId);
    final updated =
        current.movies.where((m) => m.id != event.movieId).toList();

    if (updated.isEmpty) {
      emit(const WatchlistEmpty());
    } else {
      emit(WatchlistLoaded(updated));
    }
  }
}
