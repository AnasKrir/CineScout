import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../domain/entities/movie.dart';
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_event.dart';
import '../bloc/watchlist_state.dart';
import 'movie_details_page.dart';
import '/core/language/language_cubit.dart'; // ✅ langue

class WatchlistPage extends StatelessWidget {
  const WatchlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Bloc global fourni dans main.dart
    return const _WatchlistView();
  }
}

class _WatchlistView extends StatelessWidget {
  const _WatchlistView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist'),
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            context.read<WatchlistBloc>().add(const WatchlistRefreshed()),
        child: BlocBuilder<WatchlistBloc, WatchlistState>(
          builder: (context, state) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildBodyForState(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBodyForState(BuildContext context, WatchlistState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final isFr = context.watch<LanguageCubit>().state.isFrench; // ✅

    if (state is WatchlistInitial || state is WatchlistLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    } else if (state is WatchlistError) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.message,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context
                    .read<WatchlistBloc>()
                    .add(const WatchlistStarted()),
                child: Text(isFr ? 'Réessayer' : 'Retry'), // (optionnel) ✅
              ),
            ],
          ),
        ),
      );
    } else if (state is WatchlistEmpty) {
      final emptyText = isFr
          ? 'Votre watchlist est vide.\nAjoutez des films depuis la page de détails.'
          : 'Your watchlist is empty.\nAdd movies from the details page.'; // ✅

      return Center(
        key: const ValueKey('empty'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      );
    } else if (state is WatchlistLoaded) {
      final movies = state.movies;

      return LayoutBuilder(
        key: const ValueKey('grid'),
        builder: (context, constraints) {
          // 🔹 Même logique de colonnes que Discover/Search
          final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);

          return GridView.builder(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65, // 🔹 même ratio que Discover/Search
            ),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return _WatchlistMovieCard(movie: movie);
            },
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}

class _WatchlistMovieCard extends StatelessWidget {
  const _WatchlistMovieCard({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseImageUrl =
        dotenv.env['TMDB_IMAGE_BASE_URL'] ??
            'https://image.tmdb.org/t/p';
    final posterPath = movie.posterPath;
    final posterUrl =
        posterPath != null ? '$baseImageUrl/w500$posterPath' : null;

    final heroTag = 'watchlist_${movie.id}';

    final isFr = context.watch<LanguageCubit>().state.isFrench; // (pour le tooltip)

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MovieDetailsPage(
              movieId: movie.id,
              initialMovie: movie,
              heroTag: heroTag,
            ),
          ),
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
            // 🔹 Poster plein
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: posterUrl != null
                    ? Hero(
                        tag: heroTag,
                        child: CachedNetworkImage(
                          imageUrl: posterUrl,
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
                        alignment: Alignment.center,
                        child: const Icon(Icons.movie_outlined),
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.only(left: 8, right: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Colors.amber.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    movie.voteAverage.toStringAsFixed(1),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      context
                          .read<WatchlistBloc>()
                          .add(WatchlistItemRemoved(movie.id));
                    },
                    icon: const Icon(
                      Icons.bookmark_remove_outlined,
                      size: 18,
                    ),
                    tooltip: isFr
                        ? 'Retirer de la watchlist'
                        : 'Remove from watchlist', // ✅
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
