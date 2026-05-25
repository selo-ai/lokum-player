import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/language_provider.dart';
import '../controllers/providers.dart';
import '../widgets/glass_container.dart';
import '../controllers/iptv_controller.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _getLanguageName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.tr:
        return 'Türkçe 🇹🇷';
      case AppLanguage.en:
        return 'English 🇺🇸';
      case AppLanguage.de:
        return 'Deutsch 🇩🇪';
      case AppLanguage.es:
        return 'Español 🇪🇸';
      case AppLanguage.pt:
        return 'Português 🇵🇹';
      case AppLanguage.zh:
        return '中文 🇨🇳';
    }
  }

  void _showLanguageSelectorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          ref.watch(languageProvider).name == 'tr' ? 'Uygulama Dili' : 'App Language',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((lang) {
            final isSelected = ref.read(languageProvider) == lang;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                _getLanguageName(lang),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage(lang);
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showRecentCountSelectorDialog(BuildContext context) {
    final counts = [10, 20, 30];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          ref.watch(languageProvider).name == 'tr' ? 'Son Eklenenler Limiti' : 'Recently Added Limit',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: counts.map((count) {
            final isSelected = ref.read(recentCountProvider) == count;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              title: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                ref.read(recentCountProvider.notifier).setCount(count);
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            val,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showServiceInfoModal(BuildContext context) {
    final authState = ref.read(authControllerProvider);
    final creds = authState.credentials;
    if (creds == null) return;
    
    final state = ref.read(iptvControllerProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<Map<String, dynamic>?>(
              future: ref.read(iptvApiProvider).getAccountInfo(creds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }

                final data = snapshot.data;
                final userInfo = data?['user_info'] as Map<String, dynamic>?;
                final serverInfo = data?['server_info'] as Map<String, dynamic>?;

                // Format expiration date cleanly
                String expDateText = 'Bilinmiyor';
                if (userInfo != null) {
                  final expRaw = userInfo['exp_date'];
                  if (expRaw == null || expRaw == '0' || expRaw.toString() == 'null' || expRaw.toString().isEmpty) {
                    expDateText = ref.tr('info_unlimited');
                  } else {
                    final seconds = int.tryParse(expRaw.toString());
                    if (seconds != null) {
                      final dt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
                      expDateText = '${dt.day}.${dt.month}.${dt.year}';
                    }
                  }
                }

                final activeCons = userInfo?['active_cons']?.toString() ?? '0';
                final maxConnections = userInfo?['max_connections']?.toString() ?? '1';
                final unknownText = ref.tr('info_unknown');

                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.dns_rounded, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            ref.tr('info_title'),
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.borderDark, height: 32),

                      Text(
                        ref.tr('info_sub_details'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(ref.tr('info_status'), ref.tr('dashboard_active')),
                            const SizedBox(height: 12),
                            _buildInfoRow(ref.tr('info_exp_date'), expDateText),
                            const SizedBox(height: 12),
                            _buildInfoRow(ref.tr('info_active_connections'), '$activeCons / $maxConnections'),
                            if (userInfo?['is_trial']?.toString() == '1') ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(ref.tr('info_account_type'), ref.tr('info_trial')),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        ref.tr('info_server_details'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(ref.tr('info_server_url'), serverInfo?['url'] ?? creds.serverUrl),
                            const SizedBox(height: 12),
                            _buildInfoRow(ref.tr('info_timezone'), serverInfo?['timezone'] ?? unknownText),
                            const SizedBox(height: 12),
                            _buildInfoRow(ref.tr('info_server_time'), serverInfo?['time_now'] ?? unknownText),
                            if (userInfo?['allowed_outputs'] is List) ...[
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                ref.tr('info_allowed_formats'),
                                (userInfo!['allowed_outputs'] as List).join(', ').toUpperCase(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        ref.tr('info_content_stats'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(ref.tr('info_live_channels'), state.liveChannels.length.toString()),
                            const SizedBox(height: 12),
                            _buildInfoRow(ref.tr('info_movies'), state.movies.length.toString()),
                            const SizedBox(height: 12),
                            _buildInfoRow(ref.tr('info_series'), state.series.length.toString()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final serverUrl = authState.credentials?.serverUrl ?? '-';
    final username = authState.credentials?.username ?? '-';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          ref.tr('settings_title'),
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Card
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_circle_outlined, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            ref.tr('settings_account_info'),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.borderDark, height: 24),
                      _buildInfoRow(ref.tr('settings_server'), serverUrl),
                      const SizedBox(height: 12),
                      _buildInfoRow(ref.tr('settings_username'), username),
                      const Divider(color: AppColors.borderDark, height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _showServiceInfoModal(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                ref.tr('info_title'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Language Setting Card
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.language_rounded, color: AppColors.primary, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            ref.tr('settings_language'),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.borderDark, height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          ref.watch(languageProvider).name == 'tr' ? 'Dil Seçimi' : 'Select Language',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          _getLanguageName(ref.watch(languageProvider)),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 28),
                        onTap: () => _showLanguageSelectorDialog(context),
                      ),
                      const Divider(color: AppColors.borderDark, height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primary,
                        title: Text(
                          ref.watch(languageProvider).name == 'tr' ? 'EPG (TV Rehberi) Desteği' : 'EPG (TV Guide) Support',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          ref.watch(languageProvider).name == 'tr' ? 'Canlı kanallar için yayın akışı bilgisini getir' : 'Fetch program guide for live channels',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        value: ref.watch(epgEnabledProvider),
                        onChanged: (val) {
                          ref.read(epgEnabledProvider.notifier).setEnabled(val);
                        },
                      ),
                      const Divider(color: AppColors.borderDark, height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          ref.watch(languageProvider).name == 'tr' ? 'Son Eklenenler Limiti' : 'Recently Added Limit',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${ref.watch(recentCountProvider)}',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 28),
                        onTap: () => _showRecentCountSelectorDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Logout Button
                ElevatedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.background,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: Text(
                          ref.tr('settings_logout_confirm_title'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          ref.tr('settings_logout_confirm_msg'),
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: Text(ref.tr('settings_cancel')),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: Text(
                              ref.tr('settings_logout_action'),
                              style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error.withOpacity(0.12),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded),
                      const SizedBox(width: 10),
                      Text(ref.tr('settings_logout'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
