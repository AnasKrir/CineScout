import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'package:cinescout/core/errors/app_exception.dart';
import 'package:cinescout/features/movies/domain/entities/paginated_movies.dart';
import 'package:cinescout/features/movies/domain/repositories/movies_repository.dart';

import 'search_event.dart';
import 'search_state.dart';

EventTransformer<T> _debounce<T>(Duration duration) {
  return (events, mapper) => events
      .debounceTime(duration)
      .switchMap(mapper); // on annule les anciennes recherches si l'user tape encore
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({required MoviesRepository moviesRepository})
      : _moviesRepository = moviesRepository,
        super(const SearchInitial()) {
    on<SearchQueryChanged>(
      _onQueryChanged,
      transformer: _debounce(const Duration(milliseconds: 400)),
    );
    on<SearchSubmitted>(_onSubmitted);
    on<SearchLoadMore>(_onLoadMore);
  }

  final MoviesRepository _moviesRepository;

  String _currentQuery = '';
  bool _isFetchingMore = false;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      _currentQuery = '';
      emit(const SearchInitial());
      return;
    }

    // Si même query que l'état actuel -> on ne relance pas
    if (state is SearchLoaded && _currentQuery == query) return;

    _currentQuery = query;
    emit(const SearchLoading());

    try {
      final PaginatedMovies result =
          await _moviesRepository.searchMovies(query: query, page: 1);

      if (result.results.isEmpty) {
        emit(SearchEmpty(query));
      } else {
        emit(SearchLoaded(
          query: query,
          results: result.results,
          currentPage: result.page,
          hasMore: result.hasMore,
        ));
      }
    } catch (e) {
      if (e is AppException) {
        emit(SearchError(e.message));
      } else {
        emit(const SearchError('Erreur lors de la recherche.'));
      }
    }
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    // On force la recherche immédiate, sans debounce
    return _onQueryChanged(SearchQueryChanged(event.query), emit);
  }

  Future<void> _onLoadMore(
    SearchLoadMore event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SearchLoaded) return;
    if (!currentState.hasMore || _isFetchingMore) return;
    if (_currentQuery.isEmpty) return;

    _isFetchingMore = true;
    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final PaginatedMovies result = await _moviesRepository.searchMovies(
        query: _currentQuery,
        page: nextPage,
      );

      emit(
        currentState.copyWith(
          results: [...currentState.results, ...result.results],
          currentPage: result.page,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      // On ne casse pas tout si la page suivante échoue
      emit(currentState.copyWith(isLoadingMore: false));
    } finally {
      _isFetchingMore = false;
    }
  }
}
