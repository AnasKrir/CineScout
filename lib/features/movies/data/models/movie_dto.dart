import '../../domain/entities/movie.dart';

class MovieDto {
  final int id;
  final String title;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? releaseDate;

  const MovieDto({
    required this.id,
    required this.title,
    this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.releaseDate,
  });

  factory MovieDto.fromJson(Map<String, dynamic> json) {
    final vote = json['vote_average'];
    double voteAverage = 0;
    if (vote is num) {
      voteAverage = vote.toDouble();
    }

    return MovieDto(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? json['name'] ?? '') as String,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: voteAverage,
      releaseDate:
          (json['release_date'] ?? json['first_air_date']) as String?,
    );
  }

  Movie toDomain() => Movie(
        id: id,
        title: title,
        overview: overview,
        posterPath: posterPath,
        backdropPath: backdropPath,
        voteAverage: voteAverage,
        releaseDate: releaseDate,
      );
}