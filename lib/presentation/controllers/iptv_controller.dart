import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/iptv_models.dart';
import 'auth_controller.dart';
import 'providers.dart';

class IptvState {
  final bool isLoading;
  final String? errorMessage;
  
  // Categorized content
  final List<IptvCategory> liveCategories;
  final List<IptvCategory> movieCategories;
  final List<IptvCategory> seriesCategories;
  
  // Capped or raw lists
  final List<IptvLiveChannel> liveChannels;
  final List<IptvMovie> movies;
  final List<IptvSeries> series;

  // Favorites
  final List<IptvLiveChannel> favoriteLive;
  final List<IptvMovie> favoriteMovies;
  final List<IptvSeries> favoriteSeries;

  // Active UI filters
  final String selectedLiveCategoryId;
  final String selectedMovieCategoryId;
  final String selectedSeriesCategoryId;
  final String searchQuery;

  // EPG Cache for Live Channels
  final Map<int, EpgProgram?> epgCache;

  IptvState({
    required this.isLoading,
    this.errorMessage,
    required this.liveCategories,
    required this.movieCategories,
    required this.seriesCategories,
    required this.liveChannels,
    required this.movies,
    required this.series,
    required this.favoriteLive,
    required this.favoriteMovies,
    required this.favoriteSeries,
    required this.selectedLiveCategoryId,
    required this.selectedMovieCategoryId,
    required this.selectedSeriesCategoryId,
    required this.searchQuery,
    required this.epgCache,
  });

  factory IptvState.initial() => IptvState(
    isLoading: false,
    errorMessage: null,
    liveCategories: [],
    movieCategories: [],
    seriesCategories: [],
    liveChannels: [],
    movies: [],
    series: [],
    favoriteLive: [],
    favoriteMovies: [],
    favoriteSeries: [],
    selectedLiveCategoryId: '',
    selectedMovieCategoryId: '',
    selectedSeriesCategoryId: '',
    searchQuery: '',
    epgCache: const {},
  );

  IptvState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<IptvCategory>? liveCategories,
    List<IptvCategory>? movieCategories,
    List<IptvCategory>? seriesCategories,
    List<IptvLiveChannel>? liveChannels,
    List<IptvMovie>? movies,
    List<IptvSeries>? series,
    List<IptvLiveChannel>? favoriteLive,
    List<IptvMovie>? favoriteMovies,
    List<IptvSeries>? favoriteSeries,
    String? selectedLiveCategoryId,
    String? selectedMovieCategoryId,
    String? selectedSeriesCategoryId,
    String? searchQuery,
    Map<int, EpgProgram?>? epgCache,
  }) {
    return IptvState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      liveCategories: liveCategories ?? this.liveCategories,
      movieCategories: movieCategories ?? this.movieCategories,
      seriesCategories: seriesCategories ?? this.seriesCategories,
      liveChannels: liveChannels ?? this.liveChannels,
      movies: movies ?? this.movies,
      series: series ?? this.series,
      favoriteLive: favoriteLive ?? this.favoriteLive,
      favoriteMovies: favoriteMovies ?? this.favoriteMovies,
      favoriteSeries: favoriteSeries ?? this.favoriteSeries,
      selectedLiveCategoryId: selectedLiveCategoryId ?? this.selectedLiveCategoryId,
      selectedMovieCategoryId: selectedMovieCategoryId ?? this.selectedMovieCategoryId,
      selectedSeriesCategoryId: selectedSeriesCategoryId ?? this.selectedSeriesCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      epgCache: epgCache ?? this.epgCache,
    );
  }
}

