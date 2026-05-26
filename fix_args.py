import os
import re

SCREENS_DIR = 'lib/presentation/screens'
screens = [
    'action_room_screen.dart', 'documentary_room_screen.dart', 'horror_room_screen.dart',
    'kids_club_screen.dart', 'laughing_gas_screen.dart', 'nostalgia_room_screen.dart',
    'scifi_room_screen.dart', 'sports_dashboard_screen.dart'
]

def clean_refs(match):
    refs_str = match.group(1)
    # Find the first ref.tr('...')
    first_ref = re.search(r"ref\.tr\('[^']+'\)", refs_str).group(0)
    args = match.group(2)
    return first_ref, args

for screen in screens:
    path = os.path.join(SCREENS_DIR, screen)
    if not os.path.exists(path): continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    def replacer_live(m):
        first_ref, args = clean_refs(m)
        return f"_buildLiveChannelsRow({first_ref}, {args}, context, ref)"
        
    def replacer_movie(m):
        first_ref, args = clean_refs(m)
        return f"_buildMatchedMovieRow({first_ref}, {args}, context, ref, {m.group(3)})"
        
    def replacer_series(m):
        first_ref, args = clean_refs(m)
        return f"_buildMatchedSeriesRow({first_ref}, {args}, context, ref, {m.group(3)})"

    content = re.sub(r'_buildLiveChannelsRow\((ref\.tr\(\'[^\']+\'\)(?:,\s*ref\.tr\(\'[^\']+\'\))*),\s*(.*?),\s*context,\s*ref\)', replacer_live, content)
    content = re.sub(r'_buildMatchedMovieRow\((ref\.tr\(\'[^\']+\'\)(?:,\s*ref\.tr\(\'[^\']+\'\))*),\s*(.*?),\s*context,\s*ref,\s*(.*?)\)', replacer_movie, content)
    content = re.sub(r'_buildMatchedSeriesRow\((ref\.tr\(\'[^\']+\'\)(?:,\s*ref\.tr\(\'[^\']+\'\))*),\s*(.*?),\s*context,\s*ref,\s*(.*?)\)', replacer_series, content)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

print("Fix applied")
