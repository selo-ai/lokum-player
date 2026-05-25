import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/live_tv_categorizer.dart';
import '../controllers/iptv_controller.dart';
import 'player_screen.dart';

class LiveTvDashboardScreen extends ConsumerStatefulWidget {
  const LiveTvDashboardScreen({super.key});

  @override
  ConsumerState<LiveTvDashboardScreen> createState() => _LiveTvDashboardScreenState();
}

class _LiveTvDashboardScreenState extends ConsumerState<LiveTvDashboardScreen> {
  String? _selectedMainCategory;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(iptvControllerProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.liveChannels.isEmpty) {
      return const Center(
        child: Text('Canlı TV kanalları bulunamadı.', style: TextStyle(color: Colors.white70)),
      );
    }

    // Categorize Data
    final categorizedData = LiveTvCategorizer.categorize(state.liveChannels, state.liveCategories);

    if (categorizedData.isEmpty) {
      return const Center(
        child: Text('Kategorize edilecek veri bulunamadı.', style: TextStyle(color: Colors.white70)),
      );
    }

    // Default to the first main category (TÜRKÇE if available)
    final mainCategories = categorizedData.keys.toList();
    _selectedMainCategory ??= mainCategories.first;

    // Ensure selected category is still valid
    if (!mainCategories.contains(_selectedMainCategory)) {
      _selectedMainCategory = mainCategories.first;
    }

    final activeNetworks = categorizedData[_selectedMainCategory!] ?? {};

    return Scaffold(
      backgroundColor: Colors.transparent, // Background handled by parent HomeScreen
      body: Row(
        children: [
          // Left Sidebar (Main Categories)
          Container(
            width: 120,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.1), width: 1)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: mainCategories.length,
              itemBuilder: (context, index) {
                final category = mainCategories[index];
                final isSelected = category == _selectedMainCategory;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMainCategory = category;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.success.withOpacity(0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.success.withOpacity(0.5) : Colors.transparent,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        category,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? AppColors.success : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Right Content Area (Networks and Channels)
          Expanded(
            child: activeNetworks.isEmpty
                ? const Center(child: Text('Bu bölgede kanal yok.', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 20, bottom: 100), // padding for bottom nav
                    itemCount: activeNetworks.keys.length,
                    itemBuilder: (context, index) {
                      final networkName = activeNetworks.keys.elementAt(index);
                      final channels = activeNetworks[networkName]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Network Title
                          Padding(
                            padding: const EdgeInsets.only(left: 20, bottom: 12, top: 16),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  networkName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(${channels.length})',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Horizontal Channels List
                          SizedBox(
                            height: 120, // Height for Live TV cards (wider than posters)
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              itemCount: channels.length,
                              itemBuilder: (context, chIndex) {
                                final channel = channels[chIndex];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlayerScreen(
                                          mediaId: channel.streamId,
                                          mediaName: channel.displayName,
                                          mediaType: 'live',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 160,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          // Channel Logo or Placeholder
                                          if (channel.icon != null && channel.icon!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.all(24.0),
                                              child: CachedNetworkImage(
                                                imageUrl: channel.icon!,
                                                fit: BoxFit.contain,
                                                errorWidget: (_, __, ___) => _buildFallbackLogo(channel.displayName),
                                              ),
                                            )
                                          else
                                            _buildFallbackLogo(channel.displayName),
                                            
                                          // Dark Gradient at bottom for text readability
                                          Positioned(
                                            bottom: 0, left: 0, right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Colors.black.withOpacity(0.9),
                                                    Colors.black.withOpacity(0.4),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                              child: Text(
                                                channel.displayName,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          // Quality Badge (HD, FHD, etc.)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.8),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                channel.qualityLabel,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo(String channelName) {
    String initials = "TV";
    final parts = channelName.split(' ');
    if (parts.isNotEmpty) {
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts[0].length > 1) {
        initials = parts[0].substring(0, 2).toUpperCase();
      }
    }
    
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white.withOpacity(0.2),
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
