import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/tmdb_api.dart';
import '../../data/models/iptv_models.dart';
import '../../data/models/tmdb_models.dart';
import '../../core/utils/asian_content_filter.dart';
import 'iptv_controller.dart';
import 'language_provider.dart';

final trendingMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final iptvMovies = iptvState.movies.where((m) => !AsianContentFilter.isAsianContent(m.name)).toList();

  if (iptvMovies.isEmpty) return [];

  final tmdbApi = ref.read(tmdbApiProvider);
  final List<TmdbMovie> trendingTmdb = await tmdbApi.getTrendingMovies();

  final List<MatchedMovie> matched = [];

  for (final tmdbMovie in trendingTmdb) {
    if (tmdbMovie.backdropPath.isEmpty) continue; // Carousel needs backdrops
    final tmdbName = _cleanName(tmdbMovie.title);
    final tmdbOriginal = _cleanName(tmdbMovie.originalTitle);

    try {
      final match = iptvMovies.firstWhere((iptvMovie) {
        final iptvName = _cleanName(iptvMovie.name);
        if (iptvName == tmdbName || iptvName == tmdbOriginal) return true;
        if (iptvName.contains(tmdbName) && tmdbName.length > 5) return true;
        return false;
      });

      // Avoid duplicates
      if (!matched.any((m) => m.streamId == match.streamId)) {
        matched.add(MatchedMovie(
          tmdbMovie: tmdbMovie,
          streamId: match.streamId,
          streamIcon: match.icon ?? '',
        ));
      }
    } catch (_) {}
  }
  final appLang = ref.watch(languageProvider);
  matched.sort((a, b) {
    final aLang = a.tmdbMovie.originalLanguage;
    final bLang = b.tmdbMovie.originalLanguage;
    if (aLang == appLang && bLang != appLang) return -1;
    if (aLang != appLang && bLang == appLang) return 1;
    return 0;
  });
  return matched;
});

final trendingSeriesProvider = FutureProvider<List<MatchedSeries>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final iptvSeriesList = iptvState.series.where((s) => !AsianContentFilter.isAsianContent(s.name)).toList();

  if (iptvSeriesList.isEmpty) return [];

  final tmdbApi = ref.read(tmdbApiProvider);
  final List<TmdbSeries> trendingTmdb = await tmdbApi.getTrendingTvShows();

  final List<MatchedSeries> matched = [];

  for (final tmdbSeries in trendingTmdb) {
    if (tmdbSeries.backdropPath.isEmpty) continue;
    final tmdbName = _cleanName(tmdbSeries.name);
    final tmdbOriginal = _cleanName(tmdbSeries.originalName);

    try {
      final match = iptvSeriesList.firstWhere((iptvSeries) {
        final iptvName = _cleanName(iptvSeries.name);
        if (iptvName == tmdbName || iptvName == tmdbOriginal) return true;
        if (iptvName.contains(tmdbName) && tmdbName.length > 5) return true;
        return false;
      });

      // Avoid duplicates
      if (!matched.any((m) => m.seriesId == match.seriesId)) {
        matched.add(MatchedSeries(
          tmdbSeries: tmdbSeries,
          seriesId: match.seriesId,
          cover: match.cover ?? '',
        ));
      }
    } catch (_) {}
  }
  final appLang = ref.watch(languageProvider);
  matched.sort((a, b) {
    final aLang = a.tmdbSeries.originalLanguage;
    final bLang = b.tmdbSeries.originalLanguage;
    if (aLang == appLang && bLang != appLang) return -1;
    if (aLang != appLang && bLang == appLang) return 1;
    return 0;
  });
  return matched;
});

