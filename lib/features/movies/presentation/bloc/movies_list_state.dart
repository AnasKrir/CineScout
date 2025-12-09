import 'package:equatable/equatable.dart';

import '../../domain/entities/movie.dart';

abstract class MoviesListState extends Equatable {
  const MoviesListState();

  @override
  List<Object?> get props => [];
}

class MoviesListInitial extends MoviesListState {
  const MoviesListInitial();
}

class MoviesListLoading extends MoviesListState {
  const MoviesListLoading();
}

class MoviesListLoaded extends MoviesListState {
  const MoviesListLoaded({
    required this.movies,
    required this.currentPage,
    required this.hasMore,
    this.isFetchingMore = false,
  });

  final List<Movie> movies;
  final int currentPage;
  final bool hasMore;
  final bool isFetchingMore;

  MoviesListLoaded copyWith({
    List<Movie>? movies,
    int? currentPage,
    bool? hasMore,
    bool? isFetchingMore,
  }) {
    return MoviesListLoaded(
      movies: movies ?? this.movies,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }

  @override
  List<Object?> get props => [movies, currentPage, hasMore, isFetchingMore];
}

class MoviesListError extends MoviesListState {
  const MoviesListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
