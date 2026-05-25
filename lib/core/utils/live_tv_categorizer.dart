import '../../data/models/iptv_models.dart';

class LiveTvCategorizer {
  /// Groups channels into Country -> Network -> List of Channels
  static Map<String, Map<String, List<IptvLiveChannel>>> categorize(
    List<IptvLiveChannel> channels,
    List<IptvCategory> categories,
  ) {
    // 1. Create a fast lookup for Category ID -> Category Name
    final categoryMap = <String, String>{};
    for (final cat in categories) {
      categoryMap[cat.id] = cat.name;
    }

    final Map<String, Map<String, List<IptvLiveChannel>>> result = {};

    for (final channel in channels) {
      final rawCategoryName = categoryMap[channel.categoryId] ?? 'BİLİNMEYEN';
      
      // Step 1: Determine Country / Main Category
      final mainCategory = _extractMainCategory(rawCategoryName);
      
      // Step 2: Determine Network / Sub Group
      final network = extractNetwork(channel.displayName, mainCategory);

      if (!result.containsKey(mainCategory)) {
        result[mainCategory] = {};
      }
      
      if (!result[mainCategory]!.containsKey(network)) {
        result[mainCategory]![network] = [];
      }
      
      result[mainCategory]![network]!.add(channel);
    }
    
    // Sort networks alphabetically, but push 'DİĞER' to the bottom
    for (final mainCategory in result.keys) {
      final networks = result[mainCategory]!;
      final sortedKeys = networks.keys.toList()..sort((a, b) {
        if (a == 'DİĞER') return 1;
        if (b == 'DİĞER') return -1;
        return a.compareTo(b);
      });
      
      final sortedNetworks = <String, List<IptvLiveChannel>>{};
      for (final key in sortedKeys) {
        sortedNetworks[key] = networks[key]!;
      }
      result[mainCategory] = sortedNetworks;
    }

    // Sort main categories
    final sortedMainKeys = result.keys.toList()..sort((a, b) {
      if (a == 'TÜRKÇE') return -1;
      if (b == 'TÜRKÇE') return 1;
      if (a == 'BİLİNMEYEN') return 1;
      if (b == 'BİLİNMEYEN') return -1;
      return a.compareTo(b);
    });
    
    final sortedResult = <String, Map<String, List<IptvLiveChannel>>>{};
    for (final key in sortedMainKeys) {
      sortedResult[key] = result[key]!;
    }

    return sortedResult;
  }

  static String _extractMainCategory(String rawCategory) {
    final upper = rawCategory.toUpperCase();
    
    // Check Turkish
    if (upper.contains('TR') || upper.contains('TURK') || upper.contains('TÜRK') || upper.contains('TURKEY')) {
      return 'TÜRKÇE';
    }
    // Check German
    if (upper.contains('DE') || upper.contains('GER') || upper.contains('ALMAN')) {
      return 'DEUTSCH';
    }
    // Check French
    if (upper.contains('FR') || upper.contains('FRAN')) {
      return 'FRANCE';
    }
    // Check UK / US / EN
    if (upper.contains('UK') || upper.contains('US') || upper.contains('ENGL') || upper.contains('USA')) {
      return 'ENGLISH';
    }
    // Check NL
    if (upper.contains('NL') || upper.contains('NETHER') || upper.contains('HOLLAN')) {
      return 'NEDERLANDS';
    }
    
    // If it's something like "VIP", "SPORTS" but no country tag, return as is or 'DİĞER'
    // Let's strip special chars and return cleaned name as fallback
    final cleaned = upper.replaceAll(RegExp(r'[^A-Z0-9\s]'), '').trim();
    if (cleaned.isEmpty) return 'DİĞER';
    
    return cleaned;
  }

