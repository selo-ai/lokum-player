import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../screens/player_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/language_provider.dart';

void showMovieDetailSheet(BuildContext context, {
  required int mediaId,
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
    builder: (ctx) => _MovieDetailSheet(
      mediaId: mediaId,
      name: name,
      posterUrl: posterUrl,
      rating: rating,
      description: description,
      year: year,
    ),
  );
}

class _MovieDetailSheet extends ConsumerWidget {
  final int mediaId;
  final String name;
  final String? posterUrl;
  final String? rating;
  final String? description;
  final String? year;

  const _MovieDetailSheet({
    required this.mediaId,
    required this.name,
    this.posterUrl,
    this.rating,
    this.description,
    this.year,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Cover image
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                Positioned.fill(
                  child: posterUrl != null && posterUrl!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: posterUrl!, fit: BoxFit.cover, errorWidget: (context, url, error) => Container(color: AppColors.surface))
                      : Container(color: AppColors.surface),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.background, AppColors.background.withValues(alpha: 0.1), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                // Play Button Over Banner
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (year != null && year!.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(year!, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (rating != null && rating!.isNotEmpty) ...[
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(rating!, style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Close button
                Positioned(
                  top: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Play Button Action
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              mediaId: mediaId,
                              mediaName: name,
                              mediaType: 'movie',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      label: Text(
                        ref.tr('player_play') == 'player_play' ? 'Hemen İzle' : ref.tr('player_play'),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Özet',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (description != null && description!.isNotEmpty) ? description! : 'Bu film için açıklama bulunmamaktadır.',
                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
