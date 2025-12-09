import 'package:equatable/equatable.dart';

abstract class MoviesListEvent extends Equatable {
  const MoviesListEvent();

  @override
  List<Object?> get props => [];
}

class FetchFirstPage extends MoviesListEvent {
  const FetchFirstPage();
}

class FetchNextPage extends MoviesListEvent {
  const FetchNextPage();
}

class RefreshMovies extends MoviesListEvent {
  const RefreshMovies();
}