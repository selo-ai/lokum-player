import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/tmdb_api.dart';
import '../../data/models/iptv_models.dart';
import '../../data/models/tmdb_models.dart';
import 'iptv_controller.dart';

final sportsMatchedMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final iptvMovies = iptvState.movies;

  if (iptvMovies.isEmpty) {
    print('VOD Matcher: IPTV movies list is empty, returning early.');
    return [];
  }

  print('VOD Matcher: Starting TMDB match process. IPTV movies count: ${iptvMovies.length}');

  final tmdbApi = ref.read(tmdbApiProvider);
  // Genre ID 12 is usually Adventure, but wait! TMDB has genres.
  // 28: Action, 12: Adventure, 16: Animation, 35: Comedy, 80: Crime, 99: Documentary, 18: Drama, 10751: Family, 14: Fantasy, 36: History, 27: Horror, 10402: Music, 9648: Mystery, 10749: Romance, 878: Science Fiction, 10770: TV Movie, 53: Thriller, 10752: War, 37: Western.
  // Unfortunately, "Sports" is NOT a main TMDB movie genre. It's often categorized as Drama or Documentary.
  // However, TMDB has Keywords! For example, keyword 6075 is "sports".
  // But wait, the API call is getPopularMoviesByGenre. We might need to adjust it to get movies with specific keywords or just use a popular list.
  // For now, let's use Action (28) as a placeholder for "Sports/Action" or we can update tmdb_api to use with_keywords.

  // 6075 is the TMDB keyword for "sports". Let's fetch 5 pages of popular sports movies.
  print('VOD Matcher: Fetching popular sports movies from TMDB...');
  final List<TmdbMovie> allTmdbMovies = [];
  for (int i = 1; i <= 5; i++) {
    allTmdbMovies.addAll(await tmdbApi.getMoviesByKeyword(6075, page: i));
  }
  print('VOD Matcher: Fetched ${allTmdbMovies.length} sports movies from TMDB.');

  final List<MatchedMovie> matched = [];

  for (final tmdbMovie in allTmdbMovies) {
    // Basic text matching: Clean up names
    final tmdbName = _cleanName(tmdbMovie.title);
    final tmdbOriginal = _cleanName(tmdbMovie.originalTitle);

    // Find in IPTV
    try {
      final match = iptvMovies.firstWhere((iptvMovie) {
        final iptvName = _cleanName(iptvMovie.name);
        // Direct match or contains
        if (iptvName == tmdbName || iptvName == tmdbOriginal) return true;
        if (iptvName.contains(tmdbName) && tmdbName.length > 5) return true;
        return false;
      });

      matched.add(MatchedMovie(
        tmdbMovie: tmdbMovie,
        streamId: match.streamId,
        streamIcon: match.icon ?? '',
      ));
    } catch (_) {
      // Not found
    }
  }

  print('VOD Matcher: Found ${matched.length} matched movies!');
  return matched;
});

final sportsMatchedSeriesProvider = FutureProvider<List<MatchedSeries>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final iptvSeriesList = iptvState.series;

  if (iptvSeriesList.isEmpty) return [];

  print('VOD Matcher: Starting TMDB match process for Sports Series.');

  final tmdbApi = ref.read(tmdbApiProvider);
  print('VOD Matcher: Fetching popular sports series from TMDB...');
  final List<TmdbSeries> allTmdbSeries = [];
  for (int i = 1; i <= 5; i++) {
    allTmdbSeries.addAll(await tmdbApi.getTvShowsByKeyword(6075, page: i)); // 6075 is sports
  }
  print('VOD Matcher: Fetched ${allTmdbSeries.length} sports series from TMDB.');

  final List<MatchedSeries> matched = [];

  for (final tmdbSeries in allTmdbSeries) {
    final tmdbName = _cleanName(tmdbSeries.name);
    final tmdbOriginal = _cleanName(tmdbSeries.originalName);

    try {
      final match = iptvSeriesList.firstWhere((iptvSeries) {
        final iptvName = _cleanName(iptvSeries.name);
        if (iptvName == tmdbName || iptvName == tmdbOriginal) return true;
        if (iptvName.contains(tmdbName) && tmdbName.length > 5) return true;
        return false;
      });

      matched.add(MatchedSeries(
        tmdbSeries: tmdbSeries,
        seriesId: match.seriesId,
        cover: match.cover ?? '',
      ));
    } catch (_) {}
  }

  print('VOD Matcher: Found ${matched.length} matched sports series!');
  return matched;
});

final sportsMatchedOnlyMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) async {
  final movies = await ref.watch(sportsMatchedMoviesProvider.future);
  // Genre 99 is Documentary
  return movies.where((m) => !m.tmdbMovie.genreIds.contains(99)).toList();
});

final sportsMatchedOnlySeriesProvider = FutureProvider<List<MatchedSeries>>((ref) async {
  final series = await ref.watch(sportsMatchedSeriesProvider.future);
  final filteredSeries = series.where((s) => !s.tmdbSeries.genreIds.contains(99)).toList();
  
  // Sort so that non-animated series appear before animated series (genre 16 is Animation)
  filteredSeries.sort((a, b) {
    final aIsAnim = a.tmdbSeries.genreIds.contains(16);
    final bIsAnim = b.tmdbSeries.genreIds.contains(16);
    
    if (aIsAnim && !bIsAnim) return 1;
    if (!aIsAnim && bIsAnim) return -1;
    
    // Fallback: sort by popularity/vote average (assumed already somewhat sorted, so keep 0 or sort by vote)
    return b.tmdbSeries.voteAverage.compareTo(a.tmdbSeries.voteAverage);
  });
  
  return filteredSeries;
});

final sportsMatchedDocumentariesProvider = FutureProvider<List<dynamic>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final tmdbApi = ref.read(tmdbApiProvider);

  // 1. Fetch popular sports documentaries from TMDB
  // Genre 99 = Documentary, Keyword 6075 = Sports
  final List<TmdbMovie> tmdbDocMovies = [];
  for (int i = 1; i <= 3; i++) {
    tmdbDocMovies.addAll(await tmdbApi.getMoviesByGenreAndKeyword(99, 6075, page: i));
  }
  
  final List<TmdbSeries> tmdbDocSeries = [];
  for (int i = 1; i <= 3; i++) {
    tmdbDocSeries.addAll(await tmdbApi.getTvShowsByGenreAndKeyword(99, 6075, page: i));
  }

  // 2. Start with any we already caught in the generic sports matching
  final movies = await ref.watch(sportsMatchedMoviesProvider.future);
  final series = await ref.watch(sportsMatchedSeriesProvider.future);
  
  final existingDocMovies = movies.where((m) => m.tmdbMovie.genreIds.contains(99)).toList();
  final existingDocSeries = series.where((s) => s.tmdbSeries.genreIds.contains(99)).toList();

  final List<dynamic> matched = [];
  matched.addAll(existingDocMovies);
  matched.addAll(existingDocSeries);

  // 3. Match new tmdbDocMovies against ALL iptv movies
  final iptvMovies = iptvState.movies;
  for (final tmdbMovie in tmdbDocMovies) {
    if (matched.any((m) => m is MatchedMovie && m.tmdbMovie.id == tmdbMovie.id)) continue;
    
    final tmdbName = _cleanName(tmdbMovie.title);
    final tmdbOriginal = _cleanName(tmdbMovie.originalTitle);
    
    try {
      final match = iptvMovies.firstWhere((iptvMovie) {
        final iptvName = _cleanName(iptvMovie.name);
        if (iptvName == tmdbName || iptvName == tmdbOriginal) return true;
        if (iptvName.contains(tmdbName) && tmdbName.length > 5) return true;
        return false;
      });
      matched.add(MatchedMovie(tmdbMovie: tmdbMovie, streamId: match.streamId, streamIcon: match.icon ?? ''));
    } catch (_) {}
  }
  
  // 4. Match new tmdbDocSeries against ALL iptv series
  final iptvSeriesList = iptvState.series;
  for (final tmdbSeries in tmdbDocSeries) {
    if (matched.any((m) => m is MatchedSeries && m.tmdbSeries.id == tmdbSeries.id)) continue;
    
    final tmdbName = _cleanName(tmdbSeries.name);
    final tmdbOriginal = _cleanName(tmdbSeries.originalName);
    
    try {
      final match = iptvSeriesList.firstWhere((iptvSeries) {
        final iptvName = _cleanName(iptvSeries.name);
        if (iptvName == tmdbName || iptvName == tmdbOriginal) return true;
        if (iptvName.contains(tmdbName) && tmdbName.length > 5) return true;
        return false;
      });
      matched.add(MatchedSeries(tmdbSeries: tmdbSeries, seriesId: match.seriesId, cover: match.cover ?? ''));
    } catch (_) {}
  }

  // 5. Explicitly look for "belgesel" or "documentary" in ALL IPTV movies and create fake TMDB items if needed?
  // We'll just rely on the above matching for now, but also match raw names.
  for (final iptvMovie in iptvMovies) {
    final nameLower = iptvMovie.name.toLowerCase();
    if (nameLower.contains('ronaldinho') || nameLower.contains('last dance') || nameLower.contains('beckham')) {
       // if not already matched
       if (!matched.any((m) => m is MatchedMovie && m.streamId == iptvMovie.streamId)) {
          // You could add a raw item here, but UI expects MatchedMovie.
          // The API fetch of Genre+Keyword should catch most of them.
       }
    }
  }

  print('VOD Matcher: Found ${matched.length} matched sports documentaries!');
  return matched;
});

final horrorMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final iptvMovies = iptvState.movies;

  if (iptvMovies.isEmpty) return [];

  print('VOD Matcher: Starting TMDB match process for Horror Movies.');

  final tmdbApi = ref.read(tmdbApiProvider);
  // 3358 is the TMDB keyword for "horror" (or we can use genre 27 for horror movies).
  // Let's use genre 27 for horror movies.
  print('VOD Matcher: Fetching popular horror movies from TMDB...');
  final List<TmdbMovie> allTmdbMovies = [];
  for (int i = 1; i <= 5; i++) {
    allTmdbMovies.addAll(await tmdbApi.getPopularMoviesByGenre(27, page: i));
  }
  print('VOD Matcher: Fetched ${allTmdbMovies.length} horror movies from TMDB.');

  final List<MatchedMovie> matched = [];

  for (final tmdbMovie in allTmdbMovies) {
    final tmdbName = _cleanName(tmdbMovie.title);
    final tmdbOriginal = _cleanName(tmdbMovie.originalTitle);

    try {
      final match = iptvMovies.firstWhere((iptvMovie) {
        final iptvName = _cleanName(iptvMovie.name);
        if (iptvName == tmdbName || iptvName == tmdbOriginal) return true;
        if (iptvName.contains(tmdbName) && tmdbName.length > 5) return true;
        return false;
      });

      matched.add(MatchedMovie(
        tmdbMovie: tmdbMovie,
        streamId: match.streamId,
        streamIcon: match.icon ?? '',
      ));
    } catch (_) {}
  }

  print('VOD Matcher: Found ${matched.length} matched horror movies!');
  return matched;
});

final horrorSeriesProvider = FutureProvider<List<MatchedSeries>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final iptvSeriesList = iptvState.series;

  if (iptvSeriesList.isEmpty) return [];

  print('VOD Matcher: Starting TMDB match process for Horror Series.');

  final tmdbApi = ref.read(tmdbApiProvider);
  // TV Horror genre doesn't exist directly in discover sometimes, but keyword 3358 (horror) is good.
  print('VOD Matcher: Fetching popular horror series from TMDB...');
  final List<TmdbSeries> allTmdbSeries = [];
  for (int i = 1; i <= 5; i++) {
    allTmdbSeries.addAll(await tmdbApi.getTvShowsByKeyword(3358, page: i));
  }
  print('VOD Matcher: Fetched ${allTmdbSeries.length} horror series from TMDB.');

  final List<MatchedSeries> matched = [];

  for (final tmdbSeries in allTmdbSeries) {
    final tmdbName = _cleanName(tmdbSeries.name);
    final tmdbOriginal = _cleanName(tmdbSeries.originalName);

    try {
      final match = iptvSeriesList.firstWhere((iptvSeries) {
        final iptvName = _cleanName(iptvSeries.name);
        if (iptvName == tmdbName || iptvName == tmdbOriginal) return true;
        if (iptvName.contains(tmdbName) && tmdbName.length > 5) return true;
        return false;
      });

      matched.add(MatchedSeries(
        tmdbSeries: tmdbSeries,
        seriesId: match.seriesId,
        cover: match.cover ?? '',
      ));
    } catch (_) {}
  }

  print('VOD Matcher: Found ${matched.length} matched horror series!');
  return matched;
});

final comedyMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final iptvMovies = iptvState.movies;

  if (iptvMovies.isEmpty) return [];

  print('VOD Matcher: Starting TMDB match process for Comedy Movies.');

  final tmdbApi = ref.read(tmdbApiProvider);
  // Genre 35 is Comedy
  print('VOD Matcher: Fetching popular comedy movies from TMDB...');
  final List<TmdbMovie> allTmdbMovies = [];
  for (int i = 1; i <= 5; i++) {
    allTmdbMovies.addAll(await tmdbApi.getPopularMoviesByGenre(35, page: i));
  }

  final List<MatchedMovie> matched = [];

  for (final tmdbMovie in allTmdbMovies) {
    final tmdbName = _cleanName(tmdbMovie.title);
    final tmdbOriginal = _cleanName(tmdbMovie.originalTitle);

    try {
      final match = iptvMovies.firstWhere((iptvMovie) {
        final iptvName = _cleanName(iptvMovie.name);
        if (iptvName == tmdbName || iptvName == tmdbOriginal) return true;
        if (iptvName.contains(tmdbName) && tmdbName.length > 5) return true;
        return false;
      });

      matched.add(MatchedMovie(
        tmdbMovie: tmdbMovie,
        streamId: match.streamId,
        streamIcon: match.icon ?? '',
      ));
    } catch (_) {}
  }

  print('VOD Matcher: Found ${matched.length} matched comedy movies!');
  return matched;
});

final comedySeriesProvider = FutureProvider<List<MatchedSeries>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final iptvSeriesList = iptvState.series;

  if (iptvSeriesList.isEmpty) return [];

  print('VOD Matcher: Starting TMDB match process for Comedy Series.');

  final tmdbApi = ref.read(tmdbApiProvider);
  print('VOD Matcher: Fetching popular comedy series from TMDB...');
  final List<TmdbSeries> allTmdbSeries = [];
  for (int i = 1; i <= 5; i++) {
    allTmdbSeries.addAll(await tmdbApi.getPopularTvShowsByGenre(35, page: i));
  }

  final List<MatchedSeries> matched = [];

  for (final tmdbSeries in allTmdbSeries) {
    final tmdbName = _cleanName(tmdbSeries.name);
    final tmdbOriginal = _cleanName(tmdbSeries.originalName);

    try {
      final match = iptvSeriesList.firstWhere((iptvSeries) {
        final iptvName = _cleanName(iptvSeries.name);
        if (iptvName == tmdbName || iptvName == tmdbOriginal) return true;
        if (iptvName.contains(tmdbName) && tmdbName.length > 5) return true;
        return false;
      });

      matched.add(MatchedSeries(
        tmdbSeries: tmdbSeries,
        seriesId: match.seriesId,
        cover: match.cover ?? '',
      ));
    } catch (_) {}
  }

  print('VOD Matcher: Found ${matched.length} matched comedy series!');
  return matched;
});

String _cleanName(String input) {
  // Remove years, resolutions, audio tags, TR DUBLAJ, etc.
  String name = input.toLowerCase();
  name = name.replaceAll(RegExp(r'\(\d{4}\)'), ''); // (2023)
  name = name.replaceAll(RegExp(r'\b(1080p|720p|4k|uhd|fhd)\b', caseSensitive: false), '');
  name = name.replaceAll(RegExp(r'\b(tr dublaj|tr altyazı|dublaj|altyazı|tr|tr-en)\b', caseSensitive: false), '');
  // Remove special characters
  name = name.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  // Multiple spaces to single
  name = name.replaceAll(RegExp(r'\s+'), ' ');
  return name.trim();
}
