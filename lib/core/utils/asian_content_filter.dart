class AsianContentFilter {
  static bool isAsianContent(String? text, {String? originalLanguage}) {
    if (originalLanguage != null) {
      final lang = originalLanguage.toLowerCase();
      final restrictedLangs = ['hi', 'te', 'ta', 'ml', 'kn', 'bn', 'ja', 'ko', 'zh'];
      if (restrictedLangs.contains(lang)) return true;
    }

    if (text == null || text.isEmpty) return false;
    final lower = text.toLowerCase();
    
    // Check for Asian characters (Chinese, Japanese, Korean)
    if (RegExp(r'[\u4e00-\u9fa5\u3040-\u30ff\uac00-\ud7af]').hasMatch(text)) {
      return true;
    }
    
    // Check for specific keywords in titles/categories
    final keywords = ['kore', 'korea', 'asya', 'asian', 'japon', 'japan', 'anime', 'uzakdoğu', 'uzak dogu', 'chinese', 'çin', 'hint', 'indian', 'bollywood', 'hindi', 'telugu', 'tamil'];
    for (final kw in keywords) {
      if (RegExp(r'\b' + kw + r'\b').hasMatch(lower)) {
        return true;
      }
    }
    return false;
  }
}
