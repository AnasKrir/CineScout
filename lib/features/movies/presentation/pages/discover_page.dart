import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/movie.dart';
import '../../domain/repositories/movies_repository.dart';
import '../bloc/movies_list_bloc.dart';
import '../bloc/movies_list_category.dart';
import '../bloc/movies_list_event.dart';
import '../bloc/movies_list_state.dart';
import '/core/language/language_cubit.dart';

class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final moviesRepository = context.read<MoviesRepository>();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 8),
          BlocBuilder<LanguageCubit, AppLanguage>(
            builder: (context, lang) {
              final isEnglish = lang == AppLanguage.en;

              return TabBar(
                indicatorSize: TabBarIndicatorSize.label,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: isEnglish ? 'Popular' : 'Populaires'),
                  Tab(text: isEnglish ? 'Trending' : 'Tendance'),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              children: [
                // Onglet POPULAIRES
                BlocProvider(
                  create: (_) => MoviesListBloc(
                    moviesRepository: moviesRepository,
                    category: MoviesListCategory.popular,
                  )..add(const FetchFirstPage()),
                  child: const _MoviesListView(),
                ),

                // Onglet TENDANCE
                BlocProvider(
                  create: (_) => MoviesListBloc(
                    moviesRepository: moviesRepository,
                    category: MoviesListCategory.trending,
                  )..add(const FetchFirstPage()),
                  child: const _MoviesListView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vue générique qui lit simplement le MoviesListBloc fourni au-dessus
class _MoviesListView extends StatefulWidget {
  const _MoviesListView();

  @override
  State<_MoviesListView> createState() => _MoviesListViewState();
}

class _MoviesListViewState extends State<_MoviesListView> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    const threshold = 0.8;

    if (position.pixels >= position.maxScrollExtent * threshold) {
      // Ici, le context de _MoviesListView a bien un MoviesListBloc au-dessus
      context.read<MoviesListBloc>().add(const FetchNextPage());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<MoviesListBloc>().add(const RefreshMovies());
      },
      child: BlocBuilder<MoviesListBloc, MoviesListState>(
        builder: (context, state) {
          if (state is MoviesListInitial || state is MoviesListLoading) {
            return _MoviesGridSkeleton(controller: _scrollController);
          } else if (state is MoviesListError) {
            return _MoviesErrorView(
              message: state.message,
              onRetry: () {
                context.read<MoviesListBloc>().add(const FetchFirstPage());
              },
            );
          } else if (state is MoviesListLoaded) {
            return _MoviesGrid(
              movies: state.movies,
              isFetchingMore: state.isFetchingMore,
              hasMore: state.hasMore,
              controller: _scrollController,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MoviesGridSkeleton extends StatelessWidget {
  const _MoviesGridSkeleton({required this.controller});

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

class _MoviesGrid extends StatelessWidget {
  const _MoviesGrid({
    required this.movies,
    required this.isFetchingMore,
    required this.hasMore,
    required this.controller,
  });

  final List<Movie> movies;
  final bool isFetchingMore;
  final bool hasMore;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final baseImageUrl =
        dotenv.env['TMDB_IMAGE_BASE_URL'] ?? 'https://image.tmdb.org/t/p';

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
                    final movie = movies[index];
                    final heroTag = 'movie_${movie.id}';

                    final posterUrl = movie.posterPath != null
                        ? '$baseImageUrl/w500${movie.posterPath}'
                        : null;

                    return _MovieCard(
                      movie: movie,
                      posterUrl: posterUrl,
                      heroTag: heroTag,
                    );
                  },
                  childCount: movies.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: isFetchingMore
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : (!hasMore
                          ? Text(
                              'Fin de liste',
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

class _MovieCard extends StatelessWidget {
  const _MovieCard({
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

class _MoviesErrorView extends StatelessWidget {
  const _MoviesErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
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
