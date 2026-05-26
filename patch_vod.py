import re

path = 'lib/presentation/controllers/vod_matcher_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix AsianContentFilter calls
content = content.replace(
    "AsianContentFilter.isAsianContent(tmdbMovie.title)",
    "AsianContentFilter.isAsianContent(tmdbMovie.title, originalLanguage: tmdbMovie.originalLanguage)"
)
content = content.replace(
    "AsianContentFilter.isAsianContent(tmdbSeries.name)",
    "AsianContentFilter.isAsianContent(tmdbSeries.name, originalLanguage: tmdbSeries.originalLanguage)"
)

# Sort logic to insert before `return matched;` for movie providers
# We need to find all `  return matched;\n});` and `  return matched;\n}` in helpers.
# Actually, the sort logic needs `ref.read(languageProvider)` or `ref.watch(languageProvider)`.
# All providers already have `ref`.

sort_movie = """  final appLang = ref.watch(languageProvider);
  matched.sort((a, b) {
    final aLang = a.tmdbMovie.originalLanguage;
    final bLang = b.tmdbMovie.originalLanguage;
    if (aLang == appLang && bLang != appLang) return -1;
    if (aLang != appLang && bLang == appLang) return 1;
    return 0;
  });
  return matched;"""

sort_series = """  final appLang = ref.watch(languageProvider);
  matched.sort((a, b) {
    final aLang = a.tmdbSeries.originalLanguage;
    final bLang = b.tmdbSeries.originalLanguage;
    if (aLang == appLang && bLang != appLang) return -1;
    if (aLang != appLang && bLang == appLang) return 1;
    return 0;
  });
  return matched;"""

# For trendingMoviesProvider
content = re.sub(r'  return matched;\n\}\);', lambda m: sort_movie + '\n});', content, count=1)
# For trendingSeriesProvider
content = re.sub(r'  return matched;\n\}\);', lambda m: sort_series + '\n});', content, count=1)

# For _matchMoviesHelper
content = re.sub(r'  return matched;\n\}', lambda m: sort_movie + '\n}', content, count=1)
# For _matchSeriesHelper
content = re.sub(r'  return matched;\n\}', lambda m: sort_series + '\n}', content, count=1)

# Add languageProvider import if missing
if "import 'language_provider.dart';" not in content:
    content = content.replace("import 'iptv_controller.dart';", "import 'iptv_controller.dart';\nimport 'language_provider.dart';")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Patched vod_matcher_provider.dart")
