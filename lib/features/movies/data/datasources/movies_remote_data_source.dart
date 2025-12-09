import 'package:dio/dio.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/tmdb_client.dart';
import '../models/movie_dto.dart';
import '../models/cast_member_dto.dart';
import '../models/video_dto.dart';
import '../models/paginated_response_dto.dart';

class MoviesRemoteDataSource {
  MoviesRemoteDataSource({required TmdbClient client}) : _client = client;

  final TmdbClient _client;

  Future<PaginatedResponseDto<MovieDto>> getPopularMovies({int page = 1}) async {
    try {
      final response = await _client.dio.get(
        '/movie/popular',
        queryParameters: {'page': page},
      );
      return PaginatedResponseDto<MovieDto>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MovieDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<PaginatedResponseDto<MovieDto>> getTrendingMovies({int page = 1}) async {
    try {
      final response = await _client.dio.get(
        '/trending/movie/week',
        queryParameters: {'page': page},
      );
      return PaginatedResponseDto<MovieDto>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MovieDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<PaginatedResponseDto<MovieDto>> searchMovies({
    required String query,
    int page = 1,
  }) async {
    try {
      final response = await _client.dio.get(
        '/search/movie',
        queryParameters: {
          'query': query,
          'page': page,
          'include_adult': false,
        },
      );
      return PaginatedResponseDto<MovieDto>.fromJson(
        response.data as Map<String, dynamic>,
        (json) => MovieDto.fromJson(json),
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<MovieDto> getMovieDetails(
              int id, {
              String? languageCode,
            }) async {
              try {
                final response = await _client.dio.get(
                  '/movie/$id',
                  queryParameters: languageCode != null
                      ? {'language': languageCode}
                      : null, // si null → laisse la langue par défaut (env)
                );

                return MovieDto.fromJson(response.data as Map<String, dynamic>);
              } on DioException catch (e) {
                throw mapDioException(e);
              }
            }


  Future<List<CastMemberDto>> getMovieCredits(int id) async {
    try {
      final response = await _client.dio.get('/movie/$id/credits');
      final castList = (response.data['cast'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CastMemberDto.fromJson)
          .toList();
      return castList;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  Future<List<VideoDto>> getMovieVideos(int id) async {
    try {
      final response = await _client.dio.get('/movie/$id/videos');
      final videos = (response.data['results'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(VideoDto.fromJson)
          .toList();
      return videos;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
