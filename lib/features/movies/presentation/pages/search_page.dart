import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/movie.dart';
import '../../domain/repositories/movies_repository.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '/core/language/language_cubit.dart'; // ✅ langue

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final moviesRepository = context.read<MoviesRepository>();

    return BlocProvider<SearchBloc>(
      create: (_) => SearchBloc(moviesRepository: moviesRepository),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    const threshold = 0.8;

    if (position.pixels >= position.maxScrollExtent * threshold) {
      context.read<SearchBloc>().add(const SearchLoadMore());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    context.read<SearchBloc>().add(SearchQueryChanged(value));
  }

  void _onSubmitted(String value) {
    context.read<SearchBloc>().add(SearchSubmitted(value));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFr = context.watch<LanguageCubit>().state.isFrench; // ✅

    final hintText =
        isFr ? 'Rechercher un film...' : 'Search for a movie...'; // ✅

    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              onChanged: _onQueryChanged,
              onSubmitted: _onSubmitted,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration( // 🔁 plus "const" pour pouvoir changer le texte
                border: InputBorder.none,
                hintText: hintText, // ✅ FR / EN
                icon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchInitial) {
                return const _SearchIdleView();
              } else if (state is SearchLoading) {
                return _SearchGridSkeleton(controller: _scrollController);
              } else if (state is SearchEmpty) {
                return _SearchEmptyView(query: state.query);
              } else if (state is SearchError) {
                return _SearchErrorView(message: state.message);
              } else if (state is SearchLoaded) {
                return _SearchResultsGrid(
                  results: state.results,
                  isLoadingMore: state.isLoadingMore,
                  hasMore: state.hasMore,
                  controller: _scrollController,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _SearchIdleView extends StatelessWidget {
  const _SearchIdleView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFr = context.watch<LanguageCubit>().state.isFrench; // ✅

    final text = isFr
        ? 'Commence à taper pour rechercher un film.'
        : 'Start typing to search for a movie.'; // ✅

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_rounded,
            size: 48,
            color: colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyView extends StatelessWidget {
  const _SearchEmptyView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFr = context.watch<LanguageCubit>().state.isFrench; // ✅

    final text = isFr
        ? 'Aucun résultat trouvé pour « $query ».'
        : 'No results found for “$query”.'; // ✅

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _SearchErrorView extends StatelessWidget {
  const _SearchErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _SearchGridSkeleton extends StatelessWidget {
  const _SearchGridSkeleton({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        return GridView.builder(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: crossAxisCount * 4,
          itemBuilder: (context, index) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.35),
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchResultsGrid extends StatelessWidget {
  const _SearchResultsGrid({
    required this.results,
    required this.isLoadingMore,
    required this.hasMore,
    required this.controller,
  });

  final List<Movie> results;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final baseImageUrl =
        dotenv.env['TMDB_IMAGE_BASE_URL'] ?? 'https://image.tmdb.org/t/p';
    final isFr = context.watch<LanguageCubit>().state.isFrench; // ✅

    final endText =
        isFr ? 'Fin des résultats' : 'No more results'; // ✅

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

        return CustomScrollView(
          controller: controller,
          slivers: [
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final movie = results[index];
                    final heroTag = 'search_movie_${movie.id}';

                    final posterUrl = movie.posterPath != null
                        ? '$baseImageUrl/w500${movie.posterPath}'
                        : null;

                    return _SearchMovieCard(
                      movie: movie,
                      posterUrl: posterUrl,
                      heroTag: heroTag,
                    );
                  },
                  childCount: results.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: isLoadingMore
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (!hasMore
                          ? Text(
                              endText, // ✅ FR / EN
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            )
                          : const SizedBox.shrink()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchMovieCard extends StatelessWidget {
  const _SearchMovieCard({
    required this.movie,
    required this.posterUrl,
    required this.heroTag,
  });

  final Movie movie;
  final String? posterUrl;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        context.push(
          '/movie/${movie.id}',
          extra: {
            'movie': movie,
            'heroTag': heroTag,
          },
        );
      },
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: posterUrl != null
                    ? Hero(
                        tag: heroTag,
                        child: CachedNetworkImage(
                          imageUrl: posterUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: colorScheme.surfaceVariant
                                .withOpacity(0.3),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceVariant
                                .withOpacity(0.3),
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      )
                    : Container(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        child: const Center(
                          child: Icon(Icons.movie),
                        ),
                      ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Colors.amber.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    movie.voteAverage.toStringAsFixed(1),
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _getCrossAxisCount(double maxWidth) {
  if (maxWidth >= 1000) return 5;
  if (maxWidth >= 700) return 4;
  if (maxWidth >= 500) return 3;
  return 2;
}
