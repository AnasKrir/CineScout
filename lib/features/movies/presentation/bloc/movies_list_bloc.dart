import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/paginated_movies.dart';
import '../../domain/repositories/movies_repository.dart';
import 'movies_list_category.dart';
import 'movies_list_event.dart';
import 'movies_list_state.dart';

class MoviesListBloc extends Bloc<MoviesListEvent, MoviesListState> {
  MoviesListBloc({
    required MoviesRepository moviesRepository,
    required MoviesListCategory category,
  })  : _moviesRepository = moviesRepository,
        _category = category,
        super(const MoviesListInitial()) {
    on<FetchFirstPage>(_onFetchFirstPage);
    on<FetchNextPage>(_onFetchNextPage);
    on<RefreshMovies>(_onRefreshMovies);
  }

  final MoviesRepository _moviesRepository;
  final MoviesListCategory _category;
  bool _isFetching = false;

  Future<PaginatedMovies> _fetchPage(int page) {
    switch (_category) {
      case MoviesListCategory.popular:
        return _moviesRepository.getPopularMovies(page: page);
      case MoviesListCategory.trending:
        return _moviesRepository.getTrendingMovies(page: page);
    }
  }

  Future<void> _onFetchFirstPage(
    FetchFirstPage event,
    Emitter<MoviesListState> emit,
  ) async {
    if (_isFetching) return;
    _isFetching = true;
    emit(const MoviesListLoading());
    try {
      final result = await _fetchPage(1);
      emit(
        MoviesListLoaded(
          movies: result.results,
          currentPage: result.page,
          hasMore: result.hasMore,
        ),
      );
    } catch (e) {
      emit(
        MoviesListError(
          'Impossible de charger les films ${_category.label.toLowerCase()}.',
        ),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _onFetchNextPage(
    FetchNextPage event,
    Emitter<MoviesListState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MoviesListLoaded) return;
    if (!currentState.hasMore || currentState.isFetchingMore) return;
    if (_isFetching) return;

    _isFetching = true;
    emit(currentState.copyWith(isFetchingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final result = await _fetchPage(nextPage);

      emit(
        MoviesListLoaded(
          movies: [...currentState.movies, ...result.results],
          currentPage: result.page,
          hasMore: result.hasMore,
          isFetchingMore: false,
        ),
      );
    } catch (e) {
      // On garde la liste déjà chargée, on coupe juste le "loading more"
      emit(currentState.copyWith(isFetchingMore: false));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _onRefreshMovies(
    RefreshMovies event,
    Emitter<MoviesListState> emit,
  ) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final result = await _fetchPage(1);
      emit(
        MoviesListLoaded(
          movies: result.results,
          currentPage: result.page,
          hasMore: result.hasMore,
          isFetchingMore: false,
        ),
      );
    } catch (e) {
      emit(
        MoviesListError(
          'Impossible d’actualiser les films ${_category.label.toLowerCase()}.',
        ),
      );
    } finally {
      _isFetching = false;
    }
  }
}