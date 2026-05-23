import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/iptv_models.dart';

class IptvApi {
  late final Dio _dio;

  IptvApi() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ));

    // Bypass SSL certificate validation for cheap/self-signed IPTV servers
    _dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
        return client;
      },
    );

    // Auto-decode stringified JSON responses from misconfigured content-type IPTV servers
    _dio.interceptors.add(InterceptorsWrapper(
      onResponse: (response, handler) {
        if (response.data is String) {
          final String dataStr = (response.data as String).trim();
          if ((dataStr.startsWith('{') && dataStr.endsWith('}')) ||
              (dataStr.startsWith('[') && dataStr.endsWith(']'))) {
            try {
              response.data = jsonDecode(dataStr);
            } catch (e) {
              print('IptvApi Interceptor: Failed to decode response as JSON: $e');
            }
          }
        }
        return handler.next(response);
      },
    ));
  }

  // Generates base player_api.php URL
  String _buildApiUrl(IptvCredentials creds) {
    var baseUrl = creds.serverUrl;
    if (!baseUrl.endsWith('/')) {
      baseUrl += '/';
    }
    return '${baseUrl}player_api.php';
  }

  // Generates stream base path (e.g. server_url/live/username/password/)
  String buildStreamUrl(IptvCredentials creds, String type, int streamId, [String extension = 'ts']) {
    var baseUrl = creds.serverUrl;
    if (!baseUrl.endsWith('/')) {
      baseUrl += '/';
    }
    
    // Custom endpoint formatting
    if (type == 'live') {
      return '$baseUrl${creds.username}/${creds.password}/$streamId';
    } else if (type == 'movie') {
      return '${baseUrl}movie/${creds.username}/${creds.password}/$streamId.$extension';
    } else if (type == 'series') {
      return '${baseUrl}series/${creds.username}/${creds.password}/$streamId.$extension';
    }
    return '';
  }

  // --- Auth & Login ---
  Future<IptvCredentials?> authenticate(IptvCredentials creds) async {
    final apiUrl = _buildApiUrl(creds);
    print('IPTV API: Attempting authentication at: $apiUrl');
    print('IPTV API: Credentials - Username: "${creds.username}", Password length: ${creds.password.length}');
    try {
      final response = await _dio.get(
        apiUrl,
        queryParameters: {
          'username': creds.username,
          'password': creds.password,
        },
      );

      print('IPTV API Response: Status Code ${response.statusCode}');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        print('IPTV API Response Data Type: ${data.runtimeType}');
        print('IPTV API Response Data: $data');
        if (data is Map) {
          final userInfo = data['user_info'];
          if (userInfo != null && userInfo['auth'] != null) {
            final auth = userInfo['auth'];
            final isAuthSuccessful = auth == 1 || 
                                     auth == '1' || 
                                     auth == true || 
                                     auth.toString() == '1' || 
                                     auth.toString().toLowerCase() == 'true';
            print('IPTV API Auth Field: "$auth", isAuthSuccessful: $isAuthSuccessful');
            if (isAuthSuccessful) {
              return creds;
            }
          } else {
            print('IPTV API Auth Info missing user_info or auth key. Keys: ${data.keys.toList()}');
          }
        } else {
          print('IPTV API Response is not a Map.');
        }
      }
      return null;
    } catch (e) {
      print('IPTV API Authentication Exception: $e');
      
      // Auto-fallback from HTTPS to HTTP if a handshake or SSL error is detected
      if (creds.serverUrl.startsWith('https://')) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('handshake') || 
            errorMsg.contains('tls') || 
            errorMsg.contains('wrong_version_number') || 
            errorMsg.contains('wrong_signature_type') || 
            errorMsg.contains('certificate_verify_failed') ||
            errorMsg.contains('ssl')) {
          
          final fallbackUrl = creds.serverUrl.replaceFirst('https://', 'http://');
          print('IPTV API: HTTPS Handshake failed (likely due to HTTP-only port). Retrying with HTTP fallback: $fallbackUrl');
          final fallbackCreds = IptvCredentials(
            serverUrl: fallbackUrl,
            username: creds.username,
            password: creds.password,
          );
          return authenticate(fallbackCreds);
        }
      }
      return null;
    }
  }

  // --- Get Server Account Information ---
  Future<Map<String, dynamic>?> getAccountInfo(IptvCredentials creds) async {
    final apiUrl = _buildApiUrl(creds);
    try {
      final response = await _dio.get(
        apiUrl,
        queryParameters: {
          'username': creds.username,
          'password': creds.password,
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      print('IPTV API getAccountInfo Exception: $e');
    }
    return null;
  }

  // --- Categories ---
  Future<List<IptvCategory>> getCategories(IptvCredentials creds, String type) async {
    String action;
    if (type == 'live') {
      action = 'get_live_categories';
    } else if (type == 'movie') {
      action = 'get_vod_categories';
    } else if (type == 'series') {
      action = 'get_series_categories';
    } else {
      return [];
    }

    print('IPTV API: Fetching categories for type "$type" with action "$action"');
    try {
      final response = await _dio.get(
        _buildApiUrl(creds),
        queryParameters: {
          'username': creds.username,
          'password': creds.password,
          'action': action,
        },
      );

      print('IPTV API: getCategories ($type) Response: Status ${response.statusCode}, Data type: ${response.data?.runtimeType}');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          final list = response.data as List;
          print('IPTV API: Loaded ${list.length} categories for type "$type"');
          return list.map((json) => IptvCategory.fromJson(json, type)).toList();
        } else {
          print('IPTV API Warning: getCategories ($type) response data is NOT a List. Data: ${response.data}');
        }
      }
      return [];
    } catch (e) {
      print('IPTV API Error: getCategories ($type) failed: $e');
      return [];
    }
  }

  // --- Live Channels ---
  Future<List<IptvLiveChannel>> getLiveChannels(IptvCredentials creds, {String? categoryId}) async {
    print('IPTV API: Fetching live channels (category: $categoryId)');
    try {
      final queryParams = {
        'username': creds.username,
        'password': creds.password,
        'action': 'get_live_streams',
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category_id'] = categoryId;
      }

      final response = await _dio.get(
        _buildApiUrl(creds),
        queryParameters: queryParams,
      );

      print('IPTV API: getLiveChannels Response: Status ${response.statusCode}, Data type: ${response.data?.runtimeType}');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          final list = response.data as List;
          print('IPTV API: Loaded ${list.length} live channels');
          return list.map((json) => IptvLiveChannel.fromJson(json)).toList();
        } else {
          print('IPTV API Warning: getLiveChannels response data is NOT a List. Data: ${response.data}');
        }
      }
      return [];
    } catch (e) {
      print('IPTV API Error: getLiveChannels failed: $e');
      return [];
    }
  }

  // --- Movies (VOD) ---
  Future<List<IptvMovie>> getMovies(IptvCredentials creds, {String? categoryId}) async {
    print('IPTV API: Fetching movies (category: $categoryId)');
    try {
      final queryParams = {
        'username': creds.username,
        'password': creds.password,
        'action': 'get_vod_streams',
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category_id'] = categoryId;
      }

      final response = await _dio.get(
        _buildApiUrl(creds),
        queryParameters: queryParams,
      );

      print('IPTV API: getMovies Response: Status ${response.statusCode}, Data type: ${response.data?.runtimeType}');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          final list = response.data as List;
          print('IPTV API: Loaded ${list.length} movies');
          return list.map((json) => IptvMovie.fromJson(json)).toList();
        } else {
          print('IPTV API Warning: getMovies response data is NOT a List. Data: ${response.data}');
        }
      }
      return [];
    } catch (e) {
      print('IPTV API Error: getMovies failed: $e');
      return [];
    }
  }

  // --- Series ---
  Future<List<IptvSeries>> getSeries(IptvCredentials creds, {String? categoryId}) async {
    print('IPTV API: Fetching series (category: $categoryId)');
    try {
      final queryParams = {
        'username': creds.username,
        'password': creds.password,
        'action': 'get_series',
      };
      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category_id'] = categoryId;
      }

      final response = await _dio.get(
        _buildApiUrl(creds),
        queryParameters: queryParams,
      );

      print('IPTV API: getSeries Response: Status ${response.statusCode}, Data type: ${response.data?.runtimeType}');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          final list = response.data as List;
          print('IPTV API: Loaded ${list.length} series');
          return list.map((json) => IptvSeries.fromJson(json)).toList();
        } else {
          print('IPTV API Warning: getSeries response data is NOT a List. Data: ${response.data}');
        }
      }
      return [];
    } catch (e) {
      print('IPTV API Error: getSeries failed: $e');
      return [];
    }
  }

  // --- Series Details & Episodes ---
  Future<List<IptvEpisode>> getSeriesEpisodes(IptvCredentials creds, int seriesId) async {
    try {
      final response = await _dio.get(
        _buildApiUrl(creds),
        queryParameters: {
          'username': creds.username,
          'password': creds.password,
          'action': 'get_series_info',
          'series_id': seriesId.toString(),
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final episodesMap = data['episodes'];
        if (episodesMap != null && episodesMap is Map) {
          final List<IptvEpisode> allEpisodes = [];
          
          episodesMap.forEach((seasonKey, episodeList) {
            if (episodeList is List) {
              for (final ep in episodeList) {
                if (ep is Map) {
                  allEpisodes.add(IptvEpisode.fromJson(Map<String, dynamic>.from(ep)));
                }
              }
            }
          });
          
          // Sort episodes: season ascending, episode number ascending
          allEpisodes.sort((a, b) {
            if (a.season != b.season) return a.season.compareTo(b.season);
            return a.episodeNum.compareTo(b.episodeNum);
          });
          
          return allEpisodes;
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- EPG (Short) ---
  Future<List<EpgProgram>> getShortEpg(IptvCredentials creds, int streamId) async {
    try {
      print('IPTV API: Requesting short EPG for stream_id $streamId...');
      final response = await _dio.get(
        _buildApiUrl(creds),
        queryParameters: {
          'username': creds.username,
          'password': creds.password,
          'action': 'get_short_epg',
          'stream_id': streamId.toString(),
        },
      );

      print('IPTV API: getShortEpg Response status: ${response.statusCode}, data type: ${response.data.runtimeType}');
      if (response.statusCode == 200) {
        if (response.data is Map) {
          final data = response.data as Map;
          final listings = data['epg_listings'];
          print('IPTV API: listings list: $listings');
          if (listings is List) {
            final programs = listings.map((json) => EpgProgram.fromJson(json)).toList();
            print('IPTV API: Parsed ${programs.length} EPG programs.');
            return programs;
          }
        } else {
          print('IPTV API: getShortEpg response.data is not a Map, it is: ${response.data}');
        }
      }
      return [];
    } catch (e, stack) {
      print('IPTV API: getShortEpg Exception: $e');
      print(stack);
      return [];
    }
  }
}
