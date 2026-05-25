import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../data/models/iptv_models.dart';
import '../../data/models/tmdb_models.dart';
import '../controllers/iptv_controller.dart';
import '../controllers/providers.dart';
import '../controllers/sports_provider.dart';
import '../controllers/vod_matcher_provider.dart';
import '../controllers/language_provider.dart';
import '../widgets/glass_container.dart';
import 'player_screen.dart';
import '../widgets/movie_detail_sheet.dart';

class SportsDashboardScreen extends ConsumerStatefulWidget {
  const SportsDashboardScreen({super.key});

  @override
  ConsumerState<SportsDashboardScreen> createState() => _SportsDashboardScreenState();
}

class _SportsDashboardScreenState extends ConsumerState<SportsDashboardScreen> {

  @override
  Widget build(BuildContext context) {
    final liveChannels = ref.watch(sportsLiveChannelsProvider);
    final movies = ref.watch(sportsMoviesProvider);
    final series = ref.watch(sportsSeriesProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Dark theme like horror room
      body: Stack(
        children: [
          // Background Gradient (Green/Black)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 2.5,
                colors: [
                  AppColors.success.withOpacity(0.3),
                  Colors.black,
                  Colors.black,
                ],
              ),
            ),
          ),
          
          CustomScrollView(
            slivers: [
              // Custom App Bar
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                centerTitle: true,
                title: Text(
                  ref.tr('home_sports_center'),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: [Shadow(color: AppColors.success, blurRadius: 10)],
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Canlı Yayınlar', Icons.stream_rounded, AppColors.success),
                      _buildLiveChannelsRow(liveChannels),

                      const SizedBox(height: 30),
                      _buildSectionTitle('Belgeseller', Icons.camera_roll_rounded, AppColors.warning),
                      ref.watch(sportsMatchedDocumentariesProvider).when(
                        data: (items) => _buildMatchedDynamicRow(items),
                        loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.warning))),
                        error: (err, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Hata: $err', style: const TextStyle(color: Colors.white))),
                      ),

                      const SizedBox(height: 30),
                      _buildSectionTitle(ref.tr('sports_vod_movies'), Icons.movie_creation_rounded, AppColors.accent),
                      ref.watch(sportsMatchedOnlyMoviesProvider).when(
                        data: (items) => _buildMatchedVodRow(items),
                        loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.accent))),
                        error: (err, _) => Padding(padding: const EdgeInsets.all(20), child: Text('Hata: $err', style: const TextStyle(color: Colors.white))),
                      ),

                      const SizedBox(height: 30),
                      _buildSectionTitle('Diziler', Icons.video_library_rounded, Color(0xFFFF4081)),
                      ref.watch(sportsMatchedOnlySeriesProvider).when(
                        data: (items) => _buildMatchedSeriesRow(items),
                        loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFFFF4081)))),
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

  Widget _buildSectionTitle(String title, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveChannelsRow(List<IptvLiveChannel> channels) {
    if (channels.isEmpty) {
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
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    mediaId: channel.streamId,
                    mediaName: channel.displayName,
                    mediaType: 'live',
                  ),
                ),
              );
            },
            child: Container(
              width: 120,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
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
                              errorWidget: (_, __, ___) => _buildFallbackLogo(channel.displayName),
                            )
                          : _buildFallbackLogo(channel.displayName),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                    ),
                    child: Text(
                      channel.displayName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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

  Widget _buildMatchedVodRow(List<MatchedMovie> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(ref.tr('sports_vod_not_found'), style: const TextStyle(color: AppColors.textSecondary)),
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

          return GestureDetector(
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
            child: _buildVodCard(tmdb.title, tmdb.posterUrl, tmdb.voteAverage),
          );
        },
      ),
    );
  }

  Widget _buildMatchedSeriesRow(List<MatchedSeries> items) {
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

          return GestureDetector(
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
            child: _buildVodCard(tmdb.name, tmdb.posterUrl, tmdb.voteAverage),
          );
        },
      ),
    );
  }

  Widget _buildMatchedDynamicRow(List<dynamic> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(ref.tr('doc_not_found'), style: const TextStyle(color: AppColors.textSecondary)),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          
          if (item is MatchedMovie) {
            final tmdb = item.tmdbMovie;
            return GestureDetector(
              onTap: () {
                showMovieDetailSheet(
                  context,
                  mediaId: item.streamId,
                  name: tmdb.title,
                  posterUrl: tmdb.posterUrl,
                  description: tmdb.overview,
                  year: tmdb.releaseDate.length >= 4 ? tmdb.releaseDate.substring(0, 4) : null,
                  rating: tmdb.voteAverage.toStringAsFixed(1),
                );
              },
              child: _buildVodCard(tmdb.title, tmdb.posterUrl, tmdb.voteAverage),
            );
          } else if (item is MatchedSeries) {
            final tmdb = item.tmdbSeries;
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerScreen(
                      mediaId: item.seriesId,
                      mediaName: tmdb.name,
                      mediaType: 'series',
                    ),
                  ),
                );
              },
              child: _buildVodCard(tmdb.name, tmdb.posterUrl, tmdb.voteAverage),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildVodCard(String title, String posterUrl, double voteAverage) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
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
                    errorWidget: (_, __, ___) => _buildFallbackLogo(title),
                  )
                : _buildFallbackLogo(title),
            
            // Gradient and Title
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
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
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
    );
  }

  Widget _buildFallbackLogo(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
