import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../controllers/auth_controller.dart';
import '../controllers/language_provider.dart';
import '../controllers/providers.dart';
import '../widgets/glass_container.dart';
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
