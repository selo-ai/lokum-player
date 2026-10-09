import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_app/data/models/iptv_models.dart';
import 'package:iptv_app/domain/catalog/catalog_rules.dart';

IptvLiveChannel _channel(int id, String name, {String category = '1', int num = 0}) =>
    IptvLiveChannel(streamId: id, name: name, categoryId: category, num: num);

void main() {
  group('countryCodeOf', () {
    test('reads country words and prefixes', () {
      expect(countryCodeOf('TÜRK ULUSAL'), 'TR');
      expect(countryCodeOf('DE: Sport'), 'DE');
      expect(countryCodeOf('[FR] Cinéma'), 'FR');
      expect(countryCodeOf('UK | News'), 'EN');
    });

    test('does not read RUSSIA as USA', () {
      expect(countryCodeOf('RUSSIA'), 'RU');
    });

    test('returns null when no country is named', () {
      expect(countryCodeOf('SPOR'), isNull);
    });
  });

  test('daily series categories are recognised without Turkish letters', () {
    expect(isDailySeriesCategory('Çarşamba Dizileri'), isTrue);
    expect(isDailySeriesCategory('Aksiyon Filmleri'), isFalse);
  });

  test('daily series names lose their episode marker', () {
    expect(dailySeriesBaseName('Kızılcık Şerbeti 125. Bölüm'), 'Kızılcık Şerbeti');
    expect(extractEpisodeNumber('Kızılcık Şerbeti 125. Bölüm'), 125);
    expect(extractEpisodeNumber('Dizi Bölüm 7'), 7);
  });

  test('quality variants of one channel collapse into one group, best first', () {
    final groups = groupChannelVariants([
      _channel(1, 'TR: beIN SPORTS 1 SD', num: 3),
      _channel(2, 'TR: beIN SPORTS 1 FHD', num: 4),
      _channel(3, 'TR: beIN SPORTS 1 HD', num: 5),
      _channel(4, 'TR: TRT 1 HD', num: 1),
    ]);

    expect(groups, hasLength(2));
    expect(groups.first.baseName, 'TRT 1');
    final bein = groups.last;
    expect(bein.baseName, 'beIN SPORTS 1');
    expect(bein.variations.map((c) => c.streamId), [2, 3, 1]);
  });
}
