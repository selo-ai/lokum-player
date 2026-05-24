class IptvCredentials {
  final String serverUrl;
  final String username;
  final String password;
  final String? m3uUrl; // for m3u fallback if applicable

  IptvCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.m3uUrl,
  });

  Map<String, dynamic> toJson() => {
    'serverUrl': serverUrl,
    'username': username,
    'password': password,
    'm3uUrl': m3uUrl,
  };

  factory IptvCredentials.fromJson(Map<String, dynamic> json) => IptvCredentials(
    serverUrl: json['serverUrl'] ?? '',
    username: json['username'] ?? '',
    password: json['password'] ?? '',
    m3uUrl: json['m3uUrl'],
  );

  bool get isXtream => serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
}

class IptvCategory {
  final String id;
  final String name;
  final String type; // 'live', 'movie', 'series'

  IptvCategory({
    required this.id,
    required this.name,
    required this.type,
  });

  factory IptvCategory.fromJson(Map<String, dynamic> json, String type) => IptvCategory(
    id: (json['category_id'] ?? '').toString(),
    name: json['category_name'] ?? '',
    type: type,
  );

  Map<String, dynamic> toJson() => {
    'category_id': id,
    'category_name': name,
    'type': type,
  };
}

class IptvLiveChannel {
  final int streamId;
  final String name;
  final String? icon;
  final String categoryId;
  final String? epgChannelId;
  final int num;

  IptvLiveChannel({
    required this.streamId,
    required this.name,
    this.icon,
    required this.categoryId,
    this.epgChannelId,
    required this.num,
  });

  factory IptvLiveChannel.fromJson(Map<String, dynamic> json) => IptvLiveChannel(
    streamId: json['stream_id'] is int ? json['stream_id'] : int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
    name: json['name'] ?? '',
    icon: json['stream_icon']?.toString().isEmpty == true ? null : json['stream_icon'],
    categoryId: (json['category_id'] ?? '').toString(),
    epgChannelId: json['epg_channel_id']?.toString(),
    num: json['num'] is int ? json['num'] : int.tryParse(json['num']?.toString() ?? '0') ?? 0,
  );

  String get displayName {
    var cleaned = name.trim();
    // Match prefixes like: "TR:", "TR :", "TR|", "TR |", "TR -", "TR-", "[TR]"
    final prefixRegex = RegExp(
      r'^(?:[A-Z]{2,4}\s*[:\||\-–]\s*|\[[A-Z]{2,4}\]\s*)',
      caseSensitive: true,
    );
    while (prefixRegex.hasMatch(cleaned)) {
      cleaned = cleaned.replaceFirst(prefixRegex, '').trim();
    }
    // Also clean up common secondary tags like "HD", "FHD" if separated at the beginning
    final secondaryRegex = RegExp(
      r'^(?:(?:HD|FHD|4K|SD|SD|HEVC)\s*[:\||\-–]\s*)',
      caseSensitive: false,
    );
    while (secondaryRegex.hasMatch(cleaned)) {
      cleaned = cleaned.replaceFirst(secondaryRegex, '').trim();
    }
    // Remove leading separator leftovers
    cleaned = cleaned.replaceFirst(RegExp(r'^[:\||\-–\s]+'), '');
    return cleaned.trim().isEmpty ? name : cleaned.trim();
  }

  String get baseName {
    var cleaned = displayName;
    // Match common quality and backup suffixes at the end of the channel name, supporting bracketed/parenthesized tags
    final suffixRegex = RegExp(
      r'(?:\s*[\[\(][^\]\)]*[\]\)]$|\s*(?:[:\||\-–\s]\s*)*(?:HD|FHD|4K|8K|SD|HQ|HEVC|H265|1080P|720P|YEDEK|BACKUP|ALT|VIP|RAW|PREMIUM|UHD)\b)',
      caseSensitive: false,
    );
    
    // Clean recursively to strip multiple combined suffixes (e.g. "HD YEDEK")
    String previous;
    do {
      previous = cleaned;
      cleaned = cleaned.replaceFirst(suffixRegex, '').trim();
    } while (cleaned != previous);
    
    // Remove any trailing trailing separator leftovers
    cleaned = cleaned.replaceFirst(RegExp(r'[:\||\-–\s]+$'), '');
    
    return cleaned.trim().isEmpty ? displayName : cleaned.trim();
  }

  String get qualityLabel {
    final base = baseName.toLowerCase();
    final display = displayName.toLowerCase();
    if (display == base) {
      return 'SD';
    }
    // Remove base name from display name to get the quality/backup details
    var label = displayName;
    final idx = display.indexOf(base);
    if (idx != -1) {
      label = displayName.substring(0, idx) + displayName.substring(idx + base.length);
    }
    label = label.replaceAll(RegExp(r'[\[\]\(\):\||\-–\s]+'), ' ').trim();
    return label.isEmpty ? 'SD' : label.toUpperCase();
  }