final trendingDocumentariesProvider = FutureProvider<List<CarouselMedia>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final tmdbApi = ref.read(tmdbApiProvider);
  final List<CarouselMedia> matchedDocs = [];

  final filteredMovies = iptvState.movies.where((m) => !AsianContentFilter.isAsianContent(m.name)).toList();
  if (filteredMovies.isNotEmpty) {
    final movieDocs = await tmdbApi.getPopularMoviesByGenre(99);
    for (final tmdbMovie in movieDocs) {
      if (tmdbMovie.backdropPath.isEmpty) continue;
      final tmdbName = _cleanName(tmdbMovie.title);
      final tmdbOriginal = _cleanName(tmdbMovie.originalTitle);
      try {
        final match = filteredMovies.firstWhere((m) {
          final iptvName = _cleanName(m.name);
          return iptvName == tmdbName || iptvName == tmdbOriginal || (iptvName.contains(tmdbName) && tmdbName.length > 5);
        });
        if (!matchedDocs.any((m) => m.streamId == match.streamId && m.isMovie)) {
          matchedDocs.add(CarouselMedia(isMovie: true, tmdbData: tmdbMovie, streamId: match.streamId, coverOrIcon: match.icon ?? ''));
        }
      } catch (_) {}
    }
  }

  final filteredSeries = iptvState.series.where((s) => !AsianContentFilter.isAsianContent(s.name)).toList();
  if (filteredSeries.isNotEmpty) {
    final seriesDocs = await tmdbApi.getPopularTvShowsByGenre(99);
    for (final tmdbSeries in seriesDocs) {
      if (tmdbSeries.backdropPath.isEmpty) continue;
      final tmdbName = _cleanName(tmdbSeries.name);
      final tmdbOriginal = _cleanName(tmdbSeries.originalName);
      try {
        final match = filteredSeries.firstWhere((s) {
          final iptvName = _cleanName(s.name);
          return iptvName == tmdbName || iptvName == tmdbOriginal || (iptvName.contains(tmdbName) && tmdbName.length > 5);
        });
        if (!matchedDocs.any((m) => m.streamId == match.seriesId && !m.isMovie)) {
          matchedDocs.add(CarouselMedia(isMovie: false, tmdbData: tmdbSeries, streamId: match.seriesId, coverOrIcon: match.cover ?? ''));
        }
      } catch (_) {}
    }
  }

  matchedDocs.shuffle();
  return matchedDocs;
});

final mixedCarouselProvider = FutureProvider<List<CarouselMedia>>((ref) async {
  final moviesAsync = await ref.watch(trendingMoviesProvider.future);
  final seriesAsync = await ref.watch(trendingSeriesProvider.future);
  final docsAsync = await ref.watch(trendingDocumentariesProvider.future);

  final List<CarouselMedia> mixed = [];
  
  for (final m in moviesAsync) {
    mixed.add(CarouselMedia(isMovie: true, tmdbData: m.tmdbMovie, streamId: m.streamId, coverOrIcon: m.streamIcon));
  }

  for (final s in seriesAsync) {
    mixed.add(CarouselMedia(isMovie: false, tmdbData: s.tmdbSeries, streamId: s.seriesId, coverOrIcon: s.cover));
  }

  mixed.addAll(docsAsync);

  mixed.shuffle();
  return mixed.take(10).toList();
});



final sportsMatchedMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final iptvMovies = iptvState.movies.where((m) => !AsianContentFilter.isAsianContent(m.name)).toList();

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
  final iptvSeriesList = iptvState.series.where((s) => !AsianContentFilter.isAsianContent(s.name)).toList();

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
  final iptvMovies = iptvState.movies.where((m) => !AsianContentFilter.isAsianContent(m.name)).toList();
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
  final iptvSeriesList = iptvState.series.where((s) => !AsianContentFilter.isAsianContent(s.name)).toList();
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
  final iptvMovies = iptvState.movies.where((m) => !AsianContentFilter.isAsianContent(m.name)).toList();

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
  final iptvSeriesList = iptvState.series.where((s) => !AsianContentFilter.isAsianContent(s.name)).toList();

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
  final iptvMovies = iptvState.movies.where((m) => !AsianContentFilter.isAsianContent(m.name)).toList();

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
  final iptvSeriesList = iptvState.series.where((s) => !AsianContentFilter.isAsianContent(s.name)).toList();

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

