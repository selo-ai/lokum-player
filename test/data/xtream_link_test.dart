import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_app/data/parsers/xtream_link.dart';

void main() {
  test('splits a get.php link into server, username and password', () {
    final link = XtreamLink.tryParse(
      'http://example.com:8080/get.php?username=demo&password=secret&type=m3u_plus&output=ts',
    )!;
    expect(link.serverUrl, 'http://example.com:8080');
    expect(link.username, 'demo');
    expect(link.password, 'secret');
  });

  test('adds a scheme when it is missing', () {
    final link = XtreamLink.tryParse('example.com/player_api.php?username=a1&password=b2')!;
    expect(link.serverUrl, 'http://example.com');
  });

  test('returns null for a plain server address', () {
    expect(XtreamLink.tryParse('http://example.com:8080'), isNull);
    expect(XtreamLink.tryParse(''), isNull);
  });
}
