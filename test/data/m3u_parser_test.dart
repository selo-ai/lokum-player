import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_app/data/parsers/m3u_parser.dart';

const _sample = '﻿#EXTM3U url-tvg="http://example.com/epg.xml"\r\n'
    '#EXTINF:-1 tvg-id="trt1.tr" tvg-name="TR: TRT 1 HD" tvg-logo="http://example.com/trt1.png" group-title="TR | ULUSAL",TR: TRT 1 HD\r\n'
    'http://example.com:8080/user/pass/1001\r\n'
    '\r\n'
    '#EXTINF:-1 tvg-name="Film, Virgüllü" group-title="TR | SİNEMA",Film, Virgüllü (2024)\n'
    '#EXTVLCOPT:http-user-agent=Test\n'
    'http://example.com:8080/movie/user/pass/2002.mkv\n'
    '#EXTINF:0,Dizi S01 E01\n'
    '#EXTGRP:Diziler\n'
    'http://example.com:8080/series/user/pass/3003.mp4\n'
    '#EXTINF:-1,Missing url\n';

void main() {
  test('parses attributes, name and url of each entry', () {
    final entries = M3uParser.parse(_sample);
    expect(entries, hasLength(3));

    final trt = entries[0];
    expect(trt.name, 'TR: TRT 1 HD');
    expect(trt.url, 'http://example.com:8080/user/pass/1001');
    expect(trt.tvgId, 'trt1.tr');
    expect(trt.tvgLogo, 'http://example.com/trt1.png');
    expect(trt.groupTitle, 'TR | ULUSAL');
    expect(trt.duration, -1);
    expect(trt.contentType, M3uContentType.live);
  });

  test('keeps commas inside quoted attributes out of the title', () {
    final movie = M3uParser.parse(_sample)[1];
    expect(movie.name, 'Film, Virgüllü (2024)');
    expect(movie.tvgName, 'Film, Virgüllü');
    expect(movie.contentType, M3uContentType.movie);
  });

  test('falls back to #EXTGRP when group-title is missing', () {
    final episode = M3uParser.parse(_sample)[2];
    expect(episode.groupTitle, 'Diziler');
    expect(episode.duration, 0);
    expect(episode.contentType, M3uContentType.series);
  });

  test('stream parsing gives the same entries', () async {
    final streamed = await M3uParser.parseStream(Stream.fromIterable(_sample.split('\n'))).toList();
    expect(streamed.map((e) => e.url), M3uParser.parse(_sample).map((e) => e.url));
  });

  test('ignores urls without a preceding #EXTINF', () {
    expect(M3uParser.parse('#EXTM3U\nhttp://example.com/a.ts\n'), isEmpty);
  });
}
