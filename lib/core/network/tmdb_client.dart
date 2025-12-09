// lib/core/network/tmdb_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TmdbClient {
  TmdbClient()
      : dio = Dio(
          BaseOptions(
            baseUrl:
                dotenv.env['TMDB_BASE_URL'] ?? 'https://api.themoviedb.org/3',
            queryParameters: {
              'api_key': dotenv.env['TMDB_API_KEY'],
              'language': dotenv.env['TMDB_LANGUAGE'] ?? 'fr-FR',
            },
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );

  /// Utilisé par MoviesRemoteDataSource via `_client.dio`
  final Dio dio;
}
