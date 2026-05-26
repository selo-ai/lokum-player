import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../controllers/iptv_controller.dart';
import '../controllers/language_provider.dart';
import 'player_screen.dart';
import '../widgets/movie_detail_sheet.dart';
import '../widgets/series_detail_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iptvControllerProvider);
    
    final liveResults = _query.isEmpty ? [] : state.liveChannels.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).take(20).toList();
    final movieResults = _query.isEmpty ? [] : state.movies.where((m) => m.name.toLowerCase().contains(_query.toLowerCase())).take(20).toList();
    final seriesResults = _query.isEmpty ? [] : state.series.where((s) => s.name.toLowerCase().contains(_query.toLowerCase())).take(20).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (val) {
                          setState(() {
                            _query = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: ref.tr('search_hint'),
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          suffixIcon: _query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _query = '';
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Results
            Expanded(
              child: _query.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          Text(
                            ref.tr('search_hint'),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : (liveResults.isEmpty && movieResults.isEmpty && seriesResults.isEmpty)
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_rounded, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(
                                ref.tr('movie_not_found'),
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.only(bottom: 20),
                          children: [
                            if (liveResults.isNotEmpty) _buildResultSection('Canlı TV', liveResults, 'live'),
                            if (movieResults.isNotEmpty) _buildResultSection(ref.tr('home_movies'), movieResults, 'movie'),
                            if (seriesResults.isNotEmpty) _buildResultSection(ref.tr('home_series'), seriesResults, 'series'),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String title, List<dynamic> items, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            title,
            style: const TextStyle(color: AppColors.accent, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _getImage(item, type),
                ),
              ),
              title: Text(
                item.name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                type == 'live' ? 'Kanal' : type == 'movie' ? 'Film' : 'Dizi',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              onTap: () {
                if (type == 'live') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(mediaId: item.streamId, mediaName: item.name, mediaType: 'live')));
                } else if (type == 'movie') {
                  showMovieDetailSheet(context, mediaId: item.streamId, name: item.name, posterUrl: item.icon ?? '', description: '', rating: '');
                } else if (type == 'series') {
                  showSeriesDetailSheet(context, seriesId: item.seriesId, name: item.name, posterUrl: item.cover);
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _getImage(dynamic item, String type) {
    String url = '';
    if (type == 'live') url = item.icon ?? '';
    if (type == 'movie') url = item.icon ?? '';
    if (type == 'series') url = item.cover ?? '';

    if (url.isEmpty) return const Icon(Icons.tv_rounded, color: Colors.white54);
    
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => const Icon(Icons.tv_rounded, color: Colors.white54),
    );
  }
}
