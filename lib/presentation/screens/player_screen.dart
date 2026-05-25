import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../core/constants/colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/iptv_controller.dart';
import '../controllers/providers.dart';
import '../controllers/language_provider.dart';
import '../widgets/glass_container.dart';
import '../../data/models/iptv_models.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final int mediaId;
  final String mediaName;
  final String mediaType; // 'live', 'movie', 'series'
  final String? episodeExtension; // for movies / episodes (.mp4, .mkv, etc.)
  final String? streamUrlOverride;

  const PlayerScreen({
    super.key,
    required this.mediaId,
    required this.mediaName,
    required this.mediaType,
    this.episodeExtension,
    this.streamUrlOverride,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  // Media Kit Player variables
  late final Player _player;
  late final VideoController _videoController;

  // Track player states
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _showControls = true;
  bool _isLocked = false;
  
  // Custom Controls Info
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _brightness = 0.5;
  
  // Slide controls visibility
  bool _showVolumeOverlay = false;
  bool _showBrightnessOverlay = false;
  bool _showRatioOverlay = false;
  Timer? _ratioTimer;
  
  // EPG programs for Live TV
  EpgProgram? _currentEpg;
  Timer? _epgTimer;
  
  // Zapping state for Live TV
  late int _currentMediaId;
  late String _currentMediaName;
  Timer? _controlsTimer;

  // Aspect Ratios
  final List<double?> _aspectRatios = [null, 16 / 9, 4 / 3, 21 / 9, 1.0];
  int _currentRatioIdx = 0; // null = Fit/Fill by default

  @override
  void initState() {
    super.initState();
    _currentMediaId = widget.mediaId;
    _currentMediaName = widget.mediaName;

    // Force Landscape for premium full screen playback
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize Player
    _player = Player();
    _videoController = VideoController(_player);

    // Set up listeners
    _player.stream.playing.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });
    
    _player.stream.buffer.listen((buffer) {
      // Manage buffering / loading state
    });

    _player.stream.position.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _player.stream.duration.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    _player.stream.volume.listen((vol) {
      if (mounted) setState(() => _volume = vol / 100);
    });

    _startPlayback();
    _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _epgTimer?.cancel();
    _ratioTimer?.cancel();
    
    // Restore default orientation on close
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _player.dispose();
    super.dispose();
  }

  // --- Start Video Playback ---
  void _startPlayback() async {
    setState(() {
      _isLoading = true;
    });

    final creds = ref.read(authControllerProvider).credentials;
    if (creds == null) return;

    final api = ref.read(iptvApiProvider);
    final isLive = widget.mediaType == 'live';

    // Formulate play URL
    final ext = widget.episodeExtension ?? 'mp4';
    final streamUrl = widget.streamUrlOverride ?? api.buildStreamUrl(creds, widget.mediaType, _currentMediaId, ext);

    // Save to Watch History
    ref.read(iptvControllerProvider.notifier).saveToWatchHistory(
      type: widget.mediaType,
      id: _currentMediaId,
      name: _currentMediaName,
    );

    // Fetch EPG if Live TV
    if (isLive) {
      _fetchEpgData();
      _epgTimer = Timer.periodic(const Duration(minutes: 5), (_) => _fetchEpgData());
    }

    try {
      await _player.open(Media(streamUrl));
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${ref.read(languageProvider.notifier).translate('player_error')}: ${e.toString()}'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  // --- Fetch EPG ---
  Future<void> _fetchEpgData() async {
    if (widget.mediaType != 'live') return;
    final list = await ref.read(iptvControllerProvider.notifier).getShortEpg(_currentMediaId);
    if (mounted) {
      setState(() {
        _currentEpg = list.firstWhere(
          (epg) => epg.isNow,
          orElse: () => EpgProgram(
            title: ref.read(languageProvider.notifier).translate('player_no_epg'),
            start: DateTime.now(),
            end: DateTime.now().add(const Duration(hours: 1)),
          ),
        );
      });
    }
  }

  // --- Controls Timer Visibility ---
  void _startControlsTimer() {
    _controlsTimer?.cancel();
    if (_isLocked) return;
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  // --- Controls Overlay Widgets ---
  @override
  Widget build(BuildContext context) {
    ref.watch(iptvControllerProvider);
    final activeChannels = ref.read(iptvControllerProvider.notifier).getFilteredLiveChannels();

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        onVerticalDragUpdate: _isLocked ? null : (details) {
          final height = MediaQuery.of(context).size.height;
          final positionX = details.globalPosition.dx;
          final width = MediaQuery.of(context).size.width;
          final delta = details.primaryDelta! / height;

          if (positionX < width / 2) {
            // Brightness Adjustment (Left side)
            setState(() {
              _brightness = (_brightness - delta).clamp(0.0, 1.0);
              _showBrightnessOverlay = true;
              _showVolumeOverlay = false;
            });
            // Native platform brightness would be modified in a production app. 
            // We simulate with overlay brightness filter or print values here.
          } else {
            // Volume Adjustment (Right side)
            setState(() {
              final newVol = (_volume - delta).clamp(0.0, 1.0);
              _player.setVolume(newVol * 100);
              _showVolumeOverlay = true;
              _showBrightnessOverlay = false;
            });
          }
          _startControlsTimer();
        },
        onVerticalDragEnd: (_) {
          setState(() {
            _showVolumeOverlay = false;
            _showBrightnessOverlay = false;
          });
        },
        child: Stack(
          children: [
            // Video Renderer Core
            Positioned.fill(
              child: Center(
                child: _buildVideoPlayer(),
              ),
            ),

            // Soft Dimming Backdrop overlay when controls are visible
            if (_showControls && !_isLocked)
              Positioned.fill(
                child: Container(color: Colors.black45),
              ),

            // Loading Buffering Indicator
            if (_isLoading)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
                    const SizedBox(height: 12),
                    Text(ref.tr('player_loading'), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            // Aspect Ratio and Gestures Overlays
            if (_showVolumeOverlay) _buildSliderIndicator(Icons.volume_up_rounded, _volume, ref.tr('player_volume')),
            if (_showBrightnessOverlay) _buildSliderIndicator(Icons.brightness_medium_rounded, _brightness, ref.tr('player_brightness')),
            if (_showRatioOverlay) _buildRatioOverlay(),

            // Full Control UI
            if (_showControls) ...[
              _buildTopBar(),
              _buildBottomBar(activeChannels),
            ],

            // Screen Lock floating button
            if (_showControls || _isLocked)
              Positioned(
                left: 20,
                top: MediaQuery.of(context).size.height / 2 - 25,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.6),
                  radius: 22,
                  child: IconButton(
                    icon: Icon(
                      _isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                      color: _isLocked ? AppColors.secondary : Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isLocked = !_isLocked;
                        if (_isLocked) {
                          _showControls = false;
                        } else {
                          _showControls = true;
                          _startControlsTimer();
                        }
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Gestures/Level Slider indicator ---
  Widget _buildSliderIndicator(IconData icon, double value, String label) {
    return Center(
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        width: 150,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.borderDark,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_currentRatioIdx == 5) {
      // Zoom to fill (Cover)
      return Video(
        controller: _videoController,
        fit: BoxFit.cover,
      );
    } else if (_currentRatioIdx == 6) {
      // Stretch to fill (Fill)
      return Video(
        controller: _videoController,
        fit: BoxFit.fill,
      );
    } else {
      // Normal Aspect Ratio
      return AspectRatio(
        aspectRatio: _aspectRatios[_currentRatioIdx] ?? 16 / 9,
        child: Video(
          controller: _videoController,
          fit: BoxFit.contain,
        ),
      );
    }
  }

  IconData _getRatioIcon(int idx) {
    switch (idx) {
      case 0:
        return Icons.auto_awesome_rounded;
      case 1:
        return Icons.tv_rounded;
      case 2:
        return Icons.crop_5_4_rounded;
      case 3:
        return Icons.movie_filter_rounded;
      case 4:
        return Icons.crop_square_rounded;
      case 5:
        return Icons.fullscreen_rounded;
      case 6:
        return Icons.fit_screen_rounded;
      default:
        return Icons.aspect_ratio_rounded;
    }
  }

  String _getRatioLabel(int idx) {
    switch (idx) {
      case 0:
        return ref.tr('player_hud_auto');
      case 1:
        return '16:9 (${ref.tr('player_hud_widescreen')})';
      case 2:
        return '4:3 (${ref.tr('player_hud_standard')})';
      case 3:
        return '21:9 (${ref.tr('player_hud_cinematic')})';
      case 4:
        return '1:1 (${ref.tr('player_hud_square')})';
      case 5:
        return ref.tr('player_hud_fill');
      case 6:
        return ref.tr('player_hud_stretch');
      default:
        return ref.tr('player_hud_auto');
    }
  }

  Widget _buildRatioOverlay() {
    return Center(
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getRatioIcon(_currentRatioIdx), color: AppColors.primary, size: 36),
            const SizedBox(height: 12),
            Text(
              ref.tr('player_aspect_ratio'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _getRatioLabel(_currentRatioIdx),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<int> _buildPopupItem(int value, String label, bool isSelected) {
    return PopupMenuItem<int>(
      value: value,
      height: 38,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRatioIcon(value),
            color: isSelected ? AppColors.primary : Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 16),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 14,
            ),
          ],
        ],
      ),
    );
  }

  // --- Top Bar (Title & Back button) ---
  Widget _buildTopBar() {
    if (_isLocked) return const SizedBox.shrink();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentMediaName,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.mediaType == 'live' && _currentEpg != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${ref.tr('player_now')}: ${_currentEpg!.title}',
                      style: TextStyle(color: AppColors.primary.withOpacity(0.9), fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Aspect Ratio Changer
            PopupMenuButton<int>(
              icon: const Icon(Icons.aspect_ratio_rounded, color: Colors.white),
              tooltip: ref.tr('player_aspect_ratio'),
              offset: const Offset(0, 48),
              color: AppColors.surface.withOpacity(0.95),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderLight, width: 1),
              ),
              onSelected: (idx) {
                setState(() {
                  _currentRatioIdx = idx;
                  _showRatioOverlay = true;
                  _showVolumeOverlay = false;
                  _showBrightnessOverlay = false;
                });
                _ratioTimer?.cancel();
                _ratioTimer = Timer(const Duration(milliseconds: 1500), () {
                  if (mounted) {
                    setState(() {
                      _showRatioOverlay = false;
                    });
                  }
                });
                _startControlsTimer();
              },
              itemBuilder: (context) => [
                _buildPopupItem(0, ref.tr('player_hud_auto'), _currentRatioIdx == 0),
                _buildPopupItem(1, '16:9 (${ref.tr('player_hud_widescreen')})', _currentRatioIdx == 1),
                _buildPopupItem(2, '4:3 (${ref.tr('player_hud_standard')})', _currentRatioIdx == 2),
                _buildPopupItem(3, '21:9 (${ref.tr('player_hud_cinematic')})', _currentRatioIdx == 3),
                _buildPopupItem(4, '1:1 (${ref.tr('player_hud_square')})', _currentRatioIdx == 4),
                const PopupMenuDivider(height: 8),
                _buildPopupItem(5, ref.tr('player_hud_fill'), _currentRatioIdx == 5),
                _buildPopupItem(6, ref.tr('player_hud_stretch'), _currentRatioIdx == 6),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Bottom Controls & Seeker ---
  Widget _buildBottomBar(List<dynamic> activeChannels) {
    if (_isLocked) return const SizedBox.shrink();
    final isLive = widget.mediaType == 'live';

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black87],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Timeline Seeker (Only for VOD/Series)
            if (!isLive) ...[
              Row(
                children: [
                  Text(
                    _formatDuration(_position),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.borderDark,
                        thumbColor: AppColors.primary,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      ),
                      child: Slider(
                        value: _position.inMilliseconds.toDouble(),
                        max: _duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                        onChanged: (val) {
                          _player.seek(Duration(milliseconds: val.toInt()));
                          _startControlsTimer();
                        },
                      ),
                    ),
                  ),
                  Text(
                    _formatDuration(_duration),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ] else if (isLive && _currentEpg != null) ...[
              // Live TV: Show EPG Progress Bar
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(_formatTime(_currentEpg!.start), style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _currentEpg!.progress,
                          minHeight: 3,
                          backgroundColor: AppColors.borderDark,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                  ),
                  Text(_formatTime(_currentEpg!.end), style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Buttons Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Column: Quick Zap Selection Drawer (Only Live TV)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: isLive && activeChannels.isNotEmpty
                        ? ElevatedButton.icon(
                            onPressed: () {
                              _showZappingDrawer(context, activeChannels);
                              _startControlsTimer();
                            },
                            icon: const Icon(Icons.format_list_bulleted_rounded, size: 18),
                            label: Text(ref.tr('player_channel_list'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),

                // Middle Column: Play / Pause core buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                      onPressed: () {
                        final newMs = (_position.inMilliseconds - 10000).clamp(0, _duration.inMilliseconds);
                        _player.seek(Duration(milliseconds: newMs));
                        _startControlsTimer();
                      },
                    ),
                    const SizedBox(width: 16),
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      radius: 26,
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 32,
                        ),
                        onPressed: () {
                          _player.playOrPause();
                          _startControlsTimer();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
                      onPressed: () {
                        final newMs = (_position.inMilliseconds + 10000).clamp(0, _duration.inMilliseconds);
                        _player.seek(Duration(milliseconds: newMs));
                        _startControlsTimer();
                      },
                    ),
                  ],
                ),

                // Right Column: Balanced Spacer / Placeholders
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Sliding Zapping List Drawer ---
  void _showZappingDrawer(BuildContext context, List<dynamic> channels) {
    showEndDrawer(
      context: context,
      builder: (ctx) => Drawer(
        width: MediaQuery.of(context).size.width * 0.35,
        backgroundColor: AppColors.background.withOpacity(0.92),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.borderDark)),
                ),
                child: Text(
                  ref.tr('player_quick_zap'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: channels.length,
                itemBuilder: (context, idx) {
                  final ch = channels[idx];
                  final isCurrent = ch.streamId == _currentMediaId;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isCurrent ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.of(context).pop(); // Close drawer
                        setState(() {
                          _currentMediaId = ch.streamId;
                          _currentMediaName = ch.displayName;
                        });
                        _startPlayback();
                      },
                      title: Text(
                        ch.displayName,
                        style: TextStyle(
                          color: isCurrent ? AppColors.primary : Colors.white,
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      dense: true,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom function to show drawers horizontally in landscape
  void showEndDrawer({required BuildContext context, required WidgetBuilder builder}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ZapDrawer',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim1, anim2) => Align(
        alignment: Alignment.centerRight,
        child: builder(ctx),
      ),
      transitionBuilder: (ctx, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(anim1),
          child: child,
        );
      },
    );
  }

  // --- Utility formatting tools ---
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, "0")}:${time.minute.toString().padLeft(2, "0")}';
  }
}
