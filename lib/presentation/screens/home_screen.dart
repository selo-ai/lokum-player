import 'dart:async';
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
import 'login_screen.dart';
import '../controllers/language_provider.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

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
      final state = ref.read(iptvControllerProvider);
      final recommendations = _getRecommendations(state);
      if (recommendations.isNotEmpty) {
        final nextIndex = (_currentBannerIndex + 1) % recommendations.length;
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

  List<dynamic> _getRecommendations(IptvState state) {
    final List<dynamic> recommendations = [];
    int movieIdx = 0;
    int seriesIdx = 0;
    
    while (recommendations.length < 3 && (movieIdx < state.movies.length || seriesIdx < state.series.length)) {
      if (movieIdx < state.movies.length && recommendations.length < 3) {
        recommendations.add(state.movies[movieIdx++]);
      }
      if (seriesIdx < state.series.length && recommendations.length < 3) {
        recommendations.add(state.series[seriesIdx++]);
      }
    }
    return recommendations;
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

  void _showServiceInfoModal(BuildContext context, IptvState state) {
    final authState = ref.read(authControllerProvider);
    final creds = authState.credentials;
    if (creds == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: ref.read(iptvApiProvider).getAccountInfo(creds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                final data = snapshot.data;
                final userInfo = data?['user_info'] as Map<String, dynamic>?;
                final serverInfo = data?['server_info'] as Map<String, dynamic>?;

                // Format expiration date cleanly
                String expDateText = 'Bilinmiyor';
                if (userInfo != null) {
                  final expRaw = userInfo['exp_date'];
                  if (expRaw == null || expRaw == '0' || expRaw.toString() == 'null' || expRaw.toString().isEmpty) {
                    expDateText = ref.tr('info_unlimited');
                  } else {
                    final seconds = int.tryParse(expRaw.toString());
                    if (seconds != null) {
                      final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                      expDateText = '${dt.day}.${dt.month}.${dt.year}';
                    }
                  }
                }

                // Active connections count
                final activeCons = userInfo?['active_cons']?.toString() ?? '0';
                final maxConnections = userInfo?['max_connections']?.toString() ?? '1';
                final String unknownText = ref.tr('info_unknown');

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar for drag
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Modal Title
                      Row(
                        children: [
                          const Icon(Icons.dns_rounded, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            ref.tr('info_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.borderDark, height: 32),

                      // Subscription Glassmorphic Card
                      Text(
                        ref.tr('info_sub_details'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildModalInfoRow(ref.tr('info_status'), ref.tr('dashboard_active'), isStatus: true),
                            const SizedBox(height: 12),
                            _buildModalInfoRow(ref.tr('info_exp_date'), expDateText),
                            const SizedBox(height: 12),
                            _buildModalInfoRow(ref.tr('info_active_connections'), '$activeCons / $maxConnections'),
                            if (userInfo?['is_trial']?.toString() == '1') ...[
                              const SizedBox(height: 12),
                              _buildModalInfoRow(ref.tr('info_account_type'), ref.tr('info_trial')),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Server Glassmorphic Card
                      Text(
                        ref.tr('info_server_details'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildModalInfoRow(ref.tr('info_server_url'), serverInfo?['url'] ?? creds.serverUrl),
                            const SizedBox(height: 12),
                            _buildModalInfoRow(ref.tr('info_timezone'), serverInfo?['timezone'] ?? unknownText),
                            const SizedBox(height: 12),
                            _buildModalInfoRow(ref.tr('info_server_time'), serverInfo?['time_now'] ?? unknownText),
                            if (userInfo?['allowed_outputs'] is List) ...[
                              const SizedBox(height: 12),
                              _buildModalInfoRow(
                                ref.tr('info_allowed_formats'),
                                (userInfo!['allowed_outputs'] as List).join(', ').toUpperCase(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stream Content Counts (Shifted from main screen)
                      Text(
                        ref.tr('info_content_stats'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildModalInfoRow(ref.tr('info_live_channels'), state.liveChannels.length.toString(), showDot: true, dotColor: AppColors.primary),
                            const SizedBox(height: 12),
                            _buildModalInfoRow(ref.tr('info_movies'), state.movies.length.toString(), showDot: true, dotColor: AppColors.secondary),
                            const SizedBox(height: 12),
                            _buildModalInfoRow(ref.tr('info_series'), state.series.length.toString(), showDot: true, dotColor: AppColors.accent),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        );
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

    // List of screens for bottom navigation
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
                height: 62,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
        ],
      ),
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

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          decoration: isSelected
              ? BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      activeColor.withOpacity(0.12),
                      activeColor.withOpacity(0.04),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ],
                  border: Border(
                    left: index > 0
                        ? BorderSide(
                            color: activeColor.withOpacity(0.4),
                            width: 1.5,
                          )
                        : BorderSide.none,
                    right: index < 4
                        ? BorderSide(
                            color: activeColor.withOpacity(0.4),
                            width: 1.5,
                          )
                        : BorderSide.none,
                  ),
                )
              : const BoxDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Icon(
                  isSelected ? filledIcon : outlineIcon,
                  color: isSelected ? activeColor : AppColors.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Loader Widget (Premium Shimmer) ---
  Widget _buildLoader() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            Container(width: 150, height: 28, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 24),
            Container(width: double.infinity, height: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 32),
            Container(width: 100, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (_, __) => Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(width: 120, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }

  // --- Dashboard View ---
  Widget _buildDashboard(IptvState state) {
    final history = ref.read(iptvControllerProvider.notifier).getHistory();
    


    final recommendations = _getRecommendations(state);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Welcome Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ref.tr('dashboard_welcome'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lokum Player',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  // Service Info Modal Trigger
                  GestureDetector(
                    onTap: () => _showServiceInfoModal(context, state),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      child: const Icon(
                        Icons.settings_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
                      final item = recommendations[index];
                      final isMovie = item is IptvMovie;
                      final imagePath = isMovie ? item.icon : item.cover;
                      final String tagText = isMovie ? ref.tr('dashboard_featured_movie') : ref.tr('dashboard_featured_series');
                      final Color tagBgColor = isMovie ? AppColors.primary : AppColors.secondary;
                      final Color tagTextColor = isMovie ? Colors.black : Colors.white;
                      final String subtitleText = isMovie 
                          ? '${item.year ?? "2026"} • VOD' 
                          : '${item.releaseDate != null && item.releaseDate!.length >= 4 ? item.releaseDate!.substring(0, 4) : "2026"} • ${ref.tr('media_series_label').toUpperCase()}';

                      return GestureDetector(
                        onTap: () {
                          if (isMovie) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerScreen(
                                  mediaId: item.streamId,
                                  mediaName: item.name,
                                  mediaType: 'movie',
                                ),
                              ),
                            );
                          } else {
                            _showSeriesDetails(context, item);
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
                                  child: imagePath != null
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
                                        item.name,
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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            mediaId: item['id'],
                            mediaName: item['name'],
                            mediaType: item['type'],
                            episodeExtension: item['extra'], // Pass episode extra if exists
                          ),
                        ),
                      );
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
    );
  }

  Widget _buildModalInfoRow(
    String label,
    String value, {
    bool isStatus = false,
    bool showDot = false,
    Color? dotColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDot) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor ?? AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (dotColor ?? AppColors.primary).withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (isStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
      ],
    );
  }

}
