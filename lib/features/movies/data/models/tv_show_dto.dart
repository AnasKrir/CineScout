import '../../domain/entities/tv_show.dart';

class TvShowDto {
  final int id;
  final String name;
  final String? overview;
  final String? posterPath;
  final String? backdropPath;
  final double voteAverage;
  final String? firstAirDate;

  const TvShowDto({
    required this.id,
    required this.name,
    this.overview,
    this.posterPath,
    this.backdropPath,
    required this.voteAverage,
    this.firstAirDate,
  });

  factory TvShowDto.fromJson(Map<String, dynamic> json) {
    final vote = json['vote_average'];
    double voteAverage = 0;
    if (vote is num) {
      voteAverage = vote.toDouble();
    }

    return TvShowDto(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      overview: json['overview'] as String?,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
      voteAverage: voteAverage,
      firstAirDate: json['first_air_date'] as String?,
    );
  }

  TvShow toDomain() => TvShow(
        id: id,
        name: name,
        overview: overview,
        posterPath: posterPath,
        backdropPath: backdropPath,
        voteAverage: voteAverage,
        firstAirDate: firstAirDate,
      );
}
