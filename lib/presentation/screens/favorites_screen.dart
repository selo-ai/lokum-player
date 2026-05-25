import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../data/models/iptv_models.dart';
import '../controllers/iptv_controller.dart';
import '../controllers/providers.dart';
import '../controllers/language_provider.dart';
import '../widgets/glass_container.dart';
import 'player_screen.dart';
import 'media_list_screen.dart'; // Import for SeriesDetailSheet
import '../widgets/movie_detail_sheet.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int _selectedFavoritesTab = 0;

  String _normalizeCategoryName(String text) {
    return text
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  bool _isDailySeriesCategory(String name) {
    final norm = _normalizeCategoryName(name);
    return norm.contains('pazartesi') || 
           norm.contains('sali') || 
           norm.contains('carsamba') || 
           norm.contains('persembe') || 
           norm.contains('cuma') || 
           norm.contains('cumartesi') || 
           norm.contains('pazar') || 
           norm.contains('gunluk') || 
           norm.contains('daily');
  }

  void _showSeriesDetails(BuildContext context, dynamic serie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SeriesDetailSheet(serie: serie);
      },
    );
  }

  Widget _buildFavChip(int index, String label, IconData icon, int count) {
    final isSelected = _selectedFavoritesTab == index;
    final themeColor = index == 0
        ? AppColors.primary
        : (index == 1 ? AppColors.secondary : AppColors.accent);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFavoritesTab = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? themeColor.withOpacity(0.15) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? themeColor.withOpacity(0.5) : AppColors.borderDark,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? themeColor : AppColors.textSecondary,
                    size: 16,
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? themeColor : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String typeLabel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface.withOpacity(0.5),
              ),
              child: const Icon(
                Icons.star_border_rounded,
                color: AppColors.textMuted,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              ref.tr('dashboard_no_favorites'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                ref.tr('dashboard_no_favorites_desc'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iptvControllerProvider);

    final dailySeriesCategoryIds = state.movieCategories
        .where((cat) => _isDailySeriesCategory(cat.name))
        .map((cat) => cat.id)
        .toSet();

    final dailySeriesFavMovies = state.favoriteMovies.where((m) => dailySeriesCategoryIds.contains(m.categoryId)).toList();
    final regularFavMovies = state.favoriteMovies.where((m) => !dailySeriesCategoryIds.contains(m.categoryId)).toList();
    final allFavSeries = [...state.favoriteSeries, ...dailySeriesFavMovies];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
              child: Text(
                ref.tr('dashboard_favorites'),
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),

            // Tab Selector Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildFavChip(0, ref.tr('dashboard_live'), Icons.tv_rounded, state.favoriteLive.length),
                  const SizedBox(width: 8),
                  _buildFavChip(1, ref.tr('dashboard_movies'), Icons.movie_rounded, regularFavMovies.length),
                  const SizedBox(width: 8),
                  _buildFavChip(2, ref.tr('dashboard_series'), Icons.video_library_rounded, allFavSeries.length),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Active Tab Content
            Expanded(
              child: _selectedFavoritesTab == 0
                  ? _buildLiveFavorites(state.favoriteLive)
                  : (_selectedFavoritesTab == 1
                      ? _buildMovieFavorites(regularFavMovies)
                      : _buildSeriesFavorites(allFavSeries)),
            ),
          ],
        ),
      ),
    );
  }

  // --- Live TV Favorites View ---
  Widget _buildLiveFavorites(List<IptvLiveChannel> list) {
    if (list.isEmpty) return _buildEmptyState('Live TV');

    final groupedList = _groupChannels(list);

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
      itemCount: groupedList.length,
      itemBuilder: (context, idx) {
        final group = groupedList[idx];
        return GroupedChannelTile(group: group);
      },
    );
  }

  List<GroupedLiveChannel> _groupChannels(List<IptvLiveChannel> channels) {
    final Map<String, List<IptvLiveChannel>> groups = {};
    for (final channel in channels) {
      final groupKey = '${channel.categoryId}_${channel.baseName}';
      groups.putIfAbsent(groupKey, () => []).add(channel);
    }

    final priority = ['fhd', '1080p', 'hd', '720p', 'hq', 'hevc', 'h265', 'sd', 'yedek', 'backup', 'alt'];
    int getPriority(String label) {
      final cleaned = label.toLowerCase();
      for (int i = 0; i < priority.length; i++) {
        if (cleaned.contains(priority[i])) {
          return i;
        }
      }
      return priority.length;
    }

    final List<GroupedLiveChannel> groupedList = [];
    groups.forEach((groupKey, variations) {
      variations.sort((a, b) {
        final pA = getPriority(a.qualityLabel);
        final pB = getPriority(b.qualityLabel);
        if (pA != pB) return pA.compareTo(pB);
        return a.displayName.compareTo(b.displayName);
      });
      groupedList.add(GroupedLiveChannel(baseName: variations.first.baseName, variations: variations));
    });

    groupedList.sort((a, b) => a.mainChannel.num.compareTo(b.mainChannel.num));
    return groupedList;
  }

  // --- Movie Favorites View ---
  Widget _buildMovieFavorites(List<IptvMovie> list) {
    if (list.isEmpty) return _buildEmptyState('Movie');

    return GridView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final movie = list[index];
        return GestureDetector(
          onTap: () {
            showMovieDetailSheet(
              context,
              mediaId: movie.streamId,
              name: movie.name,
              posterUrl: movie.icon,
              year: movie.year,
              rating: movie.rating?.toString(),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Poster Image
                  Positioned.fill(
                    child: movie.icon != null && movie.icon!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: movie.icon!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.surface),
                            errorWidget: (_, __, ___) => Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.cardGradient,
                              ),
                              child: const Icon(Icons.movie_rounded, color: AppColors.secondary, size: 36),
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.cardGradient,
                            ),
                            child: const Icon(Icons.movie_rounded, color: AppColors.secondary, size: 36),
                          ),
                  ),

                  // Overlay Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),

                  // Title and Year Info
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          movie.year ?? 'VOD',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Favorite Action Toggle Button Overlay (Top Right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(movie);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TV Series Favorites View ---
  Widget _buildSeriesFavorites(List<dynamic> list) {
    if (list.isEmpty) return _buildEmptyState('Series');

    return GridView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final series = list[index];
        final isMovieItem = series is IptvMovie;
        final String? imageUrl = isMovieItem ? series.icon : series.cover;
        final IconData fallbackIcon = isMovieItem ? Icons.movie_rounded : Icons.video_library_rounded;
        final Color fallbackColor = isMovieItem ? AppColors.secondary : AppColors.accent;

        return GestureDetector(
          onTap: () {
            if (isMovieItem) {
              showMovieDetailSheet(
                context,
                mediaId: series.streamId,
                name: series.name,
                posterUrl: series.icon,
                year: series.year,
                rating: series.rating?.toString(),
              );
            } else {
              _showSeriesDetails(context, series);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderDark, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Cover Image
                  Positioned.fill(
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.surface),
                            errorWidget: (_, __, ___) => Container(
                              decoration: const BoxDecoration(
                                gradient: AppColors.cardGradient,
                              ),
                              child: Icon(fallbackIcon, color: fallbackColor, size: 36),
                            ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: AppColors.cardGradient,
                            ),
                            child: Icon(fallbackIcon, color: fallbackColor, size: 36),
                          ),
                  ),

                  // Overlay Gradient
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ),

                  // Title and Date Info
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          series.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isMovieItem
                              ? (series.year ?? 'VOD')
                              : (series.releaseDate != null && series.releaseDate!.length >= 4
                                  ? series.releaseDate!.substring(0, 4)
                                  : 'Series'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Favorite Action Toggle Button Overlay (Top Right)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        if (isMovieItem) {
                          ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(series);
                        } else {
                          ref.read(iptvControllerProvider.notifier).toggleFavoriteSeries(series);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Icon(
                          Icons.star_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
