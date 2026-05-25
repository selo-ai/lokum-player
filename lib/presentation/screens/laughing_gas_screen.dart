import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../data/models/tmdb_models.dart';
import '../widgets/movie_detail_sheet.dart';
import '../../data/models/iptv_models.dart';
import '../controllers/vod_matcher_provider.dart';
import '../controllers/language_provider.dart';
import 'player_screen.dart';

class LaughingGasScreen extends ConsumerWidget {
  const LaughingGasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark theme base
      body: Stack(
        children: [
          // Background Gradient (Amber/Black for comedy)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 2.5,
                colors: [
                  Colors.amber.withValues(alpha: 0.3),
                  Colors.black,
                  Colors.black,
                ],
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                centerTitle: true,
                title: Text(
                  ref.tr('home_laughing_gas'),
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: [Shadow(color: Colors.amber, blurRadius: 10)],
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(ref.tr('comedy_channels'), Icons.emoji_emotions_rounded),
                      _buildLiveChannelsRow(ref.watch(comedyChannelsProvider), context, ref),

                      const SizedBox(height: 40),

                      _buildSectionTitle(ref.tr('comedy_movies'), Icons.theater_comedy_rounded),
                      ref.watch(comedyMoviesProvider).when(
                        data: (matchedMovies) => _buildMatchedMovieRow(matchedMovies, context, ref),
                        loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: Colors.orangeAccent))),
                        error: (err, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Hata: $err', style: const TextStyle(color: Colors.white))),
                      ),

                      const SizedBox(height: 40),
                      
                      _buildSectionTitle(ref.tr('comedy_series'), Icons.mood_rounded),
                      ref.watch(comedySeriesProvider).when(
                        data: (matchedSeries) => _buildMatchedSeriesRow(matchedSeries, context, ref),
                        loading: () => const SizedBox(height: 220, child: Center(child: CircularProgressIndicator(color: Colors.amberAccent))),
                        error: (err, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Hata: $err', style: const TextStyle(color: Colors.white))),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.amberAccent, size: 24),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChannelsRow(List<IptvLiveChannel> items, BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(ref.tr('channel_not_found'), style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final channel = items[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(mediaId: channel.streamId, mediaName: channel.name, mediaType: 'live')));
            },
            child: Container(
              width: 140,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: channel.icon != null && channel.icon!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: channel.icon!,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Center(child: Icon(Icons.tv, color: Colors.white54, size: 40)),
                            )
                          : const Center(child: Icon(Icons.tv, color: Colors.white54, size: 40)),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(11), bottomRight: Radius.circular(11)),
                    ),
                    child: Text(
                      channel.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchedMovieRow(List<MatchedMovie> items, BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(ref.tr('movie_not_found'), style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final matched = items[index];
          final tmdb = matched.tmdbMovie;

          return _buildPosterCard(
            context: context,
            title: tmdb.title,
            posterUrl: tmdb.posterUrl,
            voteAverage: tmdb.voteAverage,
            onTap: () {
              showMovieDetailSheet(
                context,
                mediaId: matched.streamId,
                name: tmdb.title,
                posterUrl: tmdb.posterUrl,
                description: tmdb.overview,
                year: tmdb.releaseDate.length >= 4 ? tmdb.releaseDate.substring(0, 4) : null,
                rating: tmdb.voteAverage.toStringAsFixed(1),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchedSeriesRow(List<MatchedSeries> items, BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(ref.tr('series_not_found'), style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final matched = items[index];
          final tmdb = matched.tmdbSeries;

          return _buildPosterCard(
            context: context,
            title: tmdb.name,
            posterUrl: tmdb.posterUrl,
            voteAverage: tmdb.voteAverage,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    mediaId: matched.seriesId,
                    mediaName: tmdb.name,
                    mediaType: 'series',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPosterCard({
    required BuildContext context,
    required String title,
    required String posterUrl,
    required double voteAverage,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              posterUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(color: Colors.black26),
                    )
                  : Container(color: Colors.black26),
              
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            voteAverage.toStringAsFixed(1),
                            style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
