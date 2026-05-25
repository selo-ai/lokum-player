import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../data/models/iptv_models.dart';
import '../controllers/auth_controller.dart';
import '../controllers/iptv_controller.dart';
import '../controllers/providers.dart';
import '../widgets/glass_container.dart';
import 'media_list_screen.dart';
import 'player_screen.dart';
import '../controllers/vod_matcher_provider.dart';
import '../../data/models/tmdb_models.dart';
import 'login_screen.dart';
import '../controllers/language_provider.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'sports_dashboard_screen.dart';
import 'horror_room_screen.dart';
import 'laughing_gas_screen.dart';
import 'kids_club_screen.dart';
import 'action_room_screen.dart';
import 'scifi_room_screen.dart';
import 'nostalgia_room_screen.dart';
import 'ai_assistant_sheet.dart';
import 'live_tv_dashboard.dart';
import '../widgets/movie_detail_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  Offset _aiButtonOffset = const Offset(300, 600); // Default position (bottom right)
  bool _isAiButtonInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAiButtonInitialized) {
      final size = MediaQuery.of(context).size;
      _aiButtonOffset = Offset(size.width - 80, size.height - 150);
      _isAiButtonInitialized = true;
    }
  }
  final TextEditingController _searchController = TextEditingController();
  
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;
  bool _isHighlightsExpanded = false;

  @override
  void initState() {
    super.initState();
    // Trigger loading content when home screen is first initialized
    Future.microtask(() {
      ref.read(iptvControllerProvider.notifier).loadAllContent().then((_) {
        _startBannerTimer();
      });
    });
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final asyncRec = ref.read(mixedCarouselProvider);
      final recommendations = asyncRec.value ?? [];
      if (recommendations.isNotEmpty) {
        final int nextIndex = ((_currentBannerIndex + 1) % recommendations.length).toInt();
        if (_bannerController.hasClients) {
          _bannerController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
          );
        }
      }
    });
  }

  void _showSeriesDetails(BuildContext context, dynamic serie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return SeriesDetailSheet(serie: serie);
      },
    );
  }



  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iptvState = ref.watch(iptvControllerProvider);

    final List<Widget> pages = [
      _buildDashboard(iptvState),
      const MediaListScreen(contentType: 'live'),
      const MediaListScreen(contentType: 'movie'),
      const MediaListScreen(contentType: 'series'),
      const FavoritesScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(decoration: const BoxDecoration(gradient: AppColors.backgroundGradient)),
          
          // Active Page Content
          Positioned.fill(
            child: iptvState.isLoading
                ? _buildLoader()
                : pages[_currentIndex],
          ),

          // Floating Glass Bottom Navigation Bar
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              bottom: true,
              child: GlassContainer(
                borderRadius: 16,
                blur: 20,
                color: AppColors.surface.withOpacity(0.55),
                height: 68, // slightly taller for elegant padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, ref.tr('tab_dashboard')),
                    _buildNavItem(1, Icons.tv_outlined, Icons.tv_rounded, ref.tr('tab_live')),
                    _buildNavItem(2, Icons.movie_filter_outlined, Icons.movie_filter_rounded, ref.tr('tab_movies')),
                    _buildNavItem(3, Icons.video_library_outlined, Icons.video_library_rounded, ref.tr('tab_series')),
                    _buildNavItem(4, Icons.star_border_rounded, Icons.star_rounded, ref.tr('tab_favorites')),
                  ],
                ),
              ),
            ),
          ),
          
          // Draggable AI Assistant Button
          Positioned(
            left: _aiButtonOffset.dx,
            top: _aiButtonOffset.dy,
            child: Draggable(
              feedback: _buildAiButton(isDragging: true),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                setState(() {
                  // Keep it within screen bounds
                  final size = MediaQuery.of(context).size;
                  double dx = details.offset.dx;
                  double dy = details.offset.dy - 50; // account for touch point
                  
                  if (dx < 0) dx = 0;
                  if (dx > size.width - 60) dx = size.width - 60;
                  if (dy < 0) dy = 0;
                  if (dy > size.height - 100) dy = size.height - 100;
                  
                  _aiButtonOffset = Offset(dx, dy);
                });
              },
              child: _buildAiButton(isDragging: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiButton({required bool isDragging}) {
    return GestureDetector(
      onTap: () {
        if (!isDragging) {
          _showAiModal(context, ref);
        }
      },
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Colors.purpleAccent, Colors.blueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withValues(alpha: 0.5),
              blurRadius: 15,
              spreadRadius: isDragging ? 5 : 2,
            ),
          ],
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  void _showAiModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiAssistantSheet(),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;

    // Per-tab vibrant accent colors
    const tabColors = <int, Color>{
      0: AppColors.primary,          // Dashboard — Neon Cyan
      1: AppColors.success,          // Live — Green
      2: AppColors.accent,           // Movies — Purple
      3: Color(0xFFFF4081),          // Series — Pink
      4: AppColors.warning,          // Favorites — Amber (same as fav star)
    };
    final activeColor = tabColors[index] ?? AppColors.primary;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuint,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? activeColor.withOpacity(0.4) : Colors.transparent,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.1),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : outlineIcon,
                color: isSelected ? activeColor : AppColors.textSecondary,
                size: 24,
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: activeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- Loader Widget (Premium Glassmorphic Loader) ---
  Widget _buildLoader() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 26),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              ref.tr('updating'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              ref.tr('splash_subtitle'),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightsRow(String title, List<dynamic> items, IptvState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4, height: 18,
                decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              bool isMovie = false;
              dynamic tmdbData;
              String imagePath = '';
              int streamId = 0;
              
              if (item is CarouselMedia) {
                isMovie = item.isMovie;
                tmdbData = item.tmdbData;
                imagePath = item.posterUrl.isNotEmpty ? item.posterUrl : item.coverOrIcon;
                streamId = item.streamId;
              } else if (item is MatchedMovie) {
                isMovie = true;
                tmdbData = item.tmdbMovie;
                imagePath = tmdbData.posterUrl.isNotEmpty ? tmdbData.posterUrl : item.streamIcon;
                streamId = item.streamId;
              } else if (item is MatchedSeries) {
                isMovie = false;
                tmdbData = item.tmdbSeries;
                imagePath = tmdbData.posterUrl.isNotEmpty ? tmdbData.posterUrl : item.cover;
                streamId = item.seriesId;
              }

              final String titleText = isMovie ? (tmdbData as TmdbMovie).title : (tmdbData as TmdbSeries).name;
              final double voteAverage = isMovie ? (tmdbData as TmdbMovie).voteAverage : (tmdbData as TmdbSeries).voteAverage;

              return GestureDetector(
                onTap: () {
                  if (isMovie) {
                    showMovieDetailSheet(
                      context,
                      mediaId: streamId,
                      name: titleText,
                      posterUrl: imagePath,
                      description: isMovie ? (tmdbData as TmdbMovie).overview : null,
                      year: isMovie 
                          ? ((tmdbData as TmdbMovie).releaseDate.length >= 4 ? (tmdbData as TmdbMovie).releaseDate.substring(0, 4) : null)
                          : null,
                      rating: voteAverage.toStringAsFixed(1),
                    );
                  } else {
                    try {
                      final iptvSeries = state.series.firstWhere((s) => s.seriesId == streamId);
                      _showSeriesDetails(context, iptvSeries);
                    } catch (_) {}
                  }
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight.withOpacity(0.1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: imagePath,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.surface),
                          errorWidget: (_, __, ___) => Container(color: AppColors.surface),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12, bottom: 12, right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleText,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '★ ${voteAverage.toStringAsFixed(1)}',
                                style: TextStyle(color: AppColors.secondary, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- Dashboard View ---
  Widget _buildDashboard(IptvState state) {
    final history = ref.read(iptvControllerProvider.notifier).getHistory();
    


    final asyncRec = ref.watch(mixedCarouselProvider);
    final recommendations = asyncRec.value ?? [];

    final asyncMoviesRec = ref.watch(trendingMoviesProvider);
    final movieRecommendations = asyncMoviesRec.value ?? [];

    final asyncSeriesRec = ref.watch(trendingSeriesProvider);
    final seriesRecommendations = asyncSeriesRec.value ?? [];

    final asyncDocsRec = ref.watch(trendingDocumentariesProvider);
    final docsRecommendations = asyncDocsRec.value ?? [];

    String getRelativeTime(DateTime? time) {
      if (time == null) return ref.tr('last_updated_never');
      final diff = DateTime.now().difference(time);
      if (diff.inMinutes < 1) return ref.tr('last_updated_just_now');
      if (diff.inHours < 1) return '${diff.inMinutes} ${ref.tr('last_updated_mins_ago')}';
      if (diff.inDays < 1) return '${diff.inHours} ${ref.tr('last_updated_hours_ago')}';
      return '${diff.inDays} ${ref.tr('last_updated_days_ago')}';
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(iptvControllerProvider.notifier).loadAllContent();
      },
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceLight,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LOKUM MC',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${ref.tr('last_updated_prefix')}${getRelativeTime(state.lastUpdated)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Refresh All / Tümünü Güncelle Button
                    GestureDetector(
                      onTap: () async {
                        try {
                          await ref.read(iptvControllerProvider.notifier).loadAllContent();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        ref.tr('update_success'),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.surfaceLight.withOpacity(0.9),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        ref.tr('update_error'),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppColors.surfaceLight.withOpacity(0.9),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        }
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Search Placeholder Button
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ref.tr('search_coming_soon'))),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // App Settings Screen Router
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 24),

          // Featured Media Banner Carousel
          if (recommendations.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              height: 180,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _bannerController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentBannerIndex = index;
                      });
                    },
                    itemCount: recommendations.length,
                    itemBuilder: (context, index) {
                      final CarouselMedia item = recommendations[index];
                      final imagePath = item.backdropUrl.isNotEmpty ? item.backdropUrl : item.coverOrIcon;
                      final String tagText = item.isMovie ? ref.tr('dashboard_featured_movie') : ref.tr('dashboard_featured_series');
                      final Color tagBgColor = item.isMovie ? AppColors.primary : AppColors.secondary;
                      final Color tagTextColor = item.isMovie ? Colors.black : Colors.white;
                      final String subtitleText = '${item.releaseDate.isNotEmpty ? item.releaseDate.split('-').first : "2026"} • VOD • ★ ${item.voteAverage.toStringAsFixed(1)}';

                      return GestureDetector(
                        onTap: () {
                          if (item.isMovie) {
                            showMovieDetailSheet(
                              context,
                              mediaId: item.streamId,
                              name: item.title,
                              posterUrl: item.coverOrIcon,
                              description: item.tmdbData is TmdbMovie ? (item.tmdbData as TmdbMovie).overview : null,
                              year: item.releaseDate.length >= 4 ? item.releaseDate.substring(0, 4) : null,
                              rating: item.voteAverage.toStringAsFixed(1),
                            );
                          } else {
                            try {
                              final iptvSeries = state.series.firstWhere((s) => s.seriesId == item.streamId);
                              _showSeriesDetails(context, iptvSeries);
                            } catch (_) {}
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderLight.withOpacity(0.1), width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                // Banner Image
                                Positioned.fill(
                                  child: imagePath.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: imagePath,
                                          fit: BoxFit.cover,
                                          placeholder: (_, __) => Container(color: AppColors.surface),
                                          errorWidget: (_, __, ___) => Container(
                                            decoration: const BoxDecoration(
                                              gradient: AppColors.primaryGradient,
                                            ),
                                          ),
                                        )
                                      : Container(decoration: const BoxDecoration(gradient: AppColors.primaryGradient)),
                                ),
                                // Gradient Overlay
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                                        begin: Alignment.bottomLeft,
                                        end: Alignment.topRight,
                                      ),
                                    ),
                                  ),
                                ),
                                // Text Info
                                Positioned(
                                  left: 20,
                                  bottom: 20,
                                  right: 40,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: tagBgColor, borderRadius: BorderRadius.circular(6)),
                                        child: Text(tagText, style: TextStyle(color: tagTextColor, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.title,
                                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitleText,
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Page Indicator Dots
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        recommendations.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentBannerIndex == index ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentBannerIndex == index
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Expandable Highlights Banner
          GestureDetector(
            onTap: () {
              setState(() {
                _isHighlightsExpanded = !_isHighlightsExpanded;
              });
            },
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [Colors.black, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(Icons.star_rounded, size: 100, color: Colors.white.withOpacity(0.05)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'ÖNE ÇIKANLAR',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Trend filmler, diziler ve belgeseller',
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _isHighlightsExpanded ? Icons.keyboard_arrow_up : Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                        
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: _isHighlightsExpanded ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),
                              if (movieRecommendations.isNotEmpty) _buildHighlightsRow('Trend Filmler', movieRecommendations, state),
                              if (seriesRecommendations.isNotEmpty) _buildHighlightsRow('Trend Diziler', seriesRecommendations, state),
                              if (docsRecommendations.isNotEmpty) _buildHighlightsRow('Trend Belgeseller', docsRecommendations, state),
                            ],
                          ) : const SizedBox(width: double.infinity, height: 0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // SPOR - ÇOCUK - KORKU - GÜLME - ADRENALİN - GALAKSİ - NOSTALJİ
          _buildBanner(
            context,
            ref.tr('home_sports_center'),
            ref.tr('home_sports_desc'),
            Icons.sports_soccer_rounded,
            AppColors.success,
            const SportsDashboardScreen(),
          ),
          const SizedBox(height: 16),
          _buildBanner(
            context,
            'ÇOCUK KULÜBÜ',
            'Çocuklara özel kanallar, çizgi filmler',
            Icons.smart_toy_rounded,
            Colors.orangeAccent,
            const KidsClubScreen(),
          ),
          const SizedBox(height: 16),
          _buildBanner(
            context,
            ref.tr('home_horror_room'),
            ref.tr('home_horror_desc'),
            Icons.local_fire_department_rounded,
            Colors.redAccent,
            const HorrorRoomScreen(),
          ),
          const SizedBox(height: 16),
          _buildBanner(
            context,
            'GÜLME GAZI',
            'Komedi filmleri ve dizileri',
            Icons.emoji_emotions_rounded,
            Colors.amberAccent,
            const LaughingGasScreen(),
          ),
          const SizedBox(height: 16),
          _buildBanner(
            context,
            'ADRENALİN BOOM',
            'Aksiyon ve macera dolu içerikler',
            Icons.local_fire_department_rounded,
            Colors.red,
            const ActionRoomScreen(),
          ),
          const SizedBox(height: 16),
          _buildBanner(
            context,
            'GALAKSİ VE ÖTESİ',
            'Bilim kurgu ve uzay temalı yapımlar',
            Icons.satellite_alt_rounded,
            Colors.deepPurpleAccent,
            const ScifiRoomScreen(),
          ),
          const SizedBox(height: 16),
          _buildBanner(
            context,
            'NOSTALJİ RÜZGARI',
            'Eski western ve klasik yapımlar',
            Icons.radio_rounded,
            Colors.brown,
            const NostalgiaRoomScreen(),
          ),
          const SizedBox(height: 28),
          // Watch History ("Son İzlenenler")
          if (history.isNotEmpty) ...[
            Text(
              ref.tr('dashboard_recently_watched'),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: history.length,
                itemBuilder: (context, idx) {
                  final item = history[idx];
                  return GestureDetector(
                      onTap: () {
                        if (item['type'] == 'live') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(
                                mediaId: item['id'],
                                mediaName: item['name'],
                                mediaType: 'live',
                              ),
                            ),
                          );
                        } else if (item['type'] == 'movie') {
                          showMovieDetailSheet(
                            context,
                            mediaId: item['id'],
                            name: item['name'],
                            posterUrl: item['icon'] ?? '',
                          );
                        } else {
                          // Series
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(
                                mediaId: item['id'],
                                mediaName: item['name'],
                                mediaType: 'series',
                                episodeExtension: item['extra'], 
                              ),
                            ),
                          );
                        }
                      },
                    child: Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderDark, width: 1),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: item['icon'] != null
                                  ? CachedNetworkImage(
                                      imageUrl: item['icon'],
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(color: AppColors.surfaceLight),
                                    )
                                  : Container(color: AppColors.surfaceLight),
                            ),
                            Positioned.fill(
                              child: Container(color: Colors.black.withOpacity(0.55)),
                            ),
                            const Center(
                              child: Icon(Icons.play_circle_outline, color: Colors.white, size: 36),
                            ),
                            Positioned(
                              left: 8,
                              right: 8,
                              bottom: 8,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    item['type'] == 'live' ? ref.tr('dashboard_live') : (item['type'] == 'movie' ? ref.tr('media_movie_label') : ref.tr('media_series_label')),
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 28),
          ],
        ],
      ),
    ),
  );
}



  Widget _buildBanner(BuildContext context, String title, String desc, IconData icon, Color color, Widget destination) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination));
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 100),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black, color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(icon, size: 100, color: Colors.white.withValues(alpha: 0.05)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
