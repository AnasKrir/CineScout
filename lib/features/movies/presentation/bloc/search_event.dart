import 'package:equatable/equatable.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Saisie dans le champ de recherche
class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Touche "search" du clavier / bouton "Rechercher"
class SearchSubmitted extends SearchEvent {
  const SearchSubmitted(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Chargement de la page suivante (scroll infini)
class SearchLoadMore extends SearchEvent {
  const SearchLoadMore();
}
