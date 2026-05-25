class TmdbMovie {
  final int id;
  final String title;
  final String originalTitle;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final String releaseDate;
  final List<int> genreIds;

  TmdbMovie({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.releaseDate,
    required this.genreIds,
  });

  factory TmdbMovie.fromJson(Map<String, dynamic> json) {
    return TmdbMovie(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      originalTitle: json['original_title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate: json['release_date'] ?? '',
      genreIds: (json['genre_ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }

  String get posterUrl => posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';
  String get backdropUrl => backdropPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w1280$backdropPath' : '';
}

class MatchedMovie {
  final TmdbMovie tmdbMovie;
  final int streamId; // From IptvMovie
  final String streamIcon; // From IptvMovie (fallback)

  MatchedMovie({
    required this.tmdbMovie,
    required this.streamId,
    required this.streamIcon,
  });
}

class TmdbSeries {
  final int id;
  final String name;
  final String originalName;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final String firstAirDate;
  final List<int> genreIds;

  TmdbSeries({
    required this.id,
    required this.name,
    required this.originalName,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.firstAirDate,
    required this.genreIds,
  });

  factory TmdbSeries.fromJson(Map<String, dynamic> json) {
    return TmdbSeries(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      originalName: json['original_name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      firstAirDate: json['first_air_date'] ?? '',
      genreIds: (json['genre_ids'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
    );
  }

  String get posterUrl => posterPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w500$posterPath' : '';
  String get backdropUrl => backdropPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w1280$backdropPath' : '';
}

class MatchedSeries {
  final TmdbSeries tmdbSeries;
  final int seriesId; // From IptvSeries
  final String cover; // From IptvSeries (fallback)

  MatchedSeries({
    required this.tmdbSeries,
    required this.seriesId,
    required this.cover,
  });
}

class CarouselMedia {
  final bool isMovie;
  final dynamic tmdbData; 
  final int streamId; 
  final String coverOrIcon;

  CarouselMedia({
    required this.isMovie,
    required this.tmdbData,
    required this.streamId,
    required this.coverOrIcon,
  });

  String get title => isMovie ? (tmdbData as TmdbMovie).title : (tmdbData as TmdbSeries).name;
  String get backdropUrl => isMovie ? (tmdbData as TmdbMovie).backdropUrl : (tmdbData as TmdbSeries).backdropUrl;
  double get voteAverage => isMovie ? (tmdbData as TmdbMovie).voteAverage : (tmdbData as TmdbSeries).voteAverage;
  String get releaseDate => isMovie ? (tmdbData as TmdbMovie).releaseDate : (tmdbData as TmdbSeries).firstAirDate;
  String get posterUrl => isMovie ? (tmdbData as TmdbMovie).posterUrl : (tmdbData as TmdbSeries).posterUrl;
}
