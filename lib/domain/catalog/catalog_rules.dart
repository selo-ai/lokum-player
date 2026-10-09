import '../../data/models/iptv_models.dart';

// Rules that turn the provider's raw category and channel names into the
// app's own catalog structure. Pure Dart, so they are unit tested.

String? countryCodeOf(String name) {
  final upperName = name.toUpperCase();
  if (upperName.contains('TÜRK') || upperName.contains('TURK') || upperName.contains('KKTC')) {
    return 'TR';
  }
  if (upperName.contains('DEUTSCHE') || upperName.contains('DEUTSCH') || upperName.contains('ÖSTERREICH')) {
    return 'DE';
  }
  if (upperName.contains('SCHWEIZ') || upperName.contains('SWISS')) {
    return 'CH';
  }
  if (upperName.contains('NEDERLAND') || upperName.contains('DUTCH')) {
    return 'NL';
  }
  if (upperName.contains('FRANCE') || upperName.contains('FRENCH')) {
    return 'FR';
  }
  if (upperName.contains('ITALIA') || upperName.contains('ITALY') || upperName.contains('ITALIAN')) {
    return 'IT';
  }
  if (upperName.contains('UNITED KINGDOM') || upperName.contains('ENGLISH')) {
    return 'EN';
  }
  if (upperName.contains('ESPAÑA') || upperName.contains('ESPANA') || upperName.contains('SPANISH') || upperName.contains('SPAIN')) {
    return 'ES';
  }
  if (upperName.contains('PORTUGAL') || upperName.contains('PORTUGUESE')) {
    return 'PT';
  }
  if (upperName.contains('ARABIC') || upperName.contains('ARAB') || upperName.contains('DINI')) {
    return 'AR';
  }
  if (upperName.contains('RUSSIA') || upperName.contains('RUSSIAN')) {
    return 'RU';
  }
  if (upperName.contains('UKRAINE') || upperName.contains('UKRAINIAN')) {
    return 'UA';
  }
  // Check USA/UK after RUSSIA/UKRAINE to avoid false substring matches (RUSSIA contains US, UKRAINE contains UK)
  if (upperName.contains('USA') || upperName.contains('UK') || upperName.contains('US ')) {
    return 'EN';
  }
  if (upperName.contains('AZERBAIJAN') || upperName.contains('AZERBAIJANI')) {
    return 'AZ';
  }
  if (upperName.contains('BULGARIA') || upperName.contains('BULGARIAN')) {
    return 'BG';
  }
  if (upperName.contains('POLAND') || upperName.contains('POLISH')) {
    return 'PL';
  }
  if (upperName.contains('DENMARK') || upperName.contains('DANISH')) {
    return 'DK';
  }
  if (upperName.contains('NORWAY') || upperName.contains('NORWEGIAN')) {
    return 'NO';
  }
  if (upperName.contains('SWEDEN') || upperName.contains('SWEDISH')) {
    return 'SE';
  }
  if (upperName.contains('BELGIUM') || upperName.contains('BELGIAN')) {
    return 'BE';
  }

  if (upperName.contains('GREECE') || upperName.contains('GREEK')) {
    return 'GR';
  }
  if (upperName.contains('ROMANIA') || upperName.contains('ROMANIAN')) {
    return 'RO';
  }
  if (upperName.contains('INDIA') || upperName.contains('INDIAN')) {
    return 'IN';
  }
  if (upperName.contains('AFRICA') || upperName.contains('AFRICAN')) {
    return 'AF';
  }
  if (upperName.contains('ALBANIA') || upperName.contains('ALBANIAN')) {
    return 'AL';
  }
  if (upperName.contains('ARMENIA') || upperName.contains('ARMENIAN')) {
    return 'AM';
  }
  if (upperName.contains('EX-YU') || upperName.contains('YUGOSLAVIA')) {
    return 'EX';
  }
  if (upperName.contains('KURDISH') || upperName.contains('KURD')) {
    return 'KU';
  }
  if (upperName.contains('CZECH')) {
    return 'CZ';
  }
  
  // Fallback prefix and leading word matches (case-insensitive because we use upperName)
  // E.g., "tr: aksiyon", "[tr] aksiyon", "tr | aksiyon", "tr-aksiyon", "tr aksiyon"
  final cleanUpper = upperName.replaceAll(RegExp(r'[\[\]\(\)]'), ' ').trim();
  if (cleanUpper.isNotEmpty) {
    final firstWord = cleanUpper.split(RegExp(r'[\s:\||\-–\+_]+')).first;
    final knownCodes = {
      'TR': 'TR', 'DE': 'DE', 'CH': 'CH', 'NL': 'NL', 'FR': 'FR', 'IT': 'IT', 
      'EN': 'EN', 'UK': 'EN', 'US': 'EN', 'ES': 'ES', 'PT': 'PT', 'AR': 'AR', 
      'RU': 'RU', 'AZ': 'AZ', 'BG': 'BG', 'PL': 'PL', 'DK': 'DK', 'NO': 'NO', 
      'SE': 'SE', 'BE': 'BE', 'UA': 'UA', 'GR': 'GR', 'RO': 'RO', 'IN': 'IN', 
      'AF': 'AF', 'AL': 'AL', 'AM': 'AM', 'EX': 'EX', 'KU': 'KU', 'CZ': 'CZ'
    };
    if (knownCodes.containsKey(firstWord)) {
      return knownCodes[firstWord];
    }
  }
  
  // Traditional regex fallback using upperName
  final match = RegExp(r'^([A-Z]{2,4})\s*[:\||\-–]\s*').firstMatch(upperName) ??
                RegExp(r'^\[([A-Z]{2,4})\]\s*').firstMatch(upperName);
  if (match != null) {
    return (match.group(1) ?? match.group(2));
  }
  return null;
}

