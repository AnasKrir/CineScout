import 'package:equatable/equatable.dart';

import '../../domain/entities/movie.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchEmpty extends SearchState {
  const SearchEmpty(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

class SearchLoaded extends SearchState {
  const SearchLoaded({
    required this.query,
    required this.results,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final String query;
  final List<Movie> results;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  SearchLoaded copyWith({
    String? query,
    List<Movie>? results,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return SearchLoaded(
      query: query ?? this.query,
      results: results ?? this.results,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [query, results, currentPage, hasMore, isLoadingMore];
}

class SearchError extends SearchState {
  const SearchError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
