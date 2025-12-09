class PaginatedResponseDto<T> {
  final int page;
  final List<T> results;
  final int totalPages;
  final int totalResults;

  const PaginatedResponseDto({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory PaginatedResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    final rawResults = (json['results'] as List<dynamic>? ?? []);
    final items = rawResults
        .whereType<Map<String, dynamic>>()
        .map(fromItem)
        .toList();

    return PaginatedResponseDto<T>(
      page: (json['page'] as num?)?.toInt() ?? 1,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      totalResults: (json['total_results'] as num?)?.toInt() ?? items.length,
      results: items,
    );
  }
}
