// Parser for M3U / M3U Plus playlists (`#EXTM3U` + `#EXTINF` lines).
//
// Works line by line so very large playlists can be parsed as a stream
// without holding the whole file in memory.

class M3uEntry {
  final String name;
  final String url;
  final String? tvgId;
  final String? tvgName;
  final String? tvgLogo;
  final String? groupTitle;
  final int duration;
  final Map<String, String> attributes;

  const M3uEntry({
    required this.name,
    required this.url,
    this.tvgId,
    this.tvgName,
    this.tvgLogo,
    this.groupTitle,
    this.duration = -1,
    this.attributes = const {},
  });

  // Xtream servers put VOD under /movie/ and /series/, live streams elsewhere.
  M3uContentType get contentType {
    final path = Uri.tryParse(url)?.path ?? url;
    if (path.contains('/movie/')) return M3uContentType.movie;
    if (path.contains('/series/')) return M3uContentType.series;
    return M3uContentType.live;
  }
}

enum M3uContentType { live, movie, series }

class M3uParser {
  static final _attribute = RegExp(r'([\w-]+)="([^"]*)"');
  static final _duration = RegExp(r'^#EXTINF:\s*(-?\d+)');

  static List<M3uEntry> parse(String content) {
    return parseLines(content.split('\n')).toList();
  }

  static Stream<M3uEntry> parseStream(Stream<String> lines) async* {
    final parser = _LineParser();
    await for (final line in lines) {
      final entry = parser.add(line);
      if (entry != null) yield entry;
    }
  }

  static Iterable<M3uEntry> parseLines(Iterable<String> lines) sync* {
    final parser = _LineParser();
    for (final line in lines) {
      final entry = parser.add(line);
      if (entry != null) yield entry;
    }
  }

  static M3uEntry _build(String extinf, String? extgrp, String url) {
    final attributes = <String, String>{
      for (final m in _attribute.allMatches(extinf)) m.group(1)!.toLowerCase(): m.group(2)!,
    };
    final name = _displayName(extinf);
    String? attr(String key) {
      final value = attributes[key]?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    return M3uEntry(
      name: name.isNotEmpty ? name : (attr('tvg-name') ?? url),
      url: url,
      tvgId: attr('tvg-id'),
      tvgName: attr('tvg-name'),
      tvgLogo: attr('tvg-logo'),
      groupTitle: attr('group-title') ?? extgrp,
      duration: int.tryParse(_duration.firstMatch(extinf)?.group(1) ?? '') ?? -1,
      attributes: attributes,
    );
  }

  // The title is everything after the first comma that is not inside quotes.
  static String _displayName(String extinf) {
    var inQuotes = false;
    for (var i = 0; i < extinf.length; i++) {
      final c = extinf[i];
      if (c == '"') inQuotes = !inQuotes;
      if (c == ',' && !inQuotes) return extinf.substring(i + 1).trim();
    }
    return '';
  }
}

class _LineParser {
  String? _extinf;
  String? _extgrp;
  bool _first = true;

  M3uEntry? add(String rawLine) {
    var line = rawLine.trim();
    if (_first) {
      _first = false;
      if (line.startsWith('﻿')) line = line.substring(1);
    }
    if (line.isEmpty) return null;

    if (line.startsWith('#EXTINF')) {
      _extinf = line;
      _extgrp = null;
      return null;
    }
    if (line.startsWith('#EXTGRP:')) {
      _extgrp = line.substring('#EXTGRP:'.length).trim();
      return null;
    }
    if (line.startsWith('#')) return null;

    final extinf = _extinf;
    if (extinf == null) return null;
    _extinf = null;
    final entry = M3uParser._build(extinf, _extgrp, line);
    _extgrp = null;
    return entry;
  }
}
