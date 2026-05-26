import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../data/models/iptv_models.dart';
import '../controllers/iptv_controller.dart';
import '../screens/player_screen.dart';

void showSeriesDetailSheet(BuildContext context, {
  required int seriesId,
  required String name,
  String? posterUrl,
  String? rating,
  String? description,
  String? year,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => _SeriesDetailSheet(
      seriesId: seriesId,
      name: name,
      posterUrl: posterUrl,
      rating: rating,
      description: description,
      year: year,
    ),
  );
}

class _SeriesDetailSheet extends ConsumerStatefulWidget {
  final int seriesId;
  final String name;
  final String? posterUrl;
  final String? rating;
  final String? description;
  final String? year;

  const _SeriesDetailSheet({
    required this.seriesId,
    required this.name,
    this.posterUrl,
    this.rating,
    this.description,
    this.year,
  });

  @override
  ConsumerState<_SeriesDetailSheet> createState() => _SeriesDetailSheetState();
}

class _SeriesDetailSheetState extends ConsumerState<_SeriesDetailSheet> {
  List<IptvEpisode>? _episodes;
  bool _isLoading = true;
  String? _error;
  
  Map<int, List<IptvEpisode>> _seasonsMap = {};
  int _selectedSeason = 1;

  @override
  void initState() {
    super.initState();
    _fetchEpisodes();
  }

  Future<void> _fetchEpisodes() async {
    try {
      final episodes = await ref.read(iptvControllerProvider.notifier).getEpisodesForSeries(widget.seriesId);
      
      if (mounted) {
        setState(() {
          _episodes = episodes;
          _isLoading = false;
          
          if (episodes.isNotEmpty) {
            // Group by season
            for (var ep in episodes) {
              if (!_seasonsMap.containsKey(ep.season)) {
                _seasonsMap[ep.season] = [];
              }
              _seasonsMap[ep.season]!.add(ep);
            }
            
            // Set initial selected season to the first available season
            final seasons = _seasonsMap.keys.toList()..sort();
            if (seasons.isNotEmpty) {
              _selectedSeason = seasons.first;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Cover image
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                Positioned.fill(
                  child: widget.posterUrl != null && widget.posterUrl!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: widget.posterUrl!, fit: BoxFit.cover, errorWidget: (context, url, error) => Container(color: AppColors.surface))
                      : Container(color: AppColors.surface),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.background, AppColors.background.withValues(alpha: 0.2), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (widget.rating != null && widget.rating!.isNotEmpty) ...[
                            const Icon(Icons.star_rounded, color: AppColors.warning, size: 16),
                            const SizedBox(width: 4),
                            Text(widget.rating!, style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 12),
                          ],
                          if (widget.year != null && widget.year!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                              child: Text(widget.year!, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Description
          if (widget.description != null && widget.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                widget.description!,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
          const Divider(color: Colors.white12, height: 1),
          
          // Episodes Section
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? Center(child: Text('Bölümler yüklenirken hata oluştu: $_error', style: const TextStyle(color: Colors.red)))
                    : _episodes == null || _episodes!.isEmpty
                        ? const Center(child: Text('Bölüm bulunamadı.', style: TextStyle(color: Colors.white54)))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Season Selector
                              if (_seasonsMap.keys.length > 1)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: (_seasonsMap.keys.toList()..sort()).map((season) {
                                        final isSelected = _selectedSeason == season;
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 10),
                                          child: ChoiceChip(
                                            label: Text('Sezon $season'),
                                            selected: isSelected,
                                            selectedColor: AppColors.primary,
                                            backgroundColor: AppColors.surface,
                                            labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white70),
                                            onSelected: (selected) {
                                              if (selected) {
                                                setState(() {
                                                  _selectedSeason = season;
                                                });
                                              }
                                            },
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              
                              // Episode List
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  itemCount: _seasonsMap[_selectedSeason]?.length ?? 0,
                                  itemBuilder: (context, index) {
                                    final episode = _seasonsMap[_selectedSeason]![index];
                                    return ListTile(
                                      leading: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: Colors.white12,
                                              borderRadius: BorderRadius.circular(8),
                                              image: widget.posterUrl != null
                                                  ? DecorationImage(
                                                      image: CachedNetworkImageProvider(widget.posterUrl!),
                                                      fit: BoxFit.cover,
                                                      colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.5), BlendMode.darken),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 30),
                                        ],
                                      ),
                                      title: Text(
                                        'Bölüm ${episode.episodeNum}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        episode.title.isNotEmpty ? episode.title : 'Sezon ${episode.season} Bölüm ${episode.episodeNum}',
                                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () {
                                        Navigator.push(context, MaterialPageRoute(
                                          builder: (_) => PlayerScreen(
                                            mediaId: episode.id, 
                                            mediaName: '${widget.name} - S${episode.season} E${episode.episodeNum}', 
                                            mediaType: 'series',
                                            episodeExtension: episode.containerExtension,
                                          )
                                        ));
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