// Helper for Movies
Future<List<MatchedMovie>> _matchMoviesHelper(Ref ref, Future<List<TmdbMovie>> Function(int) fetchPage) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final filteredMovies = iptvState.movies.where((m) => !AsianContentFilter.isAsianContent(m.name)).toList();
  if (filteredMovies.isEmpty) return [];
  final List<TmdbMovie> allTmdbMovies = [];
  for (int i = 1; i <= 5; i++) {
    allTmdbMovies.addAll(await fetchPage(i));
  }
  final List<MatchedMovie> matched = [];
  for (final tmdbMovie in allTmdbMovies) {
    final tmdbName = _cleanName(tmdbMovie.title);
    final tmdbOriginal = _cleanName(tmdbMovie.originalTitle);
    try {
      final match = filteredMovies.firstWhere((iptvMovie) {
        final iptvName = _cleanName(iptvMovie.name);
        return iptvName == tmdbName || iptvName == tmdbOriginal || (iptvName.contains(tmdbName) && tmdbName.length > 5);
      });
      matched.add(MatchedMovie(tmdbMovie: tmdbMovie, streamId: match.streamId, streamIcon: match.icon ?? ''));
    } catch (_) {}
  }
  final appLang = ref.watch(languageProvider);
  matched.sort((a, b) {
    final aLang = a.tmdbMovie.originalLanguage;
    final bLang = b.tmdbMovie.originalLanguage;
    if (aLang == appLang && bLang != appLang) return -1;
    if (aLang != appLang && bLang == appLang) return 1;
    return 0;
  });
  return matched;
}

// Helper for Series
Future<List<MatchedSeries>> _matchSeriesHelper(Ref ref, Future<List<TmdbSeries>> Function(int) fetchPage) async {
  final iptvState = ref.watch(iptvControllerProvider);
  final filteredSeries = iptvState.series.where((s) => !AsianContentFilter.isAsianContent(s.name)).toList();
  if (filteredSeries.isEmpty) return [];
  final List<TmdbSeries> allTmdbSeries = [];
  for (int i = 1; i <= 5; i++) {
    allTmdbSeries.addAll(await fetchPage(i));
  }
  final List<MatchedSeries> matched = [];
  for (final tmdbSeries in allTmdbSeries) {
    final tmdbName = _cleanName(tmdbSeries.name);
    final tmdbOriginal = _cleanName(tmdbSeries.originalName);
    try {
      final match = filteredSeries.firstWhere((iptvSeries) {
        final iptvName = _cleanName(iptvSeries.name);
        return iptvName == tmdbName || iptvName == tmdbOriginal || (iptvName.contains(tmdbName) && tmdbName.length > 5);
      });
      matched.add(MatchedSeries(tmdbSeries: tmdbSeries, seriesId: match.seriesId, cover: match.cover ?? ''));
    } catch (_) {}
  }
  final appLang = ref.watch(languageProvider);
  matched.sort((a, b) {
    final aLang = a.tmdbSeries.originalLanguage;
    final bLang = b.tmdbSeries.originalLanguage;
    if (aLang == appLang && bLang != appLang) return -1;
    if (aLang != appLang && bLang == appLang) return 1;
    return 0;
  });
  return matched;
}

// NEW MOVIE & SERIES PROVIDERS
final kidsMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) {
  return _matchMoviesHelper(ref, (page) => ref.read(tmdbApiProvider).getPopularMoviesByGenre(10751, page: page));
});
final kidsSeriesProvider = FutureProvider<List<MatchedSeries>>((ref) {
  return _matchSeriesHelper(ref, (page) => ref.read(tmdbApiProvider).getPopularTvShowsByGenre(10762, page: page));
});

final scifiMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) {
  return _matchMoviesHelper(ref, (page) => ref.read(tmdbApiProvider).getPopularMoviesByGenre(878, page: page));
});
final scifiSeriesProvider = FutureProvider<List<MatchedSeries>>((ref) {
  return _matchSeriesHelper(ref, (page) => ref.read(tmdbApiProvider).getPopularTvShowsByGenre(10765, page: page));
});

final actionMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) {
  return _matchMoviesHelper(ref, (page) => ref.read(tmdbApiProvider).getPopularMoviesByGenre(28, page: page));
});
final actionSeriesProvider = FutureProvider<List<MatchedSeries>>((ref) {
  return _matchSeriesHelper(ref, (page) => ref.read(tmdbApiProvider).getPopularTvShowsByGenre(10759, page: page));
});

final nostalgiaMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) {
  return _matchMoviesHelper(ref, (page) => ref.read(tmdbApiProvider).getClassicMovies(page: page));
});

final docsChannelsProvider = Provider<List<IptvLiveChannel>>((ref) {
  final channels = ref.watch(iptvControllerProvider).liveChannels;
  return channels.where((c) {
    final lower = c.name.toLowerCase();
    return lower.contains('belgesel') || lower.contains('docu') || lower.contains('nat geo') || lower.contains('discovery');
  }).toList();
});

final docsMoviesProvider = FutureProvider<List<MatchedMovie>>((ref) {
  return _matchMoviesHelper(ref, (page) => ref.read(tmdbApiProvider).getPopularMoviesByGenre(99, page: page));
});

final docsSeriesProvider = FutureProvider<List<MatchedSeries>>((ref) {
  return _matchSeriesHelper(ref, (page) => ref.read(tmdbApiProvider).getPopularTvShowsByGenre(99, page: page));
});
final nostalgiaSeriesProvider = FutureProvider<List<MatchedSeries>>((ref) {
  return _matchSeriesHelper(ref, (page) => ref.read(tmdbApiProvider).getClassicSeries(page: page));
});

// LIVE TV PROVIDERS
List<IptvLiveChannel> _filterLiveChannels(Ref ref, List<String> keywords) {
  final iptvState = ref.watch(iptvControllerProvider);
  if (iptvState.liveChannels.isEmpty) return [];

  final matchedCategories = iptvState.liveCategories.where((c) {
    final name = c.name.toLowerCase();
    return keywords.any((kw) => name.contains(kw));
  }).map((c) => c.id).toSet();

  var filtered = iptvState.liveChannels.where((channel) {
    if (matchedCategories.contains(channel.categoryId)) return true;
    final chName = channel.name.toLowerCase();
    return keywords.any((kw) => chName.contains(kw));
  }).toList();

  final notifier = ref.read(iptvControllerProvider.notifier);
  filtered.sort((a, b) {
    int usageA = notifier.getLiveUsage(a.streamId);
    int usageB = notifier.getLiveUsage(b.streamId);
    if (usageA != usageB) {
      return usageB.compareTo(usageA);
    }
    return a.name.compareTo(b.name);
  });

  return filtered.take(20).toList();
}

final sportsChannelsProvider = Provider<List<IptvLiveChannel>>((ref) {
  return _filterLiveChannels(ref, ['spor', 'sport', 'bein', 'match', 'maç']);
});
final kidsChannelsProvider = Provider<List<IptvLiveChannel>>((ref) {
  return _filterLiveChannels(ref, ['çocuk', 'kid', 'aile', 'cartoon', 'çizgi']);
});
final horrorChannelsProvider = Provider<List<IptvLiveChannel>>((ref) {
  return _filterLiveChannels(ref, ['korku', 'horror', 'thriller', 'gerilim']);
});
final comedyChannelsProvider = Provider<List<IptvLiveChannel>>((ref) {
  return _filterLiveChannels(ref, ['komedi', 'comedy', 'gülme', 'eğlence']);
});
final actionChannelsProvider = Provider<List<IptvLiveChannel>>((ref) {
  return _filterLiveChannels(ref, ['aksiyon', 'action', 'macera', 'adventure', 'sinema']);
});
final scifiChannelsProvider = Provider<List<IptvLiveChannel>>((ref) {
  return _filterLiveChannels(ref, ['bilim', 'sci-fi', 'uzay', 'fantastik', 'fantasy', 'sinema']);
});
final nostalgiaChannelsProvider = Provider<List<IptvLiveChannel>>((ref) {
  return _filterLiveChannels(ref, ['nostalji', 'eski', 'yeşilçam', 'klasik', 'classic', 'tarih']);
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
