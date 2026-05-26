import re

path = 'lib/presentation/controllers/vod_matcher_provider.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Fix AsianContentFilter TMDB usage
content = content.replace(
    "AsianContentFilter.isAsianContent(tmdbMovie.title)",
    "AsianContentFilter.isAsianContent(tmdbMovie.title, originalLanguage: tmdbMovie.originalLanguage)"
)
content = content.replace(
    "AsianContentFilter.isAsianContent(tmdbSeries.name)",
    "AsianContentFilter.isAsianContent(tmdbSeries.name, originalLanguage: tmdbSeries.originalLanguage)"
)

# Function to patch a specific function block
def patch_function(func_name, is_movie):
    global content
    
    # Find the function start
    idx = content.find(func_name)
    if idx == -1: return
    
    # Find the next `return matched;` after this index
    ret_idx = content.find('  return matched;', idx)
    if ret_idx == -1: return
    
    sort_code = f"""  final appLang = ref.watch(languageProvider);
  matched.sort((a, b) {{
    final aLang = a.{'tmdbMovie' if is_movie else 'tmdbSeries'}.originalLanguage;
    final bLang = b.{'tmdbMovie' if is_movie else 'tmdbSeries'}.originalLanguage;
    if (aLang == appLang && bLang != appLang) return -1;
    if (aLang != appLang && bLang == appLang) return 1;
    return 0;
  }});
  return matched;"""
    
    content = content[:ret_idx] + sort_code + content[ret_idx + len('  return matched;'):]

# Patch trending providers
patch_function('final trendingMoviesProvider', True)
patch_function('final trendingSeriesProvider', False)
patch_function('_matchMoviesHelper', True)
patch_function('_matchSeriesHelper', False)
patch_function('_matchDocumentariesHelper', False)

# Note: _matchDocumentariesHelper mixes movies and series!
# Let's handle it manually:
idx_doc = content.find('_matchDocumentariesHelper')
if idx_doc != -1:
    ret_idx = content.find('  return allMatched;', idx_doc)
    if ret_idx != -1:
        sort_code_doc = """  final appLang = ref.watch(languageProvider);
  allMatched.sort((a, b) {
    String aLang = '';
    String bLang = '';
    if (a is MatchedMovie) aLang = a.tmdbMovie.originalLanguage;
    else if (a is MatchedSeries) aLang = a.tmdbSeries.originalLanguage;
    
    if (b is MatchedMovie) bLang = b.tmdbMovie.originalLanguage;
    else if (b is MatchedSeries) bLang = b.tmdbSeries.originalLanguage;
    
    if (aLang == appLang && bLang != appLang) return -1;
    if (aLang != appLang && bLang == appLang) return 1;
    return 0;
  });
  return allMatched;"""
        content = content[:ret_idx] + sort_code_doc + content[ret_idx + len('  return allMatched;'):]

if "import 'language_provider.dart';" not in content:
    content = content.replace("import 'iptv_controller.dart';", "import 'iptv_controller.dart';\nimport 'language_provider.dart';")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Patched vod_matcher_provider.dart successfully")
