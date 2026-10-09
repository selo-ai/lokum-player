import 'package:flutter/foundation.dart';

// Debug-only logging that never prints playlist credentials.
//
// Xtream requests carry the username and password in the query string and in
// stream paths, and Dio puts the full URL into its exceptions, so every message
// is redacted before it is printed.

final Set<String> _secrets = {};

final _secretParam = RegExp(r'(username|password)=[^&\s"]+', caseSensitive: false);

// Registers a value (a username or password) that must never be printed.
void registerLogSecret(String value) {
  if (value.length >= 3) _secrets.add(value);
}

String redactSecrets(String message) {
  var out = message.replaceAllMapped(_secretParam, (m) => '${m[1]}=***');
  for (final secret in _secrets) {
    out = out.replaceAll(secret, '***');
  }
  return out;
}

void appLog(Object? message) {
  if (kDebugMode) debugPrint(redactSecrets('$message'));
}
