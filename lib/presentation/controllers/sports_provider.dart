import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/iptv_models.dart';
import 'iptv_controller.dart';
import 'providers.dart';

final sportsLiveKeywords = ['spor', 'sport', 'futbol', 'basketbol', 'bein', 'match', 'nba', 'premier', 'süper lig', 'super lig'];
final sportsVodCategoryKeywords = ['spor', 'sport', 'futbol', 'basketbol', 'nba'];

bool _isSportsCategory(IptvCategory category) {
  final name = category.name.toLowerCase();
  return sportsLiveKeywords.any((keyword) => name.contains(keyword));
}

// 1. Get all sports category IDs for Live TV
final sportsLiveCategoriesProvider = Provider<List<String>>((ref) {
  final iptvState = ref.watch(iptvControllerProvider);
  return iptvState.liveCategories
      .where(_isSportsCategory)
      .map((c) => c.id)
      .toList();
});

// 2. Get all sports Live Channels (filtered by category or channel name)
final sportsLiveChannelsProvider = Provider<List<IptvLiveChannel>>((ref) {
  final iptvState = ref.watch(iptvControllerProvider);
  final sportsCatIds = ref.watch(sportsLiveCategoriesProvider);

  return iptvState.liveChannels.where((channel) {
    if (sportsCatIds.contains(channel.categoryId)) return true;
    final name = channel.name.toLowerCase();
    return sportsLiveKeywords.any((keyword) => name.contains(keyword));
  }).toList();
});

// 3. Get all sports channels that have TV Archive (Catch-up)
final sportsArchiveChannelsProvider = Provider<List<IptvLiveChannel>>((ref) {
  final sportsChannels = ref.watch(sportsLiveChannelsProvider);
  return sportsChannels.where((c) => c.hasTvArchive).toList();
});

// 4. Get all sports category IDs for VOD (Movies & Series)
final sportsMovieCategoriesProvider = Provider<List<String>>((ref) {
  final iptvState = ref.watch(iptvControllerProvider);
  
  print('--- MOVIE CATEGORIES DUMP ---');
  for (var c in iptvState.movieCategories) {
    print('MOVIE CAT: ${c.name}');
  }
  print('-----------------------------');

  return iptvState.movieCategories
      .where((c) => sportsVodCategoryKeywords.any((kw) => c.name.toLowerCase().contains(kw)))
      .map((c) => c.id)
      .toList();
});

final sportsSeriesCategoriesProvider = Provider<List<String>>((ref) {
  final iptvState = ref.watch(iptvControllerProvider);
  return iptvState.seriesCategories
      .where((c) => sportsVodCategoryKeywords.any((kw) => c.name.toLowerCase().contains(kw)))
      .map((c) => c.id)
      .toList();
});

// 5. Get sports Movies
final sportsMoviesProvider = Provider<List<IptvMovie>>((ref) {
  final iptvState = ref.watch(iptvControllerProvider);
  final sportsCatIds = ref.watch(sportsMovieCategoriesProvider);

  return iptvState.movies.where((movie) {
    return sportsCatIds.contains(movie.categoryId);
  }).toList();
});

// 6. Get sports Series
final sportsSeriesProvider = Provider<List<IptvSeries>>((ref) {
  final iptvState = ref.watch(iptvControllerProvider);
  final sportsCatIds = ref.watch(sportsSeriesCategoriesProvider);

  return iptvState.series.where((series) {
    return sportsCatIds.contains(series.categoryId);
  }).toList();
});
