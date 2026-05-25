import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/tmdb_models.dart';

final tmdbApiProvider = Provider<TmdbApi>((ref) => TmdbApi(Dio()));

class TmdbApi {
  final Dio _dio;
  static const String _baseUrl = 'https://api.themoviedb.org/3';
  static const String _apiKey = '459adc026fb1f750defa373b6218c3a1'; // The key provided by user

  TmdbApi(this._dio);

  Future<List<TmdbMovie>> getPopularMoviesByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/discover/movie',
        queryParameters: {
          'api_key': _apiKey,
          'language': 'tr-TR',
          'with_genres': genreId,
          'sort_by': 'popularity.desc',
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final List results = response.data['results'] ?? [];
        return results.map((json) => TmdbMovie.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('TMDB API Error (getPopularMoviesByGenre): $e');
      return [];
    }
  }

  Future<List<TmdbSeries>> getPopularTvShowsByGenre(int genreId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/discover/tv',
        queryParameters: {
          'api_key': _apiKey,
          'language': 'tr-TR',
          'with_genres': genreId,
          'sort_by': 'popularity.desc',
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final List results = response.data['results'] ?? [];
        return results.map((json) => TmdbSeries.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('TMDB API Error (getPopularTvShowsByGenre): $e');
      return [];
    }
  }

  Future<List<TmdbMovie>> getTrendingMovies({int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/trending/movie/day',
        queryParameters: {
          'api_key': _apiKey,
          'language': 'tr-TR',
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final List results = response.data['results'] ?? [];
        return results.map((json) => TmdbMovie.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('TMDB API Error (getTrendingMovies): $e');
      return [];
    }
  }

  Future<List<TmdbMovie>> getMoviesByKeyword(int keywordId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/discover/movie',
        queryParameters: {
          'api_key': _apiKey,
          'language': 'tr-TR',
          'with_keywords': keywordId,
          'sort_by': 'popularity.desc',
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final List results = response.data['results'] ?? [];
        return results.map((json) => TmdbMovie.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('TMDB API Error (getMoviesByKeyword): $e');
      return [];
    }
  }

  Future<List<TmdbSeries>> getTvShowsByKeyword(int keywordId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/discover/tv',
        queryParameters: {
          'api_key': _apiKey,
          'language': 'tr-TR',
          'with_keywords': keywordId,
          'sort_by': 'popularity.desc',
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final List results = response.data['results'] ?? [];
        return results.map((json) => TmdbSeries.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('TMDB API Error (getTvShowsByKeyword): $e');
      return [];
    }
  }

  Future<List<TmdbMovie>> getMoviesByGenreAndKeyword(int genreId, int keywordId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/discover/movie',
        queryParameters: {
          'api_key': _apiKey,
          'language': 'tr-TR',
          'with_genres': genreId,
          'with_keywords': keywordId,
          'sort_by': 'popularity.desc',
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final List results = response.data['results'] ?? [];
        return results.map((json) => TmdbMovie.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('TMDB API Error (getMoviesByGenreAndKeyword): $e');
      return [];
    }
  }

  Future<List<TmdbSeries>> getTvShowsByGenreAndKeyword(int genreId, int keywordId, {int page = 1}) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/discover/tv',
        queryParameters: {
          'api_key': _apiKey,
          'language': 'tr-TR',
          'with_genres': genreId,
          'with_keywords': keywordId,
          'sort_by': 'popularity.desc',
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final List results = response.data['results'] ?? [];
        return results.map((json) => TmdbSeries.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('TMDB API Error (getTvShowsByGenreAndKeyword): $e');
      return [];
    }
  }
}
