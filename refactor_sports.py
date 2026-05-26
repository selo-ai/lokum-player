import os
import re

path = 'lib/presentation/screens/sports_dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import
if "import 'thematic_grid_screen.dart';" not in content:
    content = content.replace("import 'player_screen.dart';", "import 'player_screen.dart';\nimport 'thematic_grid_screen.dart';")

# Update callers
content = content.replace("_buildLiveChannelsRow(liveChannels)", "_buildLiveChannelsRow('Canlı Yayınlar', liveChannels)")
content = content.replace("_buildMatchedDynamicRow(items)", "_buildMatchedDynamicRow('Belgeseller', items)")
content = content.replace("_buildMatchedVodRow(items)", "_buildMatchedVodRow(ref.tr('sports_vod_movies'), items)")
content = content.replace("_buildMatchedSeriesRow(items)", "_buildMatchedSeriesRow('Diziler', items)")

# Replace builders from `Widget _buildSectionTitle` to end of file (wait, `_buildSectionTitle` is used above).
# We will replace from `Widget _buildLiveChannelsRow` up to the end of the file.
start_idx = content.find("  Widget _buildLiveChannelsRow")
if start_idx != -1:
    NEW_METHODS = """  Widget _buildLiveChannelsRow(String title, List<IptvLiveChannel> items) {
    if (items.isEmpty) return Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('Canlı yayın bulunamadı', style: const TextStyle(color: AppColors.textSecondary)));
    final int displayCount = items.length > 15 ? 15 : items.length;
    final bool showAll = items.length > 15;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: displayCount + (showAll ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayCount) return _buildShowAllCard(context, title, AppColors.success, items, ThematicGridType.live);
          final channel = items[index];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(mediaId: channel.streamId, mediaName: channel.name, mediaType: 'live'))),
            child: Container(
              width: 105,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
              child: Column(
                children: [
                  Expanded(child: Padding(padding: const EdgeInsets.all(8.0), child: channel.icon != null && channel.icon!.isNotEmpty ? CachedNetworkImage(imageUrl: channel.icon!, fit: BoxFit.contain, errorWidget: (_,__,___) => const Center(child: Icon(Icons.tv, color: Colors.white54, size: 30))) : const Center(child: Icon(Icons.tv, color: Colors.white54, size: 30)))),
                  Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4), decoration: const BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(11), bottomRight: Radius.circular(11))), child: Text(channel.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchedDynamicRow(String title, List<dynamic> items) {
    if (items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Belgesel bulunamadı', style: TextStyle(color: AppColors.textSecondary)));
    final int displayCount = items.length > 15 ? 15 : items.length;
    final bool showAll = items.length > 15;
    return SizedBox(
      height: 165,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: displayCount + (showAll ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayCount) return _buildShowAllCard(context, title, AppColors.warning, items, ThematicGridType.mixed);
          final matched = items[index];
          if (matched is MatchedMovie) {
            final tmdb = matched.tmdbMovie;
            return _buildPosterCard(
              context: context, title: tmdb.title, posterUrl: tmdb.posterUrl, voteAverage: tmdb.voteAverage, color: AppColors.warning,
              onTap: () => showMovieDetailSheet(context, mediaId: matched.streamId, name: tmdb.title, posterUrl: tmdb.posterUrl, description: tmdb.overview, year: tmdb.releaseDate.length >= 4 ? tmdb.releaseDate.substring(0, 4) : null, rating: tmdb.voteAverage.toStringAsFixed(1)),
            );
          } else if (matched is MatchedSeries) {
            final tmdb = matched.tmdbSeries;
            return _buildPosterCard(
              context: context, title: tmdb.name, posterUrl: tmdb.posterUrl, voteAverage: tmdb.voteAverage, color: AppColors.warning,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(mediaId: matched.seriesId, mediaName: tmdb.name, mediaType: 'series'))),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildMatchedVodRow(String title, List<MatchedMovie> items) {
    if (items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Film bulunamadı', style: TextStyle(color: AppColors.textSecondary)));
    final int displayCount = items.length > 15 ? 15 : items.length;
    final bool showAll = items.length > 15;
    return SizedBox(
      height: 165,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: displayCount + (showAll ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayCount) return _buildShowAllCard(context, title, AppColors.accent, items, ThematicGridType.movie);
          final matched = items[index];
          final tmdb = matched.tmdbMovie;
          return _buildPosterCard(
            context: context, title: tmdb.title, posterUrl: tmdb.posterUrl, voteAverage: tmdb.voteAverage, color: AppColors.accent,
            onTap: () => showMovieDetailSheet(context, mediaId: matched.streamId, name: tmdb.title, posterUrl: tmdb.posterUrl, description: tmdb.overview, year: tmdb.releaseDate.length >= 4 ? tmdb.releaseDate.substring(0, 4) : null, rating: tmdb.voteAverage.toStringAsFixed(1)),
          );
        },
      ),
    );
  }

  Widget _buildMatchedSeriesRow(String title, List<MatchedSeries> items) {
    if (items.isEmpty) return const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Dizi bulunamadı', style: TextStyle(color: AppColors.textSecondary)));
    final int displayCount = items.length > 15 ? 15 : items.length;
    final bool showAll = items.length > 15;
    return SizedBox(
      height: 165,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: displayCount + (showAll ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == displayCount) return _buildShowAllCard(context, title, const Color(0xFFFF4081), items, ThematicGridType.series);
          final matched = items[index];
          final tmdb = matched.tmdbSeries;
          return _buildPosterCard(
            context: context, title: tmdb.name, posterUrl: tmdb.posterUrl, voteAverage: tmdb.voteAverage, color: const Color(0xFFFF4081),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(mediaId: matched.seriesId, mediaName: tmdb.name, mediaType: 'series'))),
          );
        },
      ),
    );
  }

  Widget _buildPosterCard({required BuildContext context, required String title, required String posterUrl, required double voteAverage, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 105,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.3)), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              posterUrl.isNotEmpty ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(color: Colors.black26)) : Container(color: Colors.black26),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent])),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(children: [const Icon(Icons.star_rounded, color: AppColors.warning, size: 10), const SizedBox(width: 4), Text(voteAverage.toStringAsFixed(1), style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.bold))]),
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

  Widget _buildShowAllCard(BuildContext context, String title, Color color, List<dynamic> items, ThematicGridType type) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ThematicGridScreen(title: title, themeColor: color, type: type, items: items))),
      child: Container(
        width: 105,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.5))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.arrow_forward_rounded, color: color, size: 32),
            const SizedBox(height: 8),
            Text('Tümünü Göster', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
"""
    content = content[:start_idx] + NEW_METHODS
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Sports Refactored")
