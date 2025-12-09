import 'package:equatable/equatable.dart';

abstract class MovieDetailsEvent extends Equatable {
  const MovieDetailsEvent();

  @override
  List<Object?> get props => [];
}

class MovieDetailsRequested extends MovieDetailsEvent {
  const MovieDetailsRequested(this.movieId);

  final int movieId;

  @override
  List<Object?> get props => [movieId];
}

class MovieDetailsRetryRequested extends MovieDetailsEvent {
  const MovieDetailsRetryRequested();
}

class MovieDetailsWatchlistToggled extends MovieDetailsEvent {
  const MovieDetailsWatchlistToggled();
}