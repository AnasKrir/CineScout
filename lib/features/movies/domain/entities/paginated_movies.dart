// lib/features/movies/domain/entities/paginated_movies.dart
import 'movie.dart';

class PaginatedMovies {
  final int page;
  final List<Movie> results;
  final int totalPages;
  final int totalResults;

  const PaginatedMovies({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  /// Indique s’il reste encore des pages disponibles à charger.
  /// TMDB renvoie `page` et `total_pages`, on considère qu’il y a
  /// encore des résultats tant que la page courante est < totalPages.
  bool get hasMore => page < totalPages;
}