class IptvController extends Notifier<IptvState> {
  @override
  IptvState build() {
    // Listen to authentication changes
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        loadAllContent();
      } else if (next.status == AuthStatus.unauthenticated) {
        state = IptvState.initial();
      }
    });
    return IptvState.initial();
  }

  // --- Load All Data ---
  Future<void> loadAllContent() async {
    final creds = ref.read(authControllerProvider).credentials;
    if (creds == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final api = ref.read(iptvApiProvider);
    final storage = ref.read(localStorageProvider);

    try {
      // 1. Fetch Categories
      final rawLiveCats = await api.getCategories(creds, 'live');
      final rawMovieCats = await api.getCategories(creds, 'movie');
      final rawSeriesCats = await api.getCategories(creds, 'series');

      final liveCats = [
        IptvCategory(id: '', name: 'Tümü', type: 'live'),
        ...rawLiveCats,
      ];
      final movieCats = [
        IptvCategory(id: '', name: 'Tümü', type: 'movie'),
        ...rawMovieCats,
      ];
      final seriesCats = [
        IptvCategory(id: '', name: 'Tümü', type: 'series'),
        ...rawSeriesCats,
      ];



      // 2. Fetch All Channels/Movies/Series
      final channels = await api.getLiveChannels(creds);
      final movies = await api.getMovies(creds);
      final series = await api.getSeries(creds);

      // 3. Load Favorites
      final favoriteLiveIds = storage.getFavoriteLiveIds();
      final favoriteMovieIds = storage.getFavoriteMovieIds();
      final favoriteSeriesIds = storage.getFavoriteSeriesIds();

      final favLive = channels.where((c) => favoriteLiveIds.contains(c.streamId)).toList();
      final favMovies = movies.where((m) => favoriteMovieIds.contains(m.streamId)).toList();
      final favSeries = series.where((s) => favoriteSeriesIds.contains(s.seriesId)).toList();

      state = state.copyWith(
        isLoading: false,
        liveCategories: liveCats,
        movieCategories: movieCats,
        seriesCategories: seriesCats,
        liveChannels: channels,
        movies: movies,
        series: series,
        favoriteLive: favLive,
        favoriteMovies: favMovies,
        favoriteSeries: favSeries,
        selectedLiveCategoryId: '',
        selectedMovieCategoryId: '',
        selectedSeriesCategoryId: '',
      );
    } catch (e, stack) {
      print('IPTV Controller Error: loadAllContent exception: $e');
      print(stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'İçerik yüklenirken hata oluştu: ${e.toString()}',
      );
    }
  }

  // --- Filter Selectors ---
  void selectLiveCategory(String catId) {
    state = state.copyWith(selectedLiveCategoryId: catId);
  }

  void selectMovieCategory(String catId) {
    state = state.copyWith(selectedMovieCategoryId: catId);
  }

  void selectSeriesCategory(String catId) {
    state = state.copyWith(selectedSeriesCategoryId: catId);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // --- Favorites Management ---
  Future<void> toggleFavoriteLive(IptvLiveChannel channel) async {
    final storage = ref.read(localStorageProvider);
    await storage.toggleFavoriteLive(channel.streamId);
    
    final favIds = storage.getFavoriteLiveIds();
    final updatedFavs = state.liveChannels.where((c) => favIds.contains(c.streamId)).toList();
    
    state = state.copyWith(favoriteLive: updatedFavs);
  }

  Future<void> toggleFavoriteMovie(IptvMovie movie) async {
    final storage = ref.read(localStorageProvider);
    await storage.toggleFavoriteMovie(movie.streamId);

    final favIds = storage.getFavoriteMovieIds();
    final updatedFavs = state.movies.where((m) => favIds.contains(m.streamId)).toList();

    state = state.copyWith(favoriteMovies: updatedFavs);
  }

  Future<void> toggleFavoriteSeries(IptvSeries serie) async {
    final storage = ref.read(localStorageProvider);
    await storage.toggleFavoriteSeries(serie.seriesId);

    final favIds = storage.getFavoriteSeriesIds();
    final updatedFavs = state.series.where((s) => favIds.contains(s.seriesId)).toList();

    state = state.copyWith(favoriteSeries: updatedFavs);
  }

  // --- Episode Fetcher (on Demand) ---
  Future<List<IptvEpisode>> getEpisodesForSeries(int seriesId) async {
    final creds = ref.read(authControllerProvider).credentials;
    if (creds == null) return [];
    
    final api = ref.read(iptvApiProvider);
    return await api.getSeriesEpisodes(creds, seriesId);
  }

  // --- EPG Fetcher (on Demand) ---
  Future<List<EpgProgram>> getShortEpg(int streamId) async {
    final creds = ref.read(authControllerProvider).credentials;
    if (creds == null) return [];

    final api = ref.read(iptvApiProvider);
    return await api.getShortEpg(creds, streamId);
  }

  // --- Async EPG Fetcher & Cache ---
  Future<void> fetchEpgForChannel(int streamId) async {
    // If already in cache (either loading, loaded, or null/error), skip to avoid double loading
    if (state.epgCache.containsKey(streamId)) return;

    // Mark as null first so we don't fetch again while waiting
    final updatedCache = Map<int, EpgProgram?>.from(state.epgCache);
    updatedCache[streamId] = null;
    state = state.copyWith(epgCache: updatedCache);

    try {
      final creds = ref.read(authControllerProvider).credentials;
      if (creds == null) return;
      
      final api = ref.read(iptvApiProvider);
      final list = await api.getShortEpg(creds, streamId);
      
      EpgProgram? nowProgram;
      try {
        nowProgram = list.firstWhere((epg) => epg.isNow);
      } catch (_) {
        // No program currently running
      }

      final finalCache = Map<int, EpgProgram?>.from(state.epgCache);
      if (nowProgram != null && nowProgram.title.isNotEmpty) {
        finalCache[streamId] = nowProgram;
      } else {
        // Placeholder indicating no EPG data found so we don't request it again
        finalCache[streamId] = EpgProgram(
          title: 'EPG Yok',
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(hours: 1)),
        );
      }
      state = state.copyWith(epgCache: finalCache);
    } catch (e) {
      // Keep it as null to allow retries or mark as placeholder
    }
  }

  // --- Watch History ---
  Future<void> saveToWatchHistory({
    required String type,
    required int id,
    required String name,
    String? icon,
    String? extra,
  }) async {
    final storage = ref.read(localStorageProvider);
    await storage.addToHistory(type: type, id: id, name: name, icon: icon, extra: extra);
  }

  List<Map<String, dynamic>> getHistory() {
    final storage = ref.read(localStorageProvider);
    return storage.getHistory();
  }

  // --- Getters for Filtered Lists (UI friendly) ---
  List<IptvLiveChannel> getFilteredLiveChannels() {
    final query = state.searchQuery.toLowerCase();
    final catId = state.selectedLiveCategoryId;
    return state.liveChannels.where((c) {
      final matchesCategory = catId.isEmpty || c.categoryId == catId;
      final matchesSearch = query.isEmpty || c.name.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<IptvMovie> getFilteredMovies() {
    final query = state.searchQuery.toLowerCase();
    final catId = state.selectedMovieCategoryId;
    return state.movies.where((m) {
      final matchesCategory = catId.isEmpty || m.categoryId == catId;
      final matchesSearch = query.isEmpty || m.name.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<IptvSeries> getFilteredSeries() {
    final query = state.searchQuery.toLowerCase();
    final catId = state.selectedSeriesCategoryId;
    return state.series.where((s) {
      final matchesCategory = catId.isEmpty || s.categoryId == catId;
      final matchesSearch = query.isEmpty || s.name.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }
}

final iptvControllerProvider = NotifierProvider<IptvController, IptvState>(() {
  return IptvController();
});
