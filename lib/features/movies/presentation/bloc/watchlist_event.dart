import 'package:equatable/equatable.dart';

abstract class WatchlistEvent extends Equatable {
  const WatchlistEvent();

  @override
  List<Object?> get props => [];
}

class WatchlistStarted extends WatchlistEvent {
  const WatchlistStarted();
}

class WatchlistRefreshed extends WatchlistEvent {
  const WatchlistRefreshed();
}

class WatchlistItemRemoved extends WatchlistEvent {
  const WatchlistItemRemoved(this.movieId);

  final int movieId;

  @override
  List<Object?> get props => [movieId];
}
