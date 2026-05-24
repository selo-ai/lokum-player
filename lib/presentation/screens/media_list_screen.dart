import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../data/models/iptv_models.dart';
import '../controllers/iptv_controller.dart';
import '../controllers/providers.dart';
import '../controllers/language_provider.dart';
import 'player_screen.dart';

const String RECENTLY_ADDED_ID = 'RECENTLY_ADDED_CUSTOM_ID';

class VirtualDailySeries {
  final String baseName;
  final IptvMovie representative;
  final List<IptvMovie> episodes;

  VirtualDailySeries({
    required this.baseName,
    required this.representative,
    required this.episodes,
  });
}

class MediaListScreen extends ConsumerStatefulWidget {
  final String contentType; // 'live', 'movie', 'series'

  const MediaListScreen({super.key, required this.contentType});

  @override
  ConsumerState<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends ConsumerState<MediaListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;
  bool _showOnlyFavorites = false;
  final Set<String> _expandedCountries = {};
  int _movieGridColumns = 2; // Default to 2-column layout (can be 2, 3, or 4)
  int _seriesGridColumns = 2; // Default to 2-column layout for series (can be 2, 3, or 4)
  int _liveGridColumns = 1; // Default to list layout for Live TV

  @override
  void initState() {
    super.initState();
    // Reset search on navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(iptvControllerProvider.notifier).setSearchQuery('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _getCountryCode(String name) {
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

  String _getCountryLabel(String code) {
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

  String _normalizeCategoryName(String text) {
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

  bool _isDailySeriesCategory(String name) {
    final norm = _normalizeCategoryName(name);
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

  String _getDailySeriesBaseName(String name) {
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

  int _extractEpisodeNumber(String name) {
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

  void _showDailySeriesEpisodesSheet(BuildContext context, VirtualDailySeries series) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DailySeriesDetailSheet(series: series);
      },
    );
  }

  Widget _buildCategoryDrawer(
    List<dynamic> categories,
    dynamic controller,
    int recentCount,
  ) {
    // Group categories by country code
    final Map<String, List<dynamic>> countryGroups = {};
    final List<dynamic> genelCategories = [];

    for (final cat in categories) {
      if (cat.id.isEmpty || cat.name == 'Tümü') continue;
      final code = _getCountryCode(cat.name);
      if (code != null) {
        final upperCode = code.toUpperCase();
        countryGroups.putIfAbsent(upperCode, () => []).add(cat);
      } else {
        genelCategories.add(cat);
      }
    }

    // Sort country codes (TR first, then by sub-category count descending)
    final sortedCountryCodes = countryGroups.keys.toList()
      ..sort((a, b) {
        if (a == 'TR') return -1;
        if (b == 'TR') return 1;
        return countryGroups[b]!.length.compareTo(countryGroups[a]!.length);
      });

    final String allText = ref.tr('category_all');
    final String titleText = ref.tr('category_title');
    
    // Group VOD categories
    final List<dynamic> yeniCategories = [];
    final List<dynamic> imdbCategories = [];
    final Map<String, List<dynamic>> vodGroups = {
      'GÜNLÜK DİZİLER': [],
      'TÜRKÇE': [],
      'DEUTSCHE': [],
      'GENEL / DİĞER': [],
      'MULTİ SERİES': [],
    };
    
    if (widget.contentType != 'live') {
      for (final cat in categories) {
        if (cat.id.isEmpty || cat.name == 'Tümü') continue;
        
        final norm = _normalizeCategoryName(cat.name);
        
        final isGerman = norm.contains('deutsch') || 
                         norm.contains('german') || 
                         norm == 'de' || 
                         norm.startsWith('de ') || 
                         norm.startsWith('de-') || 
                         norm.startsWith('de|') || 
                         norm.contains(' de ') || 
                         norm.contains(' de-') || 
                         norm.contains(' de|') || 
                         norm.contains('alman');

        final isPlatform = norm.contains('disney') || 
                           norm.contains('exxen') || 
                           norm.contains('mubi') || 
                           norm.contains('netflix') || 
                           norm.contains('blutv') || 
                           norm.contains('amazon') || 
                           norm.contains('prime') || 
                           norm.contains('tabii') || 
                           norm.contains('gain') || 
                           norm.contains('apple') || 
                           norm.contains('tod');

        if (norm.contains('imdb')) {
          imdbCategories.add(cat);
        } else if (norm.contains('yeni') || norm.contains('new') || norm.contains('guncel') || norm.contains('2024') || norm.contains('2025') || norm.contains('2026')) {
          yeniCategories.add(cat);
        } else if (norm.contains('pazartesi') || 
                   norm.contains('sali') || 
                   norm.contains('carsamba') || 
                   norm.contains('persembe') || 
                   norm.contains('cuma') || 
                   norm.contains('cumartesi') || 
                   norm.contains('pazar') || 
                   norm.contains('gunluk') || 
                   norm.contains('daily')) {
          vodGroups['GÜNLÜK DİZİLER']!.add(cat);
        } else if (norm.contains('multi') || norm.contains('multı')) {
          vodGroups['MULTİ SERİES']!.add(cat);
        } else if (isPlatform) {
          if (isGerman) {
            vodGroups['DEUTSCHE']!.add(cat);
          } else {
            vodGroups['TÜRKÇE']!.add(cat);
          }
        } else if (norm == 'tr' || 
                   norm.startsWith('tr ') || 
                   norm.startsWith('tr-') || 
                   norm.startsWith('tr|') || 
                   norm.contains(' tr ') || 
                   norm.contains(' tr-') || 
                   norm.contains(' tr|') || 
                   norm.contains('turk') || 
                   norm.contains('yerli')) {
          vodGroups['TÜRKÇE']!.add(cat);
        } else if (isGerman) {
          vodGroups['DEUTSCHE']!.add(cat);
        } else {
          vodGroups['GENEL / DİĞER']!.add(cat);
        }
      }
    }
    
    final selectedCatId = widget.contentType == 'live' 
        ? ref.watch(iptvControllerProvider).selectedLiveCategoryId
        : (widget.contentType == 'movie'
            ? ref.watch(iptvControllerProvider).selectedMovieCategoryId
            : ref.watch(iptvControllerProvider).selectedSeriesCategoryId);

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Stack(
        children: [
          // Glassmorphic Backdrop Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.85),
                  border: const Border(
                    right: BorderSide(color: AppColors.borderLight, width: 1),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drawer Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      const Icon(Icons.list_rounded, color: AppColors.primary, size: 26),
                      const SizedBox(width: 12),
                      Text(
                        titleText.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.borderDark, height: 1),

                // Categories List with Accordion
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      // "TÜMÜ" item
                      _buildDrawerCategoryItem(
                        title: '📺  ${allText.toUpperCase()}',
                        isSelected: selectedCatId.isEmpty,
                        onTap: () {
                          if (widget.contentType == 'live') {
                            controller.selectLiveCategory('');
                          } else if (widget.contentType == 'movie') {
                            controller.selectMovieCategory('');
                          } else {
                            controller.selectSeriesCategory('');
                          }
                          Navigator.of(context).pop();
                        },
                      ),
                      if (widget.contentType != 'live') ...[
                        _buildDrawerCategoryItem(
                          title: '🔥 SON EKLENENLER',
                          isSelected: selectedCatId == RECENTLY_ADDED_ID,
                          onTap: () {
                            if (widget.contentType == 'movie') {
                              controller.selectMovieCategory(RECENTLY_ADDED_ID);
                            } else {
                              controller.selectSeriesCategory(RECENTLY_ADDED_ID);
                            }
                            Navigator.of(context).pop();
                          },
                          trailing: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: AppColors.background,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Row(
                                    children: [
                                      const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      const Text('Bilgi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  content: Text(
                                    'Son eklenen $recentCount içerik gösterilmektedir. Sayıyı değiştirmek için ayarlar sayfasına gidebilirsiniz.',
                                    style: const TextStyle(color: AppColors.textSecondary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('Tamam'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Yeni Categories (Flat Links)
                        ...yeniCategories.map((cat) {
                          final isSelected = cat.id == selectedCatId;
                          return _buildDrawerCategoryItem(
                            title: cat.name,
                            isSelected: isSelected,
                            onTap: () {
                              if (widget.contentType == 'movie') {
                                controller.selectMovieCategory(cat.id);
                              } else {
                                controller.selectSeriesCategory(cat.id);
                              }
                              Navigator.of(context).pop();
                            },
                          );
                        }),
                        if (yeniCategories.isNotEmpty) const SizedBox(height: 4),

                        // IMDb Categories (Flat Links)
                        ...imdbCategories.map((cat) {
                          final isSelected = cat.id == selectedCatId;
                          final cleanTitle = cat.name.replaceFirst(RegExp(r'^(TR\s*[\-\|]?\s*|TÜRK\s*|TURK\s*)', caseSensitive: false), '').trim();
                          return _buildDrawerCategoryItem(
                            title: cleanTitle,
                            isSelected: isSelected,
                            onTap: () {
                              if (widget.contentType == 'movie') {
                                controller.selectMovieCategory(cat.id);
                              } else {
                                controller.selectSeriesCategory(cat.id);
                              }
                              Navigator.of(context).pop();
                            },
                          );
                        }),
                        if (imdbCategories.isNotEmpty) const SizedBox(height: 4),

                        // VOD Categories with Accordion
                        ...vodGroups.entries.where((e) => e.value.isNotEmpty).map((entry) {
                          final label = entry.key;
                          final subcats = entry.value;
                          final isExpanded = _expandedCountries.contains(label);
                          final hasSelectedChild = subcats.any((c) => c.id == selectedCatId);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Group header (tap to expand/collapse)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasSelectedChild
                                      ? AppColors.primary.withOpacity(0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedCountries.remove(label);
                                      } else {
                                        _expandedCountries.add(label);
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: hasSelectedChild ? Colors.white : AppColors.textSecondary,
                                              fontWeight: hasSelectedChild ? FontWeight.bold : FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        // Category count badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceLight.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${subcats.length}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.25 : 0,
                                          duration: const Duration(milliseconds: 200),
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            color: hasSelectedChild ? AppColors.primary : AppColors.textMuted,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Sub-categories (animated expand)
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Column(
                                  children: subcats.map((cat) {
                                    final isSelected = cat.id == selectedCatId;
                                    String displayName = cat.name;
                                    if (label == 'TÜRKÇE') {
                                      displayName = cat.name.replaceFirst(RegExp(r'^(TR\s*[\-\|]?\s*|TÜRK\s*|TURK\s*)', caseSensitive: false), '').trim();
                                    } else if (label == 'DEUTSCHE') {
                                      displayName = cat.name.replaceFirst(RegExp(r'^(DE\s*[\-\|]?\s*|ALMAN\s*|DEUTSCHE\s*|GERMAN\s*)', caseSensitive: false), '').trim();
                                    }
                                    return _buildDrawerCategoryItem(
                                      title: displayName,
                                      isSelected: isSelected,
                                      indent: true,
                                      onTap: () {
                                        if (widget.contentType == 'movie') {
                                          controller.selectMovieCategory(cat.id);
                                        } else {
                                          controller.selectSeriesCategory(cat.id);
                                        }
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }).toList(),
                                ),
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 200),
                              ),
                            ],
                          );
                        }),
                      ] else ...[
                        // Country accordion groups for Live TV
                        ...sortedCountryCodes.map((code) {
                        final label = _getCountryLabel(code);
                        final subcats = countryGroups[code]!;
                        final isExpanded = _expandedCountries.contains(code);
                        // Check if any sub-category in this group is selected
                        final hasSelectedChild = subcats.any((c) => c.id == selectedCatId);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Country header (tap to expand/collapse)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: hasSelectedChild
                                    ? AppColors.primary.withOpacity(0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedCountries.remove(code);
                                    } else {
                                      _expandedCountries.add(code);
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            color: hasSelectedChild ? Colors.white : AppColors.textSecondary,
                                            fontWeight: hasSelectedChild ? FontWeight.bold : FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      // Category count badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceLight.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${subcats.length}',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.25 : 0,
                                        duration: const Duration(milliseconds: 200),
                                        child: Icon(
                                          Icons.chevron_right_rounded,
                                          color: hasSelectedChild ? AppColors.primary : AppColors.textMuted,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Sub-categories (animated expand)
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Column(
                                children: subcats.map((cat) {
                                  final isSelected = cat.id == selectedCatId;
                                  return _buildDrawerCategoryItem(
                                    title: cat.name,
                                    isSelected: isSelected,
                                    indent: true,
                                    onTap: () {
                                      controller.selectLiveCategory(cat.id);
                                      Navigator.of(context).pop();
                                    },
                                  );
                                }).toList(),
                              ),
                              crossFadeState: isExpanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 200),
                            ),
                          ],
                        );
                      }),

                      // "GENEL" group if uncategorized items exist
                      if (genelCategories.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Builder(builder: (context) {
                          final isExpanded = _expandedCountries.contains('GENEL');
                          final hasSelectedChild = genelCategories.any((c) => c.id == selectedCatId);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasSelectedChild
                                      ? AppColors.primary.withOpacity(0.08)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedCountries.remove('GENEL');
                                      } else {
                                        _expandedCountries.add('GENEL');
                                      }
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '🌐 GENEL',
                                            style: TextStyle(
                                              color: hasSelectedChild ? Colors.white : AppColors.textSecondary,
                                              fontWeight: hasSelectedChild ? FontWeight.bold : FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceLight.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${genelCategories.length}',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        AnimatedRotation(
                                          turns: isExpanded ? 0.25 : 0,
                                          duration: const Duration(milliseconds: 200),
                                          child: Icon(
                                            Icons.chevron_right_rounded,
                                            color: hasSelectedChild ? AppColors.primary : AppColors.textMuted,
                                            size: 20,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Column(
                                  children: genelCategories.map((cat) {
                                    final isSelected = cat.id == selectedCatId;
                                    return _buildDrawerCategoryItem(
                                      title: cat.name,
                                      isSelected: isSelected,
                                      indent: true,
                                      onTap: () {
                                        controller.selectLiveCategory(cat.id);
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  }).toList(),
                                ),
                                crossFadeState: isExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 200),
                              ),
                            ],
                          );
                        }),
                      ],
                    ], // Closes else ...[
                  ], // Closes children: [
                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerCategoryItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool indent = false,
    Widget? trailing,
  }) {
    return Container(
      margin: EdgeInsets.only(left: indent ? 28 : 12, right: 12, top: 1, bottom: 1),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.primary.withOpacity(0.4) : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.circle_outlined,
                color: isSelected ? AppColors.primary : AppColors.textMuted.withOpacity(0.5),
                size: indent ? 14 : 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: indent ? 12.5 : 14,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _selectCategory(dynamic controller, String catId) {
    if (widget.contentType == 'live') {
      controller.selectLiveCategory(catId);
    } else if (widget.contentType == 'movie') {
      controller.selectMovieCategory(catId);
    } else {
      controller.selectSeriesCategory(catId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iptvControllerProvider);
    final controller = ref.read(iptvControllerProvider.notifier);
    final int recentCount = ref.watch(recentCountProvider);

    // Get daily series category IDs from state.movieCategories
    final dailySeriesCategoryIds = state.movieCategories
        .where((cat) => _isDailySeriesCategory(cat.name))
        .map((cat) => cat.id)
        .toSet();

    // Get current lists and categories
    final List<dynamic> categories;
    List<dynamic> filteredItems;

    if (widget.contentType == 'live') {
      categories = state.liveCategories;

      filteredItems = controller.getFilteredLiveChannels();
      if (_showOnlyFavorites) {
        final favorites = state.favoriteLive;
        filteredItems = filteredItems.where((item) => favorites.any((f) => f.streamId == item.streamId)).toList();
      }
    } else if (widget.contentType == 'movie') {
      // Movies: exclude daily series categories
      categories = state.movieCategories.where((cat) => !dailySeriesCategoryIds.contains(cat.id)).toList();

      final selectedMovieCatId = state.selectedMovieCategoryId;
      
      if (selectedMovieCatId == RECENTLY_ADDED_ID) {
        final allMovies = List<IptvMovie>.from(state.movies.where((m) => !dailySeriesCategoryIds.contains(m.categoryId)));
        allMovies.sort((a, b) {
          final d1 = a.addedDate;
          final d2 = b.addedDate;
          if (d1 == null && d2 == null) return 0;
          if (d1 == null) return 1;
          if (d2 == null) return -1;
          return d2.compareTo(d1);
        });
        filteredItems = allMovies.take(recentCount).toList();
      } else {
        filteredItems = controller.getFilteredMovies()
            .where((m) => !dailySeriesCategoryIds.contains(m.categoryId))
            .toList();
      }
      
      if (_showOnlyFavorites) {
        final favorites = state.favoriteMovies;
        filteredItems = filteredItems.where((item) => favorites.any((f) => f.streamId == item.streamId)).toList();
      }
    } else {
      // Series: include series categories PLUS daily series categories from movies
      final dailySeriesCats = state.movieCategories.where((cat) => _isDailySeriesCategory(cat.name)).toList();
      categories = [...state.seriesCategories, ...dailySeriesCats];

      final selectedSeriesCatId = state.selectedSeriesCategoryId;
      final query = state.searchQuery.toLowerCase();

      // Grouping helper
      List<dynamic> groupDailySeries(List<IptvMovie> movies) {
        final Map<String, List<IptvMovie>> grouped = {};
        for (final m in movies) {
          final baseName = _getDailySeriesBaseName(m.name);
          grouped.putIfAbsent(baseName, () => []).add(m);
        }
        
        return grouped.entries.map((e) {
          final baseName = e.key;
          final episodes = e.value;
          episodes.sort((a, b) => _extractEpisodeNumber(a.name).compareTo(_extractEpisodeNumber(b.name)));
          return VirtualDailySeries(
            baseName: baseName,
            representative: episodes.first,
            episodes: episodes,
          );
        }).toList();
      }

      if (selectedSeriesCatId == RECENTLY_ADDED_ID) {
        final allSeries = List<IptvSeries>.from(state.series);
        allSeries.sort((a, b) {
          final d1 = a.addedDate;
          final d2 = b.addedDate;
          if (d1 == null && d2 == null) return 0;
          if (d1 == null) return 1;
          if (d2 == null) return -1;
          return d2.compareTo(d1);
        });
        filteredItems = allSeries.take(recentCount).toList();
      } else if (selectedSeriesCatId.isEmpty) {
        // "Tümü" - show normal series AND grouped daily series movies
        final regularSeries = controller.getFilteredSeries();
        final dailySeriesMovies = state.movies.where((m) {
          final matchesCategory = dailySeriesCategoryIds.contains(m.categoryId);
          final matchesSearch = query.isEmpty || m.name.toLowerCase().contains(query);
          return matchesCategory && matchesSearch;
        }).toList();
        
        final groupedDailySeries = groupDailySeries(dailySeriesMovies);
        filteredItems = [...regularSeries, ...groupedDailySeries];
      } else if (dailySeriesCategoryIds.contains(selectedSeriesCatId)) {
        // Daily series category selected - show grouped daily series movies in that category
        final dailySeriesMovies = state.movies.where((m) {
          final matchesCategory = m.categoryId == selectedSeriesCatId;
          final matchesSearch = query.isEmpty || m.name.toLowerCase().contains(query);
          return matchesCategory && matchesSearch;
        }).toList();
        
        filteredItems = groupDailySeries(dailySeriesMovies);
      } else {
        // Normal series category selected
        filteredItems = controller.getFilteredSeries();
      }

      if (_showOnlyFavorites) {
        filteredItems = filteredItems.where((item) {
          if (item is IptvMovie) {
            return state.favoriteMovies.any((f) => f.streamId == item.streamId);
          } else if (item is VirtualDailySeries) {
            return item.episodes.any((ep) => state.favoriteMovies.any((f) => f.streamId == ep.streamId));
          } else {
            return state.favoriteSeries.any((f) => f.seriesId == item.seriesId);
          }
        }).toList();
      }
    }

    // Header always shows 'KATEGORİLER' for live
    final String activeCategoryName = ref.tr('category_title');

    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: categories.isNotEmpty ? _buildCategoryDrawer(categories, controller, recentCount) : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Search Bar & Header Overhaul
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _isSearchActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                firstChild: Row(
                  children: [
                      // Hamburger menu icon + KATEGORİLER text
                      Builder(
                        builder: (context) => InkWell(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.menu_rounded, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  activeCategoryName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Favorites Toggle button (Compact Glass Icon)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showOnlyFavorites = !_showOnlyFavorites;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _showOnlyFavorites ? AppColors.warning.withOpacity(0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _showOnlyFavorites ? AppColors.warning.withOpacity(0.5) : AppColors.borderDark,
                          ),
                        ),
                        child: Icon(
                          _showOnlyFavorites ? Icons.star_rounded : Icons.star_border_rounded,
                          color: _showOnlyFavorites ? AppColors.warning : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Grid Columns Toggler (Compact Glass Icon)
                    Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                      ),
                      child: PopupMenuButton<int>(
                        color: AppColors.background.withOpacity(0.9),
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: AppColors.primary.withOpacity(0.3), width: 1),
                        ),
                        tooltip: 'Görünümü Değiştir',
                        offset: const Offset(0, 50),
                        onSelected: (int val) {
                          setState(() {
                            if (widget.contentType == 'movie') {
                              _movieGridColumns = val;
                            } else if (widget.contentType == 'series') {
                              _seriesGridColumns = val;
                            } else if (widget.contentType == 'live') {
                              _liveGridColumns = val;
                            }
                          });
                        },
                          itemBuilder: (BuildContext context) {
                            if (widget.contentType == 'live') {
                              return [
                                PopupMenuItem(value: 0, child: Row(children: [Icon(Icons.view_headline_rounded, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12), const Text('Küçük Liste', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                                PopupMenuItem(value: 1, child: Row(children: [Icon(Icons.view_list_rounded, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12), const Text('Detaylı Liste', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                                const PopupMenuDivider(height: 1),
                                PopupMenuItem(value: 3, child: Row(children: [Icon(Icons.grid_on_rounded, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12), const Text('3\'lü Izgara', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                                PopupMenuItem(value: 4, child: Row(children: [Icon(Icons.view_comfy_rounded, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12), const Text('4\'lü Izgara', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                                PopupMenuItem(value: 5, child: Row(children: [Icon(Icons.apps_rounded, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12), const Text('5\'li Izgara', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                              ];
                            }
                            return [
                              PopupMenuItem(value: 0, child: Row(children: [Icon(Icons.view_headline_rounded, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12), const Text('Küçük Liste', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                              PopupMenuItem(value: 1, child: Row(children: [Icon(Icons.view_list_rounded, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12), const Text('Detaylı Liste', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                              const PopupMenuDivider(height: 1),
                              PopupMenuItem(value: 2, child: Row(children: [Icon(Icons.grid_view_rounded, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12), const Text('2\'li Izgara', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                              PopupMenuItem(value: 3, child: Row(children: [Icon(Icons.view_module_rounded, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12), const Text('3\'lü Izgara', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                              PopupMenuItem(value: 4, child: Row(children: [Icon(Icons.view_comfy_rounded, color: AppColors.textSecondary, size: 20), const SizedBox(width: 12), const Text('4\'lü Izgara', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600))])),
                            ];
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: Icon(
                              () {
                                final col = widget.contentType == 'movie' ? _movieGridColumns : (widget.contentType == 'series' ? _seriesGridColumns : _liveGridColumns);
                                if (col == 0) return Icons.view_headline_rounded;
                                if (col == 1) return Icons.view_list_rounded;
                                if (col == 2) return Icons.grid_view_rounded;
                                if (col == 3) return widget.contentType == 'live' ? Icons.grid_on_rounded : Icons.view_module_rounded;
                                if (col == 4) return Icons.view_comfy_rounded;
                                if (col == 5) return Icons.apps_rounded;
                                return Icons.view_comfy_rounded;
                              }(),
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 10),
                    // Search icon button (Compact Glass Icon)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isSearchActive = true;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                secondChild: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                        onPressed: () {
                          setState(() {
                            _isSearchActive = false;
                            _searchController.clear();
                            controller.setSearchQuery('');
                          });
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            controller.setSearchQuery(val);
                            setState(() {});
                          },
                          autofocus: true,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: ref.tr('search_hint'),
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            controller.setSearchQuery('');
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Content List Grid
            Expanded(
              child: filteredItems.isEmpty
                  ? _buildEmptyState()
                  : widget.contentType == 'live'
                      ? _buildLiveList(filteredItems)
                      : _buildMediaGrid(filteredItems),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showOnlyFavorites ? Icons.star_outline_rounded : Icons.search_off_rounded,
            color: AppColors.textMuted,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyFavorites ? ref.tr('tab_favorites') : ref.tr('media_not_found'),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _showOnlyFavorites
                ? (ref.watch(languageProvider) == AppLanguage.tr
                    ? (widget.contentType == 'live'
                        ? 'Favori canlı kanalınız bulunmamaktadır.'
                        : (widget.contentType == 'movie' ? 'Favori filminiz bulunmamaktadır.' : 'Favori diziniz bulunmamaktadır.'))
                    : ref.watch(languageProvider) == AppLanguage.de
                        ? (widget.contentType == 'live'
                            ? 'Keine Live-Favoriten gefunden.'
                            : (widget.contentType == 'movie' ? 'Keine Film-Favoriten gefunden.' : 'Keine Serien-Favoriten gefunden.'))
                        : (widget.contentType == 'live'
                            ? 'No live favorites found.'
                            : (widget.contentType == 'movie' ? 'No movie favorites found.' : 'No series favorites found.')))
                : ref.tr('media_not_found_desc'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // --- Live TV List View ---
  Widget _buildLiveList(List<dynamic> items) {
    final groupedList = _groupChannels(items);
    
    if (_liveGridColumns <= 1) {
      return ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
        itemCount: groupedList.length,
        itemBuilder: (context, index) {
          final group = groupedList[index];
          return GroupedChannelTile(group: group);
        },
      );
    }
    
    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _liveGridColumns,
        childAspectRatio: 1.0,
        crossAxisSpacing: _liveGridColumns >= 4 ? 8.0 : 12.0,
        mainAxisSpacing: _liveGridColumns >= 4 ? 8.0 : 12.0,
      ),
      itemCount: groupedList.length,
      itemBuilder: (context, index) {
        final group = groupedList[index];
        return GroupedChannelGridTile(group: group, columns: _liveGridColumns);
      },
    );
  }

  List<GroupedLiveChannel> _groupChannels(List<dynamic> items) {
    final channels = items.cast<IptvLiveChannel>();
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
    });    groupedList.sort((a, b) => a.mainChannel.num.compareTo(b.mainChannel.num));
    return groupedList;
  }

  // --- Movie/Series Grid View ---
  Widget _buildMediaGrid(List<dynamic> items) {
    final columns = widget.contentType == 'movie'
        ? _movieGridColumns
        : (widget.contentType == 'series' ? _seriesGridColumns : 2);
        
    if (columns <= 1) {
      return ListView.builder(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
        itemCount: items.length,
        itemBuilder: (context, index) {
          if (columns == 0) {
            return _buildCompactMediaListItem(items[index], context);
          } else {
            return _buildMediaListItem(items[index], context);
          }
        },
      );
    }
    
    // Dynamic design scaling variables
    final favRadius = columns >= 4 ? 11.0 : 14.0;
    final favIconSize = columns >= 4 ? 12.0 : 16.0;
    final titleFontSize = columns == 4 ? 10.5 : (columns == 3 ? 12.0 : 13.0);
    final topOffset = columns >= 4 ? 6.0 : 8.0;
    final sideOffset = columns >= 4 ? 6.0 : 8.0;

    return GridView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 90),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 0.72,
        crossAxisSpacing: columns >= 4 ? 8.0 : 12.0,
        mainAxisSpacing: columns >= 4 ? 8.0 : 12.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isMovie = item is IptvMovie;
        final isVirtual = item is VirtualDailySeries;

        final isFav = isMovie
            ? ref.read(iptvControllerProvider).favoriteMovies.any((m) => m.streamId == item.streamId)
            : (isVirtual
                ? item.episodes.any((ep) => ref.read(iptvControllerProvider).favoriteMovies.any((f) => f.streamId == ep.streamId))
                : ref.read(iptvControllerProvider).favoriteSeries.any((s) => s.seriesId == item.seriesId));

        final String? imagePath = isMovie ? item.icon : (isVirtual ? item.representative.icon : item.cover);
        final String name = isMovie ? item.name : (isVirtual ? item.baseName : item.name);
        final String? rating = isMovie ? item.rating : (isVirtual ? item.representative.rating : item.rating);

        return GestureDetector(
          onTap: () {
            if (isMovie) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    mediaId: item.streamId,
                    mediaName: item.name,
                    mediaType: 'movie',
                  ),
                ),
              );
            } else if (isVirtual) {
              _showDailySeriesEpisodesSheet(context, item);
            } else {
              _showSeriesDetails(context, item);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderDark, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  // Poster Image
                  Positioned.fill(
                    child: imagePath != null
                        ? CachedNetworkImage(
                            imageUrl: imagePath,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                            errorWidget: (_, __, ___) => _buildFallbackPoster(name),
                          )
                        : _buildFallbackPoster(name),
                  ),

                  // Rating/Favorite Badges
                  Positioned(
                    top: topOffset,
                    left: sideOffset,
                    right: sideOffset,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Rating Tag (Only display in 2-column mode to keep 3x/4x dense grids clean)
                        if (columns == 2 && rating != null && rating.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.warning, size: 12),
                                const SizedBox(width: 4),
                                Text(rating, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ] else
                          const SizedBox.shrink(),

                        // Favorite Button
                        GestureDetector(
                          onTap: () {
                            if (isMovie) {
                              ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(item);
                            } else if (isVirtual) {
                              final isAnyFav = item.episodes.any((ep) => ref.read(iptvControllerProvider).favoriteMovies.any((f) => f.streamId == ep.streamId));
                              if (isAnyFav) {
                                // Unfavorite all episodes
                                for (final ep in item.episodes) {
                                  final isEpFav = ref.read(iptvControllerProvider).favoriteMovies.any((f) => f.streamId == ep.streamId);
                                  if (isEpFav) {
                                    ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(ep);
                                  }
                                }
                              } else {
                                // Favorite the representative episode
                                ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(item.representative);
                              }
                            } else {
                              ref.read(iptvControllerProvider.notifier).toggleFavoriteSeries(item);
                            }
                          },
                          child: CircleAvatar(
                            radius: favRadius,
                            backgroundColor: Colors.black.withOpacity(0.7),
                            child: Icon(
                              isFav ? Icons.star_rounded : Icons.star_border_rounded,
                              color: isFav ? AppColors.warning : Colors.white,
                              size: favIconSize,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Shadow Overlay & Title
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: titleFontSize),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMediaListItem(dynamic item, BuildContext context) {
    final isMovie = item is IptvMovie;
    final isVirtual = item is VirtualDailySeries;

    final isFav = isMovie
        ? ref.read(iptvControllerProvider).favoriteMovies.any((m) => m.streamId == item.streamId)
        : (isVirtual
            ? item.episodes.any((ep) => ref.read(iptvControllerProvider).favoriteMovies.any((f) => f.streamId == ep.streamId))
            : ref.read(iptvControllerProvider).favoriteSeries.any((s) => s.seriesId == item.seriesId));

    final String? imagePath = isMovie ? item.icon : (isVirtual ? item.representative.icon : item.cover);
    final String name = isMovie ? item.name : (isVirtual ? item.baseName : item.name);
    final String? rating = isMovie ? item.rating : (isVirtual ? item.representative.rating : item.rating);
    final DateTime? addedDate = isMovie ? item.addedDate : (isVirtual ? item.representative.addedDate : item.addedDate);

    return GestureDetector(
      onTap: () {
        if (isMovie) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlayerScreen(
                mediaId: item.streamId,
                mediaName: item.name,
                mediaType: 'movie',
              ),
            ),
          );
        } else if (isVirtual) {
          _showDailySeriesEpisodesSheet(context, item);
        } else {
          _showSeriesDetails(context, item);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark, width: 1),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 135,
                child: imagePath != null
                    ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                        errorWidget: (_, __, ___) => _buildFallbackPoster(name),
                      )
                    : _buildFallbackPoster(name),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  if (rating != null && rating.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                        const SizedBox(width: 4),
                        Text(rating, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (addedDate != null)
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          "Eklendi: ${addedDate.day.toString().padLeft(2, '0')}.${addedDate.month.toString().padLeft(2, '0')}.${addedDate.year}",
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Favorite Button
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () {
                  if (isMovie) {
                    ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(item);
                  } else if (isVirtual) {
                    final isAnyFav = item.episodes.any((ep) => ref.read(iptvControllerProvider).favoriteMovies.any((f) => f.streamId == ep.streamId));
                    if (isAnyFav) {
                      for (final ep in item.episodes) {
                        final isEpFav = ref.read(iptvControllerProvider).favoriteMovies.any((f) => f.streamId == ep.streamId);
                        if (isEpFav) {
                          ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(ep);
                        }
                      }
                    } else {
                      ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(item.representative);
                    }
                  } else {
                    ref.read(iptvControllerProvider.notifier).toggleFavoriteSeries(item);
                  }
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: isFav ? AppColors.warning.withOpacity(0.15) : AppColors.surfaceLight,
                  child: Icon(
                    isFav ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isFav ? AppColors.warning : AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMediaListItem(dynamic item, BuildContext context) {
    final isMovie = item is IptvMovie;
    final isVirtual = item is VirtualDailySeries;

    final isFav = isMovie
        ? ref.read(iptvControllerProvider).favoriteMovies.any((m) => m.streamId == item.streamId)
        : (isVirtual
            ? item.episodes.any((ep) => ref.read(iptvControllerProvider).favoriteMovies.any((f) => f.streamId == ep.streamId))
            : ref.read(iptvControllerProvider).favoriteSeries.any((s) => s.seriesId == item.seriesId));

    final String? imagePath = isMovie ? item.icon : (isVirtual ? item.representative.icon : item.cover);
    final String name = isMovie ? item.name : (isVirtual ? item.baseName : item.name);

    return GestureDetector(
      onTap: () {
        if (isMovie) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PlayerScreen(
                mediaId: item.streamId,
                mediaName: item.name,
                mediaType: 'movie',
              ),
            ),
          );
        } else if (isVirtual) {
          _showDailySeriesEpisodesSheet(context, item);
        } else {
          _showSeriesDetails(context, item);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark, width: 1),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
              child: SizedBox(
                width: 50,
                height: 75,
                child: imagePath != null
                    ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                        errorWidget: (_, __, ___) => _buildFallbackPoster(name),
                      )
                    : _buildFallbackPoster(name),
              ),
            ),
            const SizedBox(width: 14),
            // Details
            Expanded(
              child: Text(
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Favorite Button
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  if (isMovie) {
                    ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(item);
                  } else if (isVirtual) {
                    final isAnyFav = item.episodes.any((ep) => ref.read(iptvControllerProvider).favoriteMovies.any((f) => f.streamId == ep.streamId));
                    if (isAnyFav) {
                      for (final ep in item.episodes) {
                        final isEpFav = ref.read(iptvControllerProvider).favoriteMovies.any((f) => f.streamId == ep.streamId);
                        if (isEpFav) {
                          ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(ep);
                        }
                      }
                    } else {
                      ref.read(iptvControllerProvider.notifier).toggleFavoriteMovie(item.representative);
                    }
                  } else {
                    ref.read(iptvControllerProvider.notifier).toggleFavoriteSeries(item);
                  }
                },
                child: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav ? AppColors.warning : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackPoster(String name) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surfaceLight, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.movie_creation_outlined, color: AppColors.textMuted, size: 36),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Show Series Details / Season / Episode List Bottom Sheet ---
  void _showSeriesDetails(BuildContext context, dynamic serie) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) {
        return SeriesDetailSheet(serie: serie);
      },
    );
  }
}

// Custom Bottom Sheet for Series Detail View
class SeriesDetailSheet extends ConsumerStatefulWidget {
  final dynamic serie;

  const SeriesDetailSheet({required this.serie});

  @override
  ConsumerState<SeriesDetailSheet> createState() => SeriesDetailSheetState();
}

class SeriesDetailSheetState extends ConsumerState<SeriesDetailSheet> {
  List<IptvEpisode> _episodes = [];
  bool _isLoading = true;
  int _selectedSeason = 1;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    final list = await ref.read(iptvControllerProvider.notifier).getEpisodesForSeries(widget.serie.seriesId);
    if (mounted) {
      setState(() {
        _episodes = list;
        _isLoading = false;
        if (list.isNotEmpty) {
          _selectedSeason = list.first.season;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unique list of seasons
    final seasons = _episodes.map((e) => e.season).toSet().toList()..sort();
    final filteredEpisodes = _episodes.where((e) => e.season == _selectedSeason).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Cover image
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(
                  child: widget.serie.cover != null
                      ? CachedNetworkImage(imageUrl: widget.serie.cover!, fit: BoxFit.cover)
                      : Container(color: AppColors.surface),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.background, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 16,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.serie.name,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ref.tr('media_series_label')} • ${widget.serie.releaseDate ?? "2026"}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Series Plot and Detail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text(
              widget.serie.plot ?? ref.tr('series_no_plot'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),

          const Divider(color: AppColors.borderDark, height: 24, thickness: 1),

          // Seasons List
          if (!_isLoading && seasons.isNotEmpty) ...[
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: seasons.length,
                itemBuilder: (ctx, idx) {
                  final season = seasons[idx];
                  final isSelected = season == _selectedSeason;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedSeason = season;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
                        foregroundColor: isSelected ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        ref.watch(languageProvider) == AppLanguage.tr || ref.watch(languageProvider) == AppLanguage.de
                            ? '$season. ${ref.tr('series_season_label')}'
                            : '${ref.tr('series_season_label')} $season',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Episode List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : filteredEpisodes.isEmpty
                    ? Center(child: Text(ref.tr('series_no_episodes')))
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                        itemCount: filteredEpisodes.length,
                        itemBuilder: (ctx, idx) {
                          final ep = filteredEpisodes[idx];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.of(context).pop(); // Close details sheet
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PlayerScreen(
                                      mediaId: ep.streamId,
                                      mediaName: '${widget.serie.name} - S${ep.season.toString().padLeft(2, "0")}E${ep.episodeNum.toString().padLeft(2, "0")}',
                                      mediaType: 'series',
                                      episodeExtension: ep.containerExtension ?? 'mp4',
                                    ),
                                  ),
                                );
                              },
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                              ),
                              title: Text(
                                ref.watch(languageProvider) == AppLanguage.tr || ref.watch(languageProvider) == AppLanguage.de
                                    ? '${ep.episodeNum}. ${ref.tr('series_episode_label')}: ${ep.title.isEmpty ? "${ref.tr('series_episode_label')} ${ep.episodeNum}" : ep.title}'
                                    : '${ref.tr('series_episode_label')} ${ep.episodeNum}: ${ep.title.isEmpty ? "${ref.tr('series_episode_label')} ${ep.episodeNum}" : ep.title}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              subtitle: Text('${ref.tr('series_file')}: .${ep.containerExtension ?? "mp4"}', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Custom Bottom Sheet for Grouped Daily Series Detail View
class DailySeriesDetailSheet extends ConsumerWidget {
  final VirtualDailySeries series;

  const DailySeriesDetailSheet({required this.series});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Cover image
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                Positioned.fill(
                  child: series.representative.icon != null
                      ? CachedNetworkImage(imageUrl: series.representative.icon!, fit: BoxFit.cover)
                      : Container(color: AppColors.surface),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.background, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  bottom: 16,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.baseName,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ref.tr('media_series_label')} • ${series.episodes.length} ${ref.tr('series_episode_label')}',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Series Plot and Detail
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Text(
              '${series.baseName} ${ref.tr('media_series_label').toLowerCase()} - ${series.episodes.length} ${ref.tr('series_episode_label').toLowerCase()}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ),

          const Divider(color: AppColors.borderDark, height: 24, thickness: 1),

          // Episode List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              itemCount: series.episodes.length,
              itemBuilder: (ctx, idx) {
                final ep = series.episodes[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).pop(); // Close details sheet
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            mediaId: ep.streamId,
                            mediaName: ep.name,
                            mediaType: 'movie',
                          ),
                        ),
                      );
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary),
                    ),
                    title: Text(
                      ep.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(ref.tr('series_file') + ': VOD', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- Lazy EPG Loading Widget for Channel List ---
class ChannelEpgText extends ConsumerStatefulWidget {
  final int streamId;
  const ChannelEpgText({super.key, required this.streamId});

  @override
  ConsumerState<ChannelEpgText> createState() => _ChannelEpgTextState();
}

class _ChannelEpgTextState extends ConsumerState<ChannelEpgText> {
  @override
  void initState() {
    super.initState();
    // Fetch EPG after frame completes to avoid Riverpod build cycle exceptions
    Future.microtask(() {
      if (mounted) {
        ref.read(iptvControllerProvider.notifier).fetchEpgForChannel(widget.streamId);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChannelEpgText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamId != widget.streamId) {
      Future.microtask(() {
        if (mounted) {
          ref.read(iptvControllerProvider.notifier).fetchEpgForChannel(widget.streamId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final epgCache = ref.watch(iptvControllerProvider.select((s) => s.epgCache));
    
    // If not in cache or still loading (loading is represented as null in cache)
    if (!epgCache.containsKey(widget.streamId) || epgCache[widget.streamId] == null) {
      return Text(
        'Yükleniyor...',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final epg = epgCache[widget.streamId]!;
    if (epg.title == 'EPG Yok' || epg.title.isEmpty) {
      return Text(
        'Yayın akışı bilgisi yok',
        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
      );
    }

    final startTime = _formatTime(epg.start);
    final endTime = _formatTime(epg.end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          epg.title,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '$startTime - $endTime',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: epg.progress,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

// Grouped Channel Presentation Model
class GroupedLiveChannel {
  final String baseName;
  final List<IptvLiveChannel> variations;
  GroupedLiveChannel({required this.baseName, required this.variations});
  IptvLiveChannel get mainChannel => variations.first;
}

// Accordion Custom Grouped Channel Widget
class GroupedChannelTile extends ConsumerStatefulWidget {
  final GroupedLiveChannel group;
  const GroupedChannelTile({super.key, required this.group});

  @override
  ConsumerState<GroupedChannelTile> createState() => _GroupedChannelTileState();
}

class _GroupedChannelTileState extends ConsumerState<GroupedChannelTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final mainChannel = group.mainChannel;
    final variations = group.variations;
    final hasMultiple = variations.length > 1;

    final isEpgEnabled = ref.watch(epgEnabledProvider);
    final favList = ref.watch(iptvControllerProvider.select((s) => s.favoriteLive));
    final isAnyFav = variations.any((v) => favList.any((c) => c.streamId == v.streamId));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    mediaId: mainChannel.streamId,
                    mediaName: mainChannel.displayName,
                    mediaType: 'live',
                  ),
                ),
              );
            },
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(4),
              child: mainChannel.icon != null && mainChannel.icon!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: mainChannel.icon!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                      ),
                      errorWidget: (_, __, ___) => const Icon(Icons.tv_rounded, color: AppColors.primary),
                    )
                  : const Icon(Icons.tv_rounded, color: AppColors.primary),
            ),
            title: Text(
              group.baseName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: isEpgEnabled ? 14 : 16, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: isEpgEnabled 
                ? Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: ChannelEpgText(streamId: mainChannel.streamId),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasMultiple)
                  IconButton(
                    icon: AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                IconButton(
                  icon: Icon(
                    isAnyFav ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isAnyFav ? AppColors.warning : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    final notifier = ref.read(iptvControllerProvider.notifier);
                    if (isAnyFav) {
                      for (final variation in variations) {
                        final isVarFav = favList.any((c) => c.streamId == variation.streamId);
                        if (isVarFav) {
                          notifier.toggleFavoriteLive(variation);
                        }
                      }
                    } else {
                      notifier.toggleFavoriteLive(mainChannel);
                    }
                  },
                ),
              ],
            ),
          ),
          if (hasMultiple)
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(color: AppColors.borderDark, height: 1, thickness: 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: variations.map((variation) {
                        final isVarFav = favList.any((c) => c.streamId == variation.streamId);
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerScreen(
                                  mediaId: variation.streamId,
                                  mediaName: variation.displayName,
                                  mediaType: 'live',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppColors.primary,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  variation.qualityLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    ref.read(iptvControllerProvider.notifier).toggleFavoriteLive(variation);
                                  },
                                  child: Icon(
                                    isVarFav ? Icons.star_rounded : Icons.star_border_rounded,
                                    color: isVarFav ? AppColors.warning : AppColors.textSecondary,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
        ],
      ),
    );
  }
}

class GroupedChannelGridTile extends ConsumerWidget {
  final GroupedLiveChannel group;
  final int columns;

  const GroupedChannelGridTile({super.key, required this.group, required this.columns});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mainChannel = group.mainChannel;
    final variations = group.variations;
    final hasMultiple = variations.length > 1;

    final favList = ref.watch(iptvControllerProvider.select((s) => s.favoriteLive));
    final isAnyFav = variations.any((v) => favList.any((c) => c.streamId == v.streamId));

    final favRadius = columns >= 4 ? 11.0 : 14.0;
    final favIconSize = columns >= 4 ? 12.0 : 16.0;
    final titleFontSize = columns == 4 ? 10.5 : (columns == 3 ? 12.0 : 13.0);
    final topOffset = columns >= 4 ? 6.0 : 8.0;
    final sideOffset = columns >= 4 ? 6.0 : 8.0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              mediaId: mainChannel.streamId,
              mediaName: mainChannel.displayName,
              mediaType: 'live',
            ),
          ),
        );
      },
      onLongPress: () {
        if (!hasMultiple) return;
        // Show variations sheet
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(group.baseName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...variations.map((v) {
                  return ListTile(
                    title: Text(v.displayName, style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(
                            mediaId: v.streamId,
                            mediaName: v.displayName,
                            mediaType: 'live',
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDark, width: 1),
        ),
        child: Stack(
          children: [
            // Center Logo
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15), // Slightly less than 16 to fit inside border
                child: mainChannel.icon != null && mainChannel.icon!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: mainChannel.icon!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                        errorWidget: (_, __, ___) => _buildFallbackLogo(mainChannel.displayName),
                      )
                    : _buildFallbackLogo(mainChannel.displayName),
              ),
            ),
            // Multi Badge (Bottom Full Width)
            if (hasMultiple)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
                  ),
                  child: Text(
                    'MULTI', 
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white, 
                      fontSize: columns >= 4 ? 8 : 10, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.5
                    ),
                  ),
                ),
              ),
            // Favorite Button
            Positioned(
              top: topOffset,
              right: sideOffset,
              child: GestureDetector(
                onTap: () {
                  if (hasMultiple) {
                    // Toggle favorite for all variations? Or just main? 
                    // Let's do main channel for simplicity if it's a grid click
                    ref.read(iptvControllerProvider.notifier).toggleFavoriteLive(mainChannel);
                  } else {
                    ref.read(iptvControllerProvider.notifier).toggleFavoriteLive(mainChannel);
                  }
                },
                child: CircleAvatar(
                  radius: favRadius,
                  backgroundColor: Colors.black.withOpacity(0.7),
                  child: Icon(
                    isAnyFav ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isAnyFav ? AppColors.warning : Colors.white,
                    size: favIconSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
