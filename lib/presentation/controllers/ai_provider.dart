import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/ai_service.dart';
import 'iptv_controller.dart';
import '../../data/models/iptv_models.dart';
import '../../data/models/tmdb_models.dart';
import 'dart:convert';
import 'vod_matcher_provider.dart';

final aiServiceProvider = Provider<AIService>((ref) => AIService());

class AIState {
  final bool isLoading;
  final String? error;
  final List<MatchedMovie> suggestedMovies;
  final List<MatchedSeries> suggestedSeries;

  AIState({
    this.isLoading = false,
    this.error,
    this.suggestedMovies = const [],
    this.suggestedSeries = const [],
  });

  AIState copyWith({
    bool? isLoading,
    String? error,
    List<MatchedMovie>? suggestedMovies,
    List<MatchedSeries>? suggestedSeries,
  }) {
    return AIState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      suggestedMovies: suggestedMovies ?? this.suggestedMovies,
      suggestedSeries: suggestedSeries ?? this.suggestedSeries,
    );
  }
}

class AIController extends Notifier<AIState> {
  @override
  AIState build() {
    return AIState();
  }

  Future<void> askAssistant(String prompt) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final aiService = ref.read(aiServiceProvider);
      
      // We instruct the AI to return a JSON list of movie/series names that match the user's intent.
      final systemPrompt = '''
Sen LOKUM MC (Media Center) uygulamasının yapay zeka destekli içerik asistanısın.
Kullanıcının isteğini analiz et ve bu isteğe en uygun 5 popüler film veya dizinin sadece isimlerini JSON formatında döndür.
Format: {"movies": ["Film 1", "Film 2"], "series": ["Dizi 1", "Dizi 2"]}
Ekstra hiçbir metin veya markdown ekleme, sadece saf JSON döndür.
Kullanıcının İsteği: $prompt
''';

      final responseText = await aiService.askAssistant(systemPrompt);
      
      // Clean up possible markdown blocks like ```json ... ```
      final cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(cleanJson) as Map<String, dynamic>;
      
      final List<String> movieNames = List<String>.from(decoded['movies'] ?? []);
      final List<String> seriesNames = List<String>.from(decoded['series'] ?? []);
      
      final iptvState = ref.read(iptvControllerProvider);
      final allIptvMovies = iptvState.movies;
      final allIptvSeries = iptvState.series;
      
      final List<MatchedMovie> matchedMovies = [];
      final List<MatchedSeries> matchedSeries = [];
      
      // Simplified matching logic for MVP (Ideally we'd search TMDB to get rich posters too)
      for (final mName in movieNames) {
        final cleanMName = mName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        try {
          final match = allIptvMovies.firstWhere((m) {
            final c = m.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            return c.contains(cleanMName) && cleanMName.length > 3;
          });
          // For now create a dummy TMDB movie just to hold the data for UI
          matchedMovies.add(MatchedMovie(
            tmdbMovie: TmdbMovie(id: 0, title: match.name, originalTitle: match.name, overview: '', posterPath: '', backdropPath: '', voteAverage: 0.0, releaseDate: '', genreIds: []),
            streamId: match.streamId,
            streamIcon: match.icon ?? '',
          ));
        } catch (_) {}
      }

      for (final sName in seriesNames) {
        final cleanSName = sName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        try {
          final match = allIptvSeries.firstWhere((s) {
            final c = s.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            return c.contains(cleanSName) && cleanSName.length > 3;
          });
          matchedSeries.add(MatchedSeries(
            tmdbSeries: TmdbSeries(id: 0, name: match.name, originalName: match.name, overview: '', posterPath: '', backdropPath: '', voteAverage: 0.0, firstAirDate: '', genreIds: []),
            seriesId: match.seriesId,
            cover: match.cover ?? '',
          ));
        } catch (_) {}
      }

      state = state.copyWith(
        isLoading: false,
        suggestedMovies: matchedMovies,
        suggestedSeries: matchedSeries,
      );

    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final aiControllerProvider = NotifierProvider<AIController, AIState>(() {
  return AIController();
});
