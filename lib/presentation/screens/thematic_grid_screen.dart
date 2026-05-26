import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../data/models/tmdb_models.dart';
import '../../data/models/iptv_models.dart';
import '../widgets/movie_detail_sheet.dart';
import '../widgets/series_detail_sheet.dart';
import 'player_screen.dart';

enum ThematicGridType { live, movie, series, mixed }

class ThematicGridScreen extends StatelessWidget {
  final String title;
  final Color themeColor;
  final ThematicGridType type;
  final List<dynamic> items;

  const ThematicGridScreen({
    super.key,
    required this.title,
    required this.themeColor,
    required this.type,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(title, style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: themeColor),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 2.5,
            colors: [
              themeColor.withValues(alpha: 0.3),
              Colors.black87,
              Colors.black,
            ],
          ),
        ),
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 120,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            if (type == ThematicGridType.live) {
              return _buildLiveCard(context, item as IptvLiveChannel);
            } else if (type == ThematicGridType.movie || (type == ThematicGridType.mixed && item is MatchedMovie)) {
              return _buildMovieCard(context, item as MatchedMovie);
            } else {
              return _buildSeriesCard(context, item as MatchedSeries);
            }
          },
        ),
      ),
    );
  }

  Widget _buildLiveCard(BuildContext context, IptvLiveChannel channel) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              mediaId: channel.streamId,
              mediaName: channel.name,
              mediaType: 'live',
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: themeColor.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: channel.icon != null && channel.icon!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: channel.icon!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(child: CircularProgressIndicator(color: themeColor)),
                        errorWidget: (context, url, error) => Icon(Icons.live_tv_rounded, color: themeColor, size: 40),
                      )
                    : Icon(Icons.live_tv_rounded, color: themeColor, size: 40),
              ),
            ),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Text(
                channel.name,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMovieCard(BuildContext context, MatchedMovie matched) {
    final tmdb = matched.tmdbMovie;
    return GestureDetector(
      onTap: () => showMovieDetailSheet(
        context,
        mediaId: matched.streamId,
        name: tmdb.title,
        posterUrl: tmdb.posterUrl,
        description: tmdb.overview,
        year: tmdb.releaseDate.length >= 4 ? tmdb.releaseDate.substring(0, 4) : null,
        rating: tmdb.voteAverage.toStringAsFixed(1),
      ),
      child: _buildPoster(tmdb.title, tmdb.posterUrl, tmdb.voteAverage),
    );
  }

  Widget _buildSeriesCard(BuildContext context, MatchedSeries matched) {
    final tmdb = matched.tmdbSeries;
    return GestureDetector(
      onTap: () {
        showSeriesDetailSheet(
          context,
          seriesId: matched.seriesId,
          name: tmdb.name,
          posterUrl: tmdb.posterUrl,
          description: tmdb.overview,
          rating: tmdb.voteAverage.toStringAsFixed(1),
          year: tmdb.firstAirDate.length >= 4 ? tmdb.firstAirDate.substring(0, 4) : null,
        );
      },
      child: _buildPoster(tmdb.name, tmdb.posterUrl, tmdb.voteAverage),
    );
  }

  Widget _buildPoster(String title, String posterUrl, double voteAverage) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: themeColor.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
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
                    placeholder: (_, __) => Center(child: CircularProgressIndicator(color: themeColor)),
                    errorWidget: (_, __, ___) => Icon(Icons.movie_rounded, color: themeColor, size: 40),
                  )
                : Icon(Icons.movie_rounded, color: themeColor, size: 40),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 10),
                    const SizedBox(width: 4),
                    Text(voteAverage.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