  Map<String, dynamic> toJson() => {
    'stream_id': streamId,
    'name': name,
    'stream_icon': icon,
    'category_id': categoryId,
    'epg_channel_id': epgChannelId,
    'num': num,
  };
}

class IptvMovie {
  final int streamId;
  final String name;
  final String? icon;
  final String categoryId;
  final String? rating;
  final String? year;
  final double? ratingValue;
  final String? added;

  IptvMovie({
    required this.streamId,
    required this.name,
    this.icon,
    required this.categoryId,
    this.rating,
    this.year,
    this.ratingValue,
    this.added,
  });

  DateTime? get addedDate {
    if (added == null || added!.isEmpty) return null;
    final seconds = int.tryParse(added!);
    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return null;
  }

  factory IptvMovie.fromJson(Map<String, dynamic> json) {
    double? rValue;
    if (json['rating'] != null) {
      rValue = double.tryParse(json['rating'].toString());
    }
    return IptvMovie(
      streamId: json['stream_id'] is int ? json['stream_id'] : int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      icon: json['stream_icon']?.toString().isEmpty == true ? null : json['stream_icon'],
      categoryId: (json['category_id'] ?? '').toString(),
      rating: json['rating']?.toString(),
      year: json['year']?.toString(),
      ratingValue: rValue,
      added: json['added']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'stream_id': streamId,
    'name': name,
    'stream_icon': icon,
    'category_id': categoryId,
    'rating': rating,
    'year': year,
  };
}

class IptvSeries {
  final int seriesId;
  final String name;
  final String? cover;
  final String categoryId;
  final String? plot;
  final String? cast;
  final String? director;
  final String? releaseDate;
  final String? rating;
  final String? added;

  IptvSeries({
    required this.seriesId,
    required this.name,
    this.cover,
    required this.categoryId,
    this.plot,
    this.cast,
    this.director,
    this.releaseDate,
    this.rating,
    this.added,
  });

  DateTime? get addedDate {
    if (added == null || added!.isEmpty) return null;
    final seconds = int.tryParse(added!);
    if (seconds != null) {
      return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    }
    return null;
  }

  factory IptvSeries.fromJson(Map<String, dynamic> json) => IptvSeries(
    seriesId: json['series_id'] is int ? json['series_id'] : int.tryParse(json['series_id']?.toString() ?? '0') ?? 0,
    name: json['name'] ?? '',
    cover: json['cover']?.toString().isEmpty == true ? null : json['cover'],
    categoryId: (json['category_id'] ?? '').toString(),
    plot: json['plot'],
    cast: json['cast'],
    director: json['director'],
    releaseDate: json['releaseDate']?.toString() ?? json['release_date']?.toString(),
    rating: json['rating']?.toString(),
    added: json['added']?.toString() ?? json['last_modified']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'series_id': seriesId,
    'name': name,
    'cover': cover,
    'category_id': categoryId,
    'plot': plot,
    'cast': cast,
    'director': director,
    'releaseDate': releaseDate,
    'rating': rating,
  };
}

class IptvEpisode {
  final int id;
  final int streamId;
  final String title;
  final String? containerExtension;
  final int episodeNum;
  final int season;

  IptvEpisode({
    required this.id,
    required this.streamId,
    required this.title,
    this.containerExtension,
    required this.episodeNum,
    required this.season,
  });

  factory IptvEpisode.fromJson(Map<String, dynamic> json) => IptvEpisode(
    id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
    streamId: json['stream_id'] is int ? json['stream_id'] : int.tryParse(json['stream_id']?.toString() ?? '0') ?? 0,
    title: json['title'] ?? '',
    containerExtension: json['container_extension'] ?? 'mp4',
    episodeNum: json['episode_num'] is int ? json['episode_num'] : int.tryParse(json['episode_num']?.toString() ?? '0') ?? 0,
    season: json['season'] is int ? json['season'] : int.tryParse(json['season']?.toString() ?? '0') ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'stream_id': streamId,
    'title': title,
    'container_extension': containerExtension,
    'episode_num': episodeNum,
    'season': season,
  };
}

class EpgProgram {
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;

  EpgProgram({
    required this.title,
    required this.start,
    required this.end,
    this.description,
  });

  factory EpgProgram.fromJson(Map<String, dynamic> json) {
    // Xtream EPG start/end times are often in unix timestamps or formatted strings
    DateTime parseTime(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val * 1000);
      if (val is String) {
        final parsed = double.tryParse(val) ?? int.tryParse(val)?.toDouble();
        if (parsed != null) {
          return DateTime.fromMillisecondsSinceEpoch((parsed * 1000).toInt());
        }
        return DateTime.tryParse(val) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return EpgProgram(
      title: json['title'] ?? '',
      start: parseTime(json['start']),
      end: parseTime(json['end']),
      description: json['description'],
    );
  }

  bool get isNow {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  double get progress {
    final now = DateTime.now();
    if (!isNow) return 0.0;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = now.difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
