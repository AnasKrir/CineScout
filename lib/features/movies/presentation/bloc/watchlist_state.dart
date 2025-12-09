import 'package:equatable/equatable.dart';

import '../../domain/entities/movie.dart';

abstract class WatchlistState extends Equatable {
  const WatchlistState();

  @override
  List<Object?> get props => [];
}

class WatchlistInitial extends WatchlistState {
  const WatchlistInitial();
}

class WatchlistLoading extends WatchlistState {
  const WatchlistLoading();
}

class WatchlistLoaded extends WatchlistState {
  const WatchlistLoaded(this.movies);

  final List<Movie> movies;

  @override
  List<Object?> get props => [movies];
}

class WatchlistEmpty extends WatchlistState {
  const WatchlistEmpty();
}

class WatchlistError extends WatchlistState {
  const WatchlistError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
