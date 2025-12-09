import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/paginated_movies.dart';

/// --------------------
/// WATCHLIST (Sqflite)
/// --------------------
class WatchlistLocalDataSource {
  WatchlistLocalDataSource(this._db);

  final AppDatabase _db;

  Future<Database> get _database async => await _db.database;

  Future<void> addToWatchlist(Movie movie) async {
    final db = await _database;

    await db.insert(
      'watchlist',
      {
        'id': movie.id,
        'title': movie.title,
        'posterPath': movie.posterPath,
        'overview': movie.overview,
        'voteAverage': movie.voteAverage,
        'type': 'movie', // plus tard tu pourras mettre 'tv'
        'addedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> removeFromWatchlist(int id) async {
    final db = await _database;
    await db.delete(
      'watchlist',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Movie>> getWatchlist() async {
    final db = await _database;
    final rows =
        await db.query('watchlist', orderBy: 'addedAt DESC');

    return rows.map((map) {
      return Movie(
        id: map['id'] as int,
        title: map['title'] as String,
        overview: map['overview'] as String?,
        posterPath: map['posterPath'] as String?,
        backdropPath: null,
        voteAverage:
            (map['voteAverage'] as num?)?.toDouble() ?? 0.0,
        releaseDate: null,
      );
    }).toList();
  }

  Future<bool> isInWatchlist(int id) async {
    final db = await _database;
    final res = await db.query(
      'watchlist',
      columns: ['id'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return res.isNotEmpty;
  }
}

/// --------------------
/// CACHE PAGES (Sqflite)
/// --------------------
class MoviesCacheLocalDataSource {
  MoviesCacheLocalDataSource(this._db);

  final AppDatabase _db;

  Future<Database> get _database async => await _db.database;

  Future<void> cachePage({
    required String key,
    required PaginatedMovies page,
  }) async {
    final db = await _database;

    final jsonString =
        jsonEncode(_paginatedMoviesToJson(page));

    await db.insert(
      'cached_pages',
      {
        'key': key,
        'json': jsonString,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PaginatedMovies?> getCachedPage(String key) async {
    final db = await _database;

    final rows = await db.query(
      'cached_pages',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final jsonString = rows.first['json'] as String;
    final decoded =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return _paginatedMoviesFromJson(decoded);
  }
}

/// ------------
/// Helpers JSON
/// ------------
Map<String, dynamic> _movieToJson(Movie movie) => {
      'id': movie.id,
      'title': movie.title,
      'overview': movie.overview,
      'posterPath': movie.posterPath,
      'backdropPath': movie.backdropPath,
      'voteAverage': movie.voteAverage,
      'releaseDate': movie.releaseDate,
    };

Movie _movieFromJson(Map<String, dynamic> json) => Movie(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      overview: json['overview'] as String?,
      posterPath: json['posterPath'] as String?,
      backdropPath: json['backdropPath'] as String?,
      voteAverage:
          (json['voteAverage'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['releaseDate'] as String?,
    );

Map<String, dynamic> _paginatedMoviesToJson(
        PaginatedMovies page) =>
    {
      'page': page.page,
      'total_pages': page.totalPages,
      'total_results': page.totalResults,
      'results':
          page.results.map(_movieToJson).toList(growable: false),
    };

PaginatedMovies _paginatedMoviesFromJson(
    Map<String, dynamic> json) {
  final resultsRaw =
      json['results'] as List<dynamic>? ?? const [];
  final movies = resultsRaw
      .whereType<Map<String, dynamic>>()
      .map(_movieFromJson)
      .toList();

  return PaginatedMovies(
    page: (json['page'] as num?)?.toInt() ?? 1,
    totalPages:
        (json['total_pages'] as num?)?.toInt() ?? 1,
    totalResults:
        (json['total_results'] as num?)?.toInt() ??
            movies.length,
    results: movies,
  );
}
