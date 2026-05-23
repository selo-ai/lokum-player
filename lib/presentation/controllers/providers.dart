import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/iptv_api.dart';
import '../../data/datasources/local_storage.dart';

// Persistent Local Storage Provider
final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

// Xtream API Client Provider
final iptvApiProvider = Provider<IptvApi>((ref) {
  return IptvApi();
});
