import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/movie.dart';
import '../../domain/entities/cast_member.dart';
import '../../domain/entities/video.dart';
import '../../domain/repositories/movies_repository.dart';
import '../bloc/movie_details_bloc.dart';
import '../bloc/movie_details_event.dart';
import '../bloc/movie_details_state.dart';
import '/core/language/language_cubit.dart';

// 🔹 Pour rafraîchir la Watchlist après un toggle
import '../bloc/watchlist_bloc.dart';
import '../bloc/watchlist_event.dart';

class MovieDetailsPage extends StatelessWidget {
  const MovieDetailsPage({
    super.key,
    required this.movieId,
    this.initialMovie,
    this.heroTag,
  });

  final int movieId;
  final Movie? initialMovie;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MovieDetailsBloc(
        moviesRepository: context.read<MoviesRepository>(),
        languageCubit: context.read<LanguageCubit>(), // ✅ nouveau
      )..add(MovieDetailsRequested(movieId)),
      child: BlocListener<LanguageCubit, AppLanguage>(
        listener: (context, state) {
          // 🔁 Quand on change FR/EN → on recharge les détails
          context
              .read<MovieDetailsBloc>()
              .add(MovieDetailsRequested(movieId));
        },
        child: _MovieDetailsView(
          movieId: movieId,
          initialMovie: initialMovie,
          heroTag: heroTag,
        ),
      ),
    );
  }
}


class _MovieDetailsView extends StatelessWidget {
  const _MovieDetailsView({
    required this.movieId,
    required this.initialMovie,
    required this.heroTag,
  });

  final int movieId;
  final Movie? initialMovie;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseImageUrl =
        dotenv.env['TMDB_IMAGE_BASE_URL'] ?? 'https://image.tmdb.org/t/p';

