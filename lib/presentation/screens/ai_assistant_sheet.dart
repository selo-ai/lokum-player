import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../controllers/ai_provider.dart';
import 'player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AiAssistantSheet extends ConsumerStatefulWidget {
  const AiAssistantSheet({super.key});

  @override
  ConsumerState<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends ConsumerState<AiAssistantSheet> {
  final TextEditingController _promptController = TextEditingController();

  void _submitPrompt() {
    final prompt = _promptController.text.trim();
    if (prompt.isNotEmpty) {
      ref.read(aiControllerProvider.notifier).askAssistant(prompt);
      FocusScope.of(context).unfocus(); // hide keyboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiControllerProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: const Color(0xFF151525), // Deep dark premium blue
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 16),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 28),
              const SizedBox(width: 10),
              Text(
                'Sihirli Asistan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: [Shadow(color: Colors.purpleAccent.withValues(alpha: 0.5), blurRadius: 10)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Input Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Bana bol ödüllü bir bilim kurgu dizisi bul...',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.purpleAccent),
                      ),
                    ),
                    onSubmitted: (_) => _submitPrompt(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: aiState.isLoading ? null : _submitPrompt,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purpleAccent, Colors.blueAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: aiState.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Results Area
          Expanded(
            child: aiState.isLoading
                ? _buildLoadingState()
                : aiState.error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Hata: ${aiState.error}',
                            style: const TextStyle(color: Colors.redAccent),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : _buildResultsView(aiState),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.purpleAccent, size: 60),
          const SizedBox(height: 20),
          Text(
            'Kütüphaneniz taranıyor...\nEn iyilerini buluyorum!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(AIState aiState) {
    if (aiState.suggestedMovies.isEmpty && aiState.suggestedSeries.isEmpty) {
      return Center(
        child: Text(
          'Benimle sohbet ederek içerik arayabilirsiniz.\nÖrn: "Doksanlardan unutulmaz bir aksiyon filmi bul."',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        if (aiState.suggestedMovies.isNotEmpty) ...[
          _buildSectionTitle('Önerilen Filmler', Icons.movie_creation_rounded),
          const SizedBox(height: 12),
          _buildHorizontalMovies(aiState.suggestedMovies),
          const SizedBox(height: 30),
        ],
        if (aiState.suggestedSeries.isNotEmpty) ...[
          _buildSectionTitle('Önerilen Diziler', Icons.live_tv_rounded),
          const SizedBox(height: 12),
          _buildHorizontalSeries(aiState.suggestedSeries),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: Colors.purpleAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalMovies(List<dynamic> items) {
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
            title: tmdb.title,
            posterUrl: matched.streamIcon ?? '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    mediaId: matched.streamId,
                    mediaName: tmdb.title,
                    mediaType: 'movie',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHorizontalSeries(List<dynamic> items) {
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
            title: tmdb.name,
            posterUrl: matched.cover ?? '',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
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
    required String title,
    required String posterUrl,
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
          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
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
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                    ),
                  ),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
