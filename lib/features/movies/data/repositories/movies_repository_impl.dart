import '../../domain/entities/movie.dart';
import '../../domain/entities/cast_member.dart';
import '../../domain/entities/video.dart';
import '../../domain/entities/paginated_movies.dart';
import '../../domain/repositories/movies_repository.dart';
import '../datasources/movies_remote_data_source.dart';
import '../datasources/movies_local_data_source.dart';
import '../../../../core/errors/app_exception.dart';

class MoviesRepositoryImpl implements MoviesRepository {
  MoviesRepositoryImpl({
    required MoviesRemoteDataSource remoteDataSource,
    required WatchlistLocalDataSource watchlistLocalDataSource,
    required MoviesCacheLocalDataSource cacheLocalDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _watchlistLocalDataSource = watchlistLocalDataSource,
        _cacheLocalDataSource = cacheLocalDataSource;

  final MoviesRemoteDataSource _remoteDataSource;
  final WatchlistLocalDataSource _watchlistLocalDataSource;
  final MoviesCacheLocalDataSource _cacheLocalDataSource;

  // ------- POPULAIRES + CACHE -------
  @override
  Future<PaginatedMovies> getPopularMovies({
    required int page,
  }) async {
    final cacheKey = 'popular_movies_page_$page';

    try {
      final response =
          await _remoteDataSource.getPopularMovies(page: page);

      final movies =
          response.results.map((dto) => dto.toDomain()).toList();

      final paginated = PaginatedMovies(
        page: response.page,
        totalPages: response.totalPages,
        totalResults: response.totalResults,
        results: movies,
      );

      await cacheMoviesPage(key: cacheKey, page: paginated);
      return paginated;
    } on AppException {
      final cached =
          await getCachedMoviesPage(key: cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }

  // ------- TENDANCE + CACHE -------
  @override
  Future<PaginatedMovies> getTrendingMovies({
    required int page,
  }) async {
    final cacheKey = 'trending_movies_page_$page';

    try {
      final response =
          await _remoteDataSource.getTrendingMovies(page: page);

      final movies =
          response.results.map((dto) => dto.toDomain()).toList();

      final paginated = PaginatedMovies(
        page: response.page,
        totalPages: response.totalPages,
        totalResults: response.totalResults,
        results: movies,
      );

      await cacheMoviesPage(key: cacheKey, page: paginated);
      return paginated;
    } on AppException {
      final cached =
          await getCachedMoviesPage(key: cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }

  // ------- SEARCH + CACHE -------
  @override
  Future<PaginatedMovies> searchMovies({
    required String query,
    required int page,
  }) async {
    final cacheKey = 'search_${query}_page_$page';

    try {
      final response = await _remoteDataSource.searchMovies(
        query: query,
        page: page,
      );

      final movies =
          response.results.map((dto) => dto.toDomain()).toList();

      final paginated = PaginatedMovies(
        page: response.page,
        totalPages: response.totalPages,
        totalResults: response.totalResults,
        results: movies,
      );

      await cacheMoviesPage(key: cacheKey, page: paginated);
      return paginated;
    } on AppException {
      final cached =
          await getCachedMoviesPage(key: cacheKey);
      if (cached != null) return cached;
      rethrow;
    }
  }

  // ------- DETAILS / CAST / VIDEOS -------
  @override
      Future<Movie> getMovieDetails(
        int id, {
        String? languageCode,
      }) async {
        final dto = await _remoteDataSource.getMovieDetails(
          id,
          languageCode: languageCode,
        );
        return dto.toDomain();
      }


  @override
  Future<List<CastMember>> getMovieCredits(int id) async {
    final dtos = await _remoteDataSource.getMovieCredits(id);
    return dtos.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Video>> getMovieVideos(int id) async {
    final dtos = await _remoteDataSource.getMovieVideos(id);
    return dtos.map((e) => e.toDomain()).toList();
  }

  // ------- WATCHLIST (Sqflite) -------
  @override
  Future<void> addToWatchlist(Movie movie) {
    return _watchlistLocalDataSource.addToWatchlist(movie);
  }

  @override
  Future<void> removeFromWatchlist(int id) {
    return _watchlistLocalDataSource.removeFromWatchlist(id);
  }

  @override
  Future<List<Movie>> getWatchlist() {
    return _watchlistLocalDataSource.getWatchlist();
  }

  @override
  Future<bool> isInWatchlist(int id) {
    return _watchlistLocalDataSource.isInWatchlist(id);
  }

  // ------- CACHE (Sqflite) -------
  @override
  Future<void> cacheMoviesPage({
    required String key,
    required PaginatedMovies page,
  }) {
    return _cacheLocalDataSource.cachePage(key: key, page: page);
  }

  @override
  Future<PaginatedMovies?> getCachedMoviesPage({
    required String key,
  }) {
    return _cacheLocalDataSource.getCachedPage(key);
  }
}