    // 🔹 Langue actuelle (FR / EN)
    final isEnglish =
        context.watch<LanguageCubit>().state == AppLanguage.en;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
          builder: (context, state) {
            final movie =
                state is MovieDetailsLoaded ? state.movie : initialMovie;
            return Text(movie?.title ?? 'Film #$movieId');
          },
        ),
      ),
      body: BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
        builder: (context, state) {
          final Movie? movie =
              state is MovieDetailsLoaded ? state.movie : initialMovie;

          final posterPath = movie?.posterPath;
          final posterUrl =
              posterPath != null ? '$baseImageUrl/w500$posterPath' : null;

          // 🔹 Texte du synopsis (adapté à la langue)
          String synopsisText;
          if (movie != null && (movie.overview?.isNotEmpty ?? false)) {
            synopsisText = movie.overview!;
          } else if (state is MovieDetailsLoading) {
            synopsisText = isEnglish
                ? 'Loading synopsis…'
                : 'Chargement du synopsis…';
          } else {
            synopsisText = isEnglish
                ? 'No synopsis available for this movie.'
                : 'Aucun synopsis disponible pour ce film.';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (posterUrl != null)
                  Center(
                    child: Hero(
                      tag: heroTag ?? 'movie_$movieId',
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: posterUrl,
                          height: 280,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 280,
                            width: 190,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 280,
                            width: 190,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                if (movie != null)
                  Text(
                    movie.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                if (movie != null) const SizedBox(height: 8),

                if (movie != null)
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        movie.voteAverage?.toStringAsFixed(1) ?? '–',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (movie.releaseDate != null)
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              movie.releaseDate!,
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                const SizedBox(height: 16),

                // 🔹 Bouton Watchlist + Bande-annonce (labels FR/EN)
                BlocBuilder<MovieDetailsBloc, MovieDetailsState>(
                  builder: (context, state) {
                    final bool isInWatchlist = state is MovieDetailsLoaded
                        ? state.isInWatchlist
                        : false;
                    final List<Video> videos = state is MovieDetailsLoaded
                        ? state.videos
                        : const [];

                    final Video? trailer = videos.isNotEmpty
                        ? videos.firstWhere(
                            (v) =>
                                (v.site?.toLowerCase() == 'youtube') &&
                                (v.type?.toLowerCase() == 'trailer' ||
                                    v.type?.toLowerCase() == 'teaser'),
                            orElse: () => videos.first,
                          )
                        : null;

                    final addToWatchlistLabel = isEnglish
                        ? 'Add to watchlist'
                        : 'Ajouter à la Watchlist';
                    final removeFromWatchlistLabel = isEnglish
                        ? 'Remove from watchlist'
                        : 'Retirer de la Watchlist';
                    final trailerLabel =
                        isEnglish ? 'Trailer' : 'Bande-annonce';

                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: state is MovieDetailsLoaded
                                ? () {
                                    // 1) Toggle en DB
                                    context
                                        .read<MovieDetailsBloc>()
                                        .add(const MovieDetailsWatchlistToggled());

                                    // 2) 🔄 Rafraîchir la watchlist globale
                                    context
                                        .read<WatchlistBloc>()
                                        .add(const WatchlistRefreshed());
                                  }
                                : null,
                            icon: Icon(
                              isInWatchlist
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                            ),
                            label: Text(
                              isInWatchlist
                                  ? removeFromWatchlistLabel
                                  : addToWatchlistLabel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (trailer != null)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openTrailer(context, trailer),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text(trailerLabel),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 🔹 Titre "Synopsis" / "Overview"
                Text(
                  isEnglish ? 'Overview' : 'Synopsis',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  synopsisText,
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.9),
                  ),
                ),

                const SizedBox(height: 24),

                // 🔹 Casting + gestion des erreurs globales (VERSION COMPLÈTE)
                if (state is MovieDetailsLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (state is MovieDetailsError)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnglish ? 'Error' : 'Erreur',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.message,
                        style: TextStyle(
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          context
                              .read<MovieDetailsBloc>()
                              .add(const MovieDetailsRetryRequested());
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          isEnglish ? 'Retry' : 'Réessayer',
                        ),
                      ),
                    ],
                  )
                else if (state is MovieDetailsLoaded)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 "Casting" / "Cast"
                      Text(
                        isEnglish ? 'Cast' : 'Casting',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      if (state.cast.isEmpty && state.hasCastError)
                        Text(
                          isEnglish
                              ? 'Unable to load cast.'
                              : 'Impossible de charger le casting.',
                          style: TextStyle(
                            color: colorScheme.error,
                          ),
                        )
                      else if (state.cast.isEmpty)
                        Text(
                          isEnglish
                              ? 'No cast found for this movie.'
                              : 'Aucun acteur trouvé pour ce film.',
                          style: TextStyle(
                            color:
                                colorScheme.onSurface.withOpacity(0.8),
                          ),
                        )
                      else
                        SizedBox(
                          height: 180,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.cast.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final CastMember member = state.cast[index];
                              final profilePath = member.profilePath;
                              final profileUrl = profilePath != null
                                  ? '$baseImageUrl/w185$profilePath'
                                  : null;

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: profileUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: profileUrl,
                                            width: 72,
                                            height: 72,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              width: 72,
                                              height: 72,
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .surfaceVariant
                                                    .withOpacity(0.4),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              width: 72,
                                              height: 72,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .surfaceVariant
                                                    .withOpacity(0.4),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.person_outline,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 72,
                                            height: 72,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .surfaceVariant
                                                  .withOpacity(0.4),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.person_outline,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      member.name ?? 'Inconnu',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  if (member.character != null) ...[
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        member.character!,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.7),
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      if (state.hasVideosError) ...[
                        const SizedBox(height: 16),
                        Text(
                          isEnglish
                              ? 'Unable to load related videos.'
                              : 'Impossible de charger les vidéos associées.',
                          style: TextStyle(
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> _openTrailer(BuildContext context, Video video) async {
  final uri =
      Uri.parse('https://www.youtube.com/watch?v=${video.key ?? ''}');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    // 🔹 On récupère la langue pour le message d’erreur
    final isEnglish =
        context.read<LanguageCubit>().state == AppLanguage.en;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEnglish
              ? 'Unable to open trailer.'
              : 'Impossible d’ouvrir la bande-annonce.',
        ),
      ),
    );
  }
}
