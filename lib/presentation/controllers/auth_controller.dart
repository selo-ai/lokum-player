import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logging/app_log.dart';
import '../../data/models/iptv_models.dart';
import 'providers.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final IptvCredentials? credentials;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.credentials,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);

  AuthState copyWith({
    AuthStatus? status,
    IptvCredentials? credentials,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      credentials: credentials ?? this.credentials,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState.initial();
  }

  Future<void> checkStoredCredentials() async {
    final storage = ref.read(localStorageProvider);
    final creds = await storage.getCredentials();
    
    if (creds != null && creds.isXtream) {
      registerLogSecret(creds.username);
      registerLogSecret(creds.password);
      state = state.copyWith(status: AuthStatus.loading);
      final api = ref.read(iptvApiProvider);
      final authenticatedCreds = await api.authenticate(creds);
      
      if (authenticatedCreds != null) {
        state = AuthState(status: AuthStatus.authenticated, credentials: authenticatedCreds);
      } else {
        // Stored credentials expired or server down, but let's allow offline mode / re-auth
        state = AuthState(
          status: AuthStatus.unauthenticated, 
          errorMessage: 'Sunucu bağlantısı kurulamadı. Lütfen giriş bilgilerinizi kontrol edin.',
        );
      }
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String serverUrl, String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    
    // Clean up server URL
    var cleanedUrl = serverUrl.trim();
    
    // Lowercase for checking but keep original case for domains if needed.
    // Strip '/player_api.php' and any trailing slash or query params
    final apiPhpIndex = cleanedUrl.toLowerCase().indexOf('/player_api.php');
    if (apiPhpIndex != -1) {
      cleanedUrl = cleanedUrl.substring(0, apiPhpIndex);
    }
    
    // Strip '/get.php' (common if copy-pasting an M3U link by mistake)
    final getPhpIndex = cleanedUrl.toLowerCase().indexOf('/get.php');
    if (getPhpIndex != -1) {
      cleanedUrl = cleanedUrl.substring(0, getPhpIndex);
    }

    // Strip '/xmltv.php' (XMLTV EPG link)
    final xmltvPhpIndex = cleanedUrl.toLowerCase().indexOf('/xmltv.php');
    if (xmltvPhpIndex != -1) {
      cleanedUrl = cleanedUrl.substring(0, xmltvPhpIndex);
    }
    
    // Strip any trailing slashes
    while (cleanedUrl.endsWith('/')) {
      cleanedUrl = cleanedUrl.substring(0, cleanedUrl.length - 1);
    }

    // Ensure valid scheme
    if (!cleanedUrl.startsWith('http://') && !cleanedUrl.startsWith('https://')) {
      cleanedUrl = 'http://$cleanedUrl';
    }

    final creds = IptvCredentials(
      serverUrl: cleanedUrl,
      username: username.trim(),
      password: password.trim(),
    );

    registerLogSecret(creds.username);
    registerLogSecret(creds.password);

    final api = ref.read(iptvApiProvider);
    final storage = ref.read(localStorageProvider);
    
    try {
      final authenticatedCreds = await api.authenticate(creds);
      if (authenticatedCreds != null) {
        await storage.saveCredentials(authenticatedCreds);
        state = AuthState(status: AuthStatus.authenticated, credentials: authenticatedCreds);
        return true;
      } else {
        state = AuthState(
          status: AuthStatus.error,
          errorMessage: 'Giriş başarısız. Lütfen bilgilerinizi ve sunucu adresini kontrol edin.',
        );
        return false;
      }
    } catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: 'Ağ hatası oluştu: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    final storage = ref.read(localStorageProvider);
    await storage.clearCredentials();
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(() {
  return AuthController();
});