String countryLabelOf(String code) {
  final Map<String, String> countryMap = {
    'TR': '🇹🇷 TÜRK',
    'DE': '🇩🇪 DEUTSCH',
    'CH': '🇨🇭 SWISS',
    'NL': '🇳🇱 DUTCH',
    'EN': '🇬🇧 ENGLISH',
    'FR': '🇫🇷 FRENCH',
    'IT': '🇮🇹 ITALIAN',
    'ES': '🇪🇸 SPANISH',
    'PT': '🇵🇹 PORTUGUESE',
    'AR': '🇸🇦 ARABIC',
    'RU': '🇷🇺 RUSSIAN',
    'AZ': '🇦🇿 AZERBAIJANI',
    'BG': '🇧🇬 BULGARIAN',
    'PL': '🇵🇱 POLISH',
    'DK': '🇩🇰 DANISH',
    'NO': '🇳🇴 NORWEGIAN',
    'SE': '🇸🇪 SWEDISH',
    'BE': '🇧🇪 BELGIAN',
    'UA': '🇺🇦 UKRAINIAN',
    'GR': '🇬🇷 GREEK',
    'RO': '🇷🇴 ROMANIAN',
    'IN': '🇮🇳 INDIAN',
    'AF': '🌍 AFRICA',
    'AL': '🇦🇱 ALBANIAN',
    'AM': '🇦🇲 ARMENIAN',
    'EX': '🇪🇺 EX-YU',
    'KU': '☀️ KURDISH',
    'CZ': '🇨🇿 CZECH',
  };
  return countryMap[code.toUpperCase()] ?? '🌐 ${code.toUpperCase()}';
}

String normalizeTurkish(String text) {
  return text
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('i̇', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');
}

bool isDailySeriesCategory(String name) {
  final norm = normalizeTurkish(name);
  return norm.contains('pazartesi') || 
         norm.contains('sali') || 
         norm.contains('carsamba') || 
         norm.contains('persembe') || 
         norm.contains('cuma') || 
         norm.contains('cumartesi') || 
         norm.contains('pazar') || 
         norm.contains('gunluk') || 
         norm.contains('daily');
}

String dailySeriesBaseName(String name) {
  var cleaned = name;
  
  // Remove parenthesized or bracketed info like (Final), (Yeni), [1080p]
  cleaned = cleaned.replaceAll(RegExp(r'[\(\[][^\)\]]*(?:final|yeni|new|fhd|hd|1080p|720p)[^\)\]]*[\)\]]', caseSensitive: false), '');
  
  // Strip patterns like "1. Bölüm", "125. Bölüm", "Bölüm 12", "12.Bölüm", "12. Bolum", "S01E02", "E02", "Ep 5", "Episode 12"
  cleaned = cleaned.replaceFirst(RegExp(r'\b(?:s\d+\s*e\d+|e\d+|ep(?:isode)?\s*\d+|\d+\.?\s*(?:bölüm|bolum|ep)\b|(?:bölüm|bolum|ep)\s*\d+)', caseSensitive: false), '');
  
  // Strip trailing space + digit (representing episode number)
  cleaned = cleaned.replaceFirst(RegExp(r'\s+\d+$'), '');
  
  // Clean up any remaining trailing punctuation/spaces
  cleaned = cleaned.replaceAll(RegExp(r'\s+[\-\|]\s*$'), ''); // strip trailing dash/pipe
  return cleaned.trim();
}

int extractEpisodeNumber(String name) {
  final match = RegExp(
    r'\b(?:bölüm|bolum|ep|episode)\s*(\d+)|\b(\d+)\.?\s*(?:bölüm|bolum|ep)\b',
    caseSensitive: false,
  ).firstMatch(name);

  if (match != null) {
    final numStr = match.group(1) ?? match.group(2);
    if (numStr != null) {
      return int.tryParse(numStr) ?? 999999;
    }
  }

  final trailingMatch = RegExp(r'\b(\d+)\s*$').firstMatch(name);
  if (trailingMatch != null) {
    return int.tryParse(trailingMatch.group(1)!) ?? 999999;
  }

  return 999999;
}

// A channel with all of its quality / backup variations, best first.
class GroupedLiveChannel {
  final String baseName;
  final List<IptvLiveChannel> variations;
  GroupedLiveChannel({required this.baseName, required this.variations});
  IptvLiveChannel get mainChannel => variations.first;
}

List<GroupedLiveChannel> groupChannelVariants(Iterable<IptvLiveChannel> channels) {
  final Map<String, List<IptvLiveChannel>> groups = {};
  for (final channel in channels) {
    final groupKey = '${channel.categoryId}_${channel.baseName}';
    groups.putIfAbsent(groupKey, () => []).add(channel);
  }

  final priority = ['fhd', '1080p', 'hd', '720p', 'hq', 'hevc', 'h265', 'sd', 'yedek', 'backup', 'alt'];
  int getPriority(String label) {
    final cleaned = label.toLowerCase();
    for (int i = 0; i < priority.length; i++) {
      if (cleaned.contains(priority[i])) {
        return i;
      }
    }
    return priority.length;
  }

  final List<GroupedLiveChannel> groupedList = [];
  groups.forEach((groupKey, variations) {
    variations.sort((a, b) {
      final pA = getPriority(a.qualityLabel);
      final pB = getPriority(b.qualityLabel);
      if (pA != pB) return pA.compareTo(pB);
      return a.displayName.compareTo(b.displayName);
    });
    groupedList.add(GroupedLiveChannel(baseName: variations.first.baseName, variations: variations));
  });

  groupedList.sort((a, b) => a.mainChannel.num.compareTo(b.mainChannel.num));
  return groupedList;
}
