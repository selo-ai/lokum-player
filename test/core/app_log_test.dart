import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_app/core/logging/app_log.dart';

void main() {
  test('hides username and password query parameters', () {
    final out = redactSecrets(
      'DioException: GET http://example.com/player_api.php?username=demo&password=secret&action=get_live_streams',
    );
    expect(out, isNot(contains('demo')));
    expect(out, isNot(contains('secret')));
    expect(out, contains('action=get_live_streams'));
  });

  test('hides registered secrets anywhere in the message', () {
    registerLogSecret('streamuser');
    registerLogSecret('streampass');
    final out = redactSecrets('http://example.com/streamuser/streampass/1001');
    expect(out, 'http://example.com/***/***/1001');
  });
}
