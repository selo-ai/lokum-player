import os
import re
import glob

# Python script to replace PlayerScreen navigation for series with showSeriesDetailSheet

screens_dir = 'lib/presentation/screens'
files = glob.glob(f"{screens_dir}/*.dart")

# Examples we need to replace:
# Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(mediaId: matched.seriesId, mediaName: tmdb.name, mediaType: 'series')));
# Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(mediaId: item.seriesId, mediaName: item.name, mediaType: 'series')));

regex_nav = r"Navigator\.push\s*\(\s*context,\s*MaterialPageRoute\s*\(\s*builder:\s*\(\_\)\s*=>\s*PlayerScreen\s*\(\s*mediaId:\s*([^,]+),\s*mediaName:\s*([^,]+),\s*mediaType:\s*'series'\s*\)\s*\)\s*\)"

def patch_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # We need to map `matched` or `item` to the tmdb object so we can pass posterUrl, description, rating, year
    # Often it looks like this:
    # final matched = items[index];
    # final tmdb = matched.tmdbSeries;
    # We can just extract variables heuristically or write a generic replacement if we can't.
    # If the file imports `series_detail_sheet.dart`, we are good.
    
    # In action_room_screen.dart and others:
    # onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(mediaId: matched.seriesId, mediaName: tmdb.name, mediaType: 'series'))),
    
    # Replacement string
    def repl(m):
        mediaId = m.group(1).strip()
        mediaName = m.group(2).strip()
        
        # Determine the tmdb variable based on mediaName (e.g. tmdb.name -> tmdb)
        tmdb_var = 'tmdb'
        if mediaName.startswith('tmdb.'):
            tmdb_var = 'tmdb'
        elif mediaName.startswith('item.'):
            tmdb_var = 'item' # if it's IptvSeries, it might not have overview/posterUrl easily accessible here
            
        if 'tmdb' in mediaName or 'tmdb' in content[m.start()-50:m.start()]:
            return f"showSeriesDetailSheet(context, seriesId: {mediaId}, name: {mediaName}, posterUrl: tmdb.posterUrl, description: tmdb.overview, rating: tmdb.voteAverage.toStringAsFixed(1), year: tmdb.firstAirDate.length >= 4 ? tmdb.firstAirDate.substring(0, 4) : null)"
        elif 'item' in mediaId and ('IptvSeries' in content or 'dynamic' in content):
            # Fallback for media_list_screen.dart where item is IptvSeries
            return f"showSeriesDetailSheet(context, seriesId: {mediaId}, name: {mediaName}, posterUrl: item.cover)"
        else:
            return f"showSeriesDetailSheet(context, seriesId: {mediaId}, name: {mediaName})"

    new_content = re.sub(regex_nav, repl, content)
    
    # Special handling for search_screen.dart:
    # Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(mediaId: item.seriesId, mediaName: item.name, mediaType: 'series')))
    
    if new_content != original_content:
        # Add import if missing
        if "import '../widgets/series_detail_sheet.dart';" not in new_content:
            new_content = new_content.replace(
                "import '../widgets/movie_detail_sheet.dart';", 
                "import '../widgets/movie_detail_sheet.dart';\nimport '../widgets/series_detail_sheet.dart';"
            )
            # If movie_detail_sheet is not imported, insert it after flutter/material.dart
            if "import '../widgets/movie_detail_sheet.dart';" not in original_content:
                new_content = new_content.replace(
                    "import 'package:flutter/material.dart';",
                    "import 'package:flutter/material.dart';\nimport '../widgets/series_detail_sheet.dart';"
                )
        
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {path}")

for f in files:
    patch_file(f)

print("Done patching.")
