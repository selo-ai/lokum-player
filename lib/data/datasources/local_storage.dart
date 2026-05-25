import 'package:hive_flutter/hive_flutter.dart';
import '../models/iptv_models.dart';

class LocalStorage {
  static const String _boxName = 'iptv_storage_box';
  static const String _keyCredentials = 'credentials';
  static const String _keyFavoritesLive = 'favorites_live';
  static const String _keyFavoritesMovie = 'favorites_movie';
  static const String _keyFavoritesSeries = 'favorites_series';
  static const String _keyHistory = 'history';
  static const String _keyLanguage = 'app_language';
  static const String _keyEpgEnabled = 'epg_enabled';
  static const String _keyRecentCount = 'recent_items_count';
  static const String _keyLastUpdated = 'last_updated';
  static const String _keyLiveUsageCount = 'live_usage_count';

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // --- Last Updated ---
  Future<void> saveLastUpdated(DateTime time) async {
    await _box.put(_keyLastUpdated, time.millisecondsSinceEpoch);
  }

  DateTime? getLastUpdated() {
    final raw = _box.get(_keyLastUpdated);
    if (raw == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw);
  }



  // --- Credentials ---
  Future<void> saveCredentials(IptvCredentials creds) async {
    await _box.put(_keyCredentials, creds.toJson());
  }

  IptvCredentials? getCredentials() {
    final raw = _box.get(_keyCredentials);
    if (raw == null) return null;
    return IptvCredentials.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> clearCredentials() async {
    await _box.delete(_keyCredentials);
    await _box.delete(_keyFavoritesLive);
    await _box.delete(_keyFavoritesMovie);
    await _box.delete(_keyFavoritesSeries);
    await _box.delete(_keyHistory);
  }

  // --- Favorites: Live Channels ---
  List<int> getFavoriteLiveIds() {
    final list = _box.get(_keyFavoritesLive);
    if (list == null) return [];
    return List<int>.from(list);
  }

  Future<void> toggleFavoriteLive(int streamId) async {
    final list = getFavoriteLiveIds();
    if (list.contains(streamId)) {
      list.remove(streamId);
    } else {
      list.add(streamId);
    }
    await _box.put(_keyFavoritesLive, list);
  }

  bool isFavoriteLive(int streamId) {
    return getFavoriteLiveIds().contains(streamId);
  }

  // --- Favorites: Movies ---
  List<int> getFavoriteMovieIds() {
    final list = _box.get(_keyFavoritesMovie);
    if (list == null) return [];
    return List<int>.from(list);
  }

  Future<void> toggleFavoriteMovie(int streamId) async {
    final list = getFavoriteMovieIds();
    if (list.contains(streamId)) {
      list.remove(streamId);
    } else {
      list.add(streamId);
    }
    await _box.put(_keyFavoritesMovie, list);
  }

  bool isFavoriteMovie(int streamId) {
    return getFavoriteMovieIds().contains(streamId);
  }

  // --- Favorites: Series ---
  List<int> getFavoriteSeriesIds() {
    final list = _box.get(_keyFavoritesSeries);
    if (list == null) return [];
    return List<int>.from(list);
  }

  Future<void> toggleFavoriteSeries(int seriesId) async {
    final list = getFavoriteSeriesIds();
    if (list.contains(seriesId)) {
      list.remove(seriesId);
    } else {
      list.add(seriesId);
    }
    await _box.put(_keyFavoritesSeries, list);
  }

  bool isFavoriteSeries(int seriesId) {
    return getFavoriteSeriesIds().contains(seriesId);
  }

  // --- Watch History ---
  List<Map<String, dynamic>> getHistory() {
    final raw = _box.get(_keyHistory);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  Future<void> addToHistory({
    required String type, // 'live', 'movie', 'episode'
    required int id,
    required String name,
    String? icon,
    String? extra, // e.g. "S01E03" for episodes
  }) async {
    var history = getHistory();
    // Remove if already exists to put it at the top
    history.removeWhere((item) => item['id'] == id && item['type'] == type);
    
    history.insert(0, {
      'type': type,
      'id': id,
      'name': name,
      'icon': icon,
      'extra': extra,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // Limit to last 30 items
    if (history.length > 30) {
      history = history.sublist(0, 30);
    }

    await _box.put(_keyHistory, history);
  }

  // --- Live Usage Tracker ---
  Map<int, int> getLiveUsageCounts() {
    final raw = _box.get(_keyLiveUsageCount);
    if (raw == null) return {};
    final map = <int, int>{};
    for (var key in (raw as Map).keys) {
      map[key as int] = raw[key] as int;
    }
    return map;
  }

  int getLiveUsage(int streamId) {
    return getLiveUsageCounts()[streamId] ?? 0;
  }

  Future<void> incrementLiveUsage(int streamId) async {
    final counts = getLiveUsageCounts();
    counts[streamId] = (counts[streamId] ?? 0) + 1;
    await _box.put(_keyLiveUsageCount, counts);
  }

  // --- Language Preference ---
  String? getLanguage() {
    return _box.get(_keyLanguage) as String?;
  }

  Future<void> saveLanguage(String langCode) async {
    await _box.put(_keyLanguage, langCode);
  }

  // --- Settings: EPG ---
  bool isEpgEnabled() {
    // Default to false since many providers don't support it or it's heavy
    return _box.get(_keyEpgEnabled, defaultValue: false);
  }

  Future<void> setEpgEnabled(bool enabled) async {
    await _box.put(_keyEpgEnabled, enabled);
  }

  // --- Settings: Recent Items Count ---
  int getRecentItemsCount() {
    return _box.get(_keyRecentCount, defaultValue: 30);
  }

  Future<void> setRecentItemsCount(int count) async {
    await _box.put(_keyRecentCount, count);
  }
}
