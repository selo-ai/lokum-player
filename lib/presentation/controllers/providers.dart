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

class EpgEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    final storage = ref.watch(localStorageProvider);
    return storage.isEpgEnabled();
  }

  void setEnabled(bool val) {
    ref.read(localStorageProvider).setEpgEnabled(val);
    state = val;
  }
}

// Settings: EPG Provider
final epgEnabledProvider = NotifierProvider<EpgEnabledNotifier, bool>(() {
  return EpgEnabledNotifier();
});