  static String extractNetwork(String channelName, String mainCategory) {
    final upper = channelName.toUpperCase();
    
    if (upper.contains('BEIN') || upper.contains('BEİN')) {
      if (upper.contains('MOVIES')) return 'BEIN MOVIES';
      if (upper.contains('SERIES')) return 'BEIN SERIES';
      return 'BEIN SPORTS';
    }
    if (upper.contains('EXXEN')) {
      return 'EXXEN';
    }
    if (upper.contains('S SPORT')) {
      return 'S SPORT';
    }
    if (upper.contains('TIVIBU') || upper.contains('TİVİBU')) {
      return 'TİVİBU SPOR';
    }
    if (upper.contains('SMART') || upper.contains('D-SMART') || upper.contains('DSMART')) {
      return 'D-SMART';
    }
    if (upper.contains('TRT')) {
      if (upper.contains('SPOR') || upper.contains('YILDIZ')) return 'TRT SPOR';
      return 'TRT';
    }
    if (upper.contains('SKY')) {
      if (upper.contains('SPORT')) return 'SKY SPORT';
      if (upper.contains('CINEMA')) return 'SKY CINEMA';
      return 'SKY';
    }
    if (upper.contains('CANAL+') || upper.contains('CANAL +')) {
      return 'CANAL+';
    }
    if (upper.contains('ESPN')) {
      return 'ESPN';
    }
    if (upper.contains('FOX')) {
      if (upper.contains('SPORTS')) return 'FOX SPORTS';
      return 'FOX';
    }
    
    // Generic fallback based on common words in Turkish channels
    if (mainCategory == 'TÜRKÇE') {
      if (upper.contains('HABER')) return 'HABER KANALLARI';
      if (upper.contains('BELGESEL') || upper.contains('NAT GEO') || upper.contains('DISCOVERY')) return 'BELGESEL';
      if (upper.contains('SİNEMA') || upper.contains('CINEMA')) return 'SİNEMA';
      if (upper.contains('ÇOCUK') || upper.contains('KIDS') || upper.contains('CARTOON') || upper.contains('DISNEY')) return 'ÇOCUK';
      if (upper.contains('ATV') || upper.contains('KANAL D') || upper.contains('STAR') || upper.contains('SHOW') || upper.contains('TV8')) return 'ULUSAL';
    }

    // Attempt to extract the first word as the network (primitive grouping)
    final parts = upper.split(' ');
    if (parts.isNotEmpty && parts[0].length > 2) {
      return parts[0].replaceAll(RegExp(r'[^A-Z]'), '');
    }
    
    return 'DİĞER';
  }

  static String extractSuperCategory(String categoryOrChannelName) {
    final upper = categoryOrChannelName.toUpperCase();
    
    if (upper.contains('SPOR') || upper.contains('SPORT') || upper.contains('BEIN') || upper.contains('EXXEN') || upper.contains('S SPORT') || upper.contains('TİVİBU') || upper.contains('TIVIBU')) {
      return 'SPOR';
    }
    if (upper.contains('HABER') || upper.contains('NEWS')) {
      return 'HABER';
    }
    if (upper.contains('ÇOCUK') || upper.contains('KIDS') || upper.contains('CARTOON') || upper.contains('DISNEY') || upper.contains('NICKELODEON') || upper.contains('ANIMASYON') || upper.contains('BABY')) {
      return 'ÇOCUK';
    }
    if (upper.contains('BELGESEL') || upper.contains('DOCUMENTARY') || upper.contains('NAT GEO') || upper.contains('ANIMAL') || upper.contains('DISCOVERY') || upper.contains('HISTORY') || upper.contains('WILD')) {
      return 'BELGESEL';
    }
    if (upper.contains('MÜZİK') || upper.contains('MUSIC') || upper.contains('KRAL') || upper.contains('POWER') || upper.contains('MTV') || upper.contains('NUMBER')) {
      return 'MÜZİK';
    }
    if (upper.contains('SİNEMA') || upper.contains('CINEMA') || upper.contains('MOVIE') || upper.contains('FILM') || upper.contains('FİLM')) {
      return 'SİNEMA';
    }
    if (upper.contains('ULUSAL') || upper.contains('ATV') || upper.contains('KANAL D') || upper.contains('STAR') || upper.contains('SHOW') || upper.contains('TV8') || upper.contains('TRT') || upper.contains('FOX') || upper.contains('NOW')) {
      return 'ULUSAL';
    }
    if (upper.contains('RADYO') || upper.contains('RADIO')) {
      return 'RADYO';
    }
    if (upper.contains('XXX') || upper.contains('ADULT') || upper.contains('18+')) {
      return 'YETİŞKİN';
    }
    
    return 'DİĞER';
  }
}
