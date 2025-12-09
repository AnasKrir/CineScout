enum MoviesListCategory {
  popular,
  trending,
}

extension MoviesListCategoryX on MoviesListCategory {
  String get label {
    switch (this) {
      case MoviesListCategory.popular:
        return 'Populaires';
      case MoviesListCategory.trending:
        return 'Tendance';
    }
  }
}