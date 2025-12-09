import '../entities/movie.dart';
import '../entities/cast_member.dart';
import '../entities/video.dart';
import '../entities/paginated_movies.dart';

abstract class MoviesRepository {
  Future<PaginatedMovies> getPopularMovies({required int page});
  Future<PaginatedMovies> getTrendingMovies({required int page});
  Future<PaginatedMovies> searchMovies({
    required String query,
    required int page,
  });

  Future<Movie> getMovieDetails(
    int id, {
    String? languageCode,
  });
  Future<List<CastMember>> getMovieCredits(int id);
  Future<List<Video>> getMovieVideos(int id);

  // Watchlist (Sqflite)
  Future<void> addToWatchlist(Movie movie);
  Future<void> removeFromWatchlist(int id);
  Future<List<Movie>> getWatchlist();
  Future<bool> isInWatchlist(int id);

  // Cache des pages (Sqflite)
  Future<void> cacheMoviesPage({
    required String key,
    required PaginatedMovies page,
  });
  Future<PaginatedMovies?> getCachedMoviesPage({
    required String key,
  });
}
