import 'package:equatable/equatable.dart';

import '../../domain/entities/movie.dart';
import '../../domain/entities/cast_member.dart';
import '../../domain/entities/video.dart';

abstract class MovieDetailsState extends Equatable {
  const MovieDetailsState();

  @override
  List<Object?> get props => [];
}

class MovieDetailsInitial extends MovieDetailsState {
  const MovieDetailsInitial();
}

class MovieDetailsLoading extends MovieDetailsState {
  const MovieDetailsLoading();
}

class MovieDetailsLoaded extends MovieDetailsState {
  const MovieDetailsLoaded({
    required this.movie,
    required this.cast,
    required this.videos,
    this.isInWatchlist = false,
    this.hasCastError = false,
    this.hasVideosError = false,
  });

  final Movie movie;
  final List<CastMember> cast;
  final List<Video> videos;
  final bool isInWatchlist;
  final bool hasCastError;
  final bool hasVideosError;

  MovieDetailsLoaded copyWith({
    Movie? movie,
    List<CastMember>? cast,
    List<Video>? videos,
    bool? isInWatchlist,
    bool? hasCastError,
    bool? hasVideosError,
  }) {
    return MovieDetailsLoaded(
      movie: movie ?? this.movie,
      cast: cast ?? this.cast,
      videos: videos ?? this.videos,
      isInWatchlist: isInWatchlist ?? this.isInWatchlist,
      hasCastError: hasCastError ?? this.hasCastError,
      hasVideosError: hasVideosError ?? this.hasVideosError,
    );
  }

  @override
  List<Object?> get props => [
        movie,
        cast,
        videos,
        isInWatchlist,
        hasCastError,
        hasVideosError,
      ];
}

class MovieDetailsError extends MovieDetailsState {
  const MovieDetailsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
