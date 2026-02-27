import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/services/firebase_service.dart';
import 'package:ai_chef/services/localization_service.dart';
import 'package:ai_chef/screens/onboarding_screen.dart';
import 'package:ai_chef/screens/appearance_screen.dart';

const _avatarEmojiKey = 'user_avatar_emoji';

const _avatarEmojis = [
  '👨‍🍳', '👩‍🍳', '🧑‍🍳', '👨‍🍳🏆', '🍳👨‍🍳', '👨‍🍳⭐', '🥇👨‍🍳', '👨‍🍳🔥',
  '😋', '🤤', '😍', '🥳', '😎', '🤩', '🥰', '😄',
  '🍕', '🍜', '🍣', '🌮', '🥘', '🍱', '🥗', '🍝',
  '⭐', '🔥', '💪', '🏆', '💎', '🚀', '✨', '🎯',
  '🌟', '🎪', '🍀', '👑', '🎨', '🦁',
];

const _languages = [
  {'code': 'en', 'name': 'English', 'flag': '🇺🇸', 'native': 'English'},
  {'code': 'ru', 'name': 'Russian', 'flag': '🇷🇺', 'native': 'Русский'},
  {'code': 'uz', 'name': 'Uzbek', 'flag': '🇺🇿', 'native': "O'zbek"},
  {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸', 'native': 'Español'},
  {'code': 'fr', 'name': 'French', 'flag': '🇫🇷', 'native': 'Français'},
  {'code': 'de', 'name': 'German', 'flag': '🇩🇪', 'native': 'Deutsch'},
  {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹', 'native': 'Italiano'},
  {'code': 'pt', 'name': 'Portuguese', 'flag': '🇧🇷', 'native': 'Português'},
  {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦', 'native': 'العربية'},
  {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳', 'native': '中文'},
  {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵', 'native': '日本語'},
  {'code': 'ko', 'name': 'Korean', 'flag': '🇰🇷', 'native': '한국어'},
  {'code': 'tr', 'name': 'Turkish', 'flag': '🇹🇷', 'native': 'Türkçe'},
  {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳', 'native': 'हिंदी'},
  {'code': 'id', 'name': 'Indonesian', 'flag': '🇮🇩', 'native': 'Bahasa'},
  {'code': 'nl', 'name': 'Dutch', 'flag': '🇳🇱', 'native': 'Nederlands'},
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? get user => FirebaseAuth.instance.currentUser;
  int _recipesCount = 0;
  int _favoritesCount = 0;
  String _avatarEmoji = '👨‍🍳';

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _avatarEmoji = prefs.getString(_avatarEmojiKey) ?? '👨‍🍳';
    });
  }

  Future<void> _loadStats() async {
    final favorites = await FirebaseService.getFavoriteRecipes();
    final all = await FirebaseService.getAllRecipes();
    if (mounted) {
      setState(() {
        _favoritesCount = favorites.length;
        _recipesCount = all.length;
      });
    }
  }

  Future<void> _signOut() async {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${loc.t('logout')}?'),
        content: Text(loc.t('log_out_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(context);
              await FirebaseService.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_seen', false);
              if (!navigator.mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                (_) => false,
              );
            },
            child: Text(
              loc.t('logout'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final sheetHeight = MediaQuery.of(context).size.height * 0.55;
    final gridHeight = (sheetHeight - 100).clamp(200.0, 400.0);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: sheetHeight,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(loc.t('choose_avatar'), style: AppTextStyles.subtitle),
            const SizedBox(height: 16),
            SizedBox(
              height: gridHeight,
              child: GridView.builder(
                shrinkWrap: false,
                physics: const ClampingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: _avatarEmojis.length,
                itemBuilder: (context, index) {
                  final emoji = _avatarEmojis[index];
                  return GestureDetector(
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString(_avatarEmojiKey, emoji);
                      if (mounted) setState(() => _avatarEmoji = emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Text(emoji, style: const TextStyle(fontSize: 28)),
                      ),
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

  void _showEditNameDialog() {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    final nameController = TextEditingController(
      text: user?.displayName ?? _getDisplayName() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.t('edit_name')),
        content: SingleChildScrollView(
          child: TextField(
            controller: nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: loc.t('your_name'),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) => _saveName(value, context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => _saveName(nameController.text.trim(), context),
            child: Text(loc.t('save')),
          ),
        ],
      ),
    );
  }

  Future<void> _saveName(String newName, BuildContext dialogContext) async {
    if (newName.isEmpty || user == null) return;
    try {
      await user!.updateDisplayName(newName);
      if (mounted) setState(() {});
      if (dialogContext.mounted) Navigator.pop(dialogContext);
      if (mounted) {
        final loc = Provider.of<LocalizationService>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.t('name_updated')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String? _getDisplayName() {
    if (user == null) return null;
    if (user!.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user!.displayName!.trim();
    }
    final email = user!.email;
    if (email == null || !email.contains('@')) return null;
    return email.split('@').first;
  }

  void _showLanguagePicker() {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('${loc.t('language')} 🌍', style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final code = lang['code'] as String;
                    final name = lang['name'] as String;
                    final flag = lang['flag'] as String;
                    final native = lang['native'] as String;
                    final isSelected = loc.lang == code;
                    return ListTile(
                      leading: Text(flag, style: const TextStyle(fontSize: 24)),
                      title: Text('$native ($name)', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.primary, size: 28)
                          : null,
                      onTap: () async {
                        await loc.setLanguage(code);
                        if (context.mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String> _selectedLanguage(LocalizationService loc) {
    return _languages.firstWhere(
      (l) => l['code'] == loc.lang,
      orElse: () => _languages.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: true);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(loc),
            _buildLanguageCard(loc),
            _buildStylePreferences(loc),
            _buildSettings(loc),
            _buildLogout(loc),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final displayName = _getDisplayName() ?? 'Chef';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B35),
            Color(0xFFFF8C42),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            children: [
              GestureDetector(
                onTap: _showEmojiPicker,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _avatarEmoji,
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 16, color: Color(0xFFFF6B35)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showEditNameDialog,
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                FirebaseAuth.instance.currentUser?.email ?? 'user@email.com',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats(LocalizationService loc) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('🍳', '$_recipesCount', loc.t('recipes_scanned'))),
          _buildDivider(),
          Expanded(child: _buildStatItem('❤️', '$_favoritesCount', loc.t('saved_recipes'))),
          _buildDivider(),
          Expanded(child: _buildStatItem('📅', '7', loc.t('day_streak'))),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: double.infinity,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildLanguageCard(LocalizationService loc) {
    final lang = _selectedLanguage(loc);
    final flag = lang['flag'] ?? '🇺🇸';
    final name = lang['name'] ?? 'English';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${loc.t('language')} 🌍', style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showLanguagePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyles.body.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylePreferences(LocalizationService loc) {
    final preferenceKeys = [
      'quick_meals',
      'healthy',
      'budget_friendly',
      'italian',
      'asian',
      'vegetarian',
    ];
    final preferences = preferenceKeys.map((k) => loc.t(k)).toList();

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.t('food_prefs'), style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: preferences
                .map((pref) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).chipTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Text(
                        pref,
                        style: (Theme.of(context).chipTheme.labelStyle ?? TextStyle(fontSize: 13)).copyWith(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(LocalizationService loc) {
    final settings = [
      {'icon': Icons.palette_outlined, 'key': 'appearance', 'subkey': ''},
      {'icon': Icons.notifications_outlined, 'key': 'notifications', 'subkey': 'Daily cooking reminders'},
      {'icon': Icons.restaurant_menu_outlined, 'key': 'dietary', 'subkey': 'Set your preferences'},
      {'icon': Icons.share_outlined, 'key': 'share', 'subkey': 'Tell your friends'},
      {'icon': Icons.star_outline, 'key': 'rate', 'subkey': 'Support us with a review'},
      {'icon': Icons.privacy_tip_outlined, 'key': 'privacy', 'subkey': ''},
      {'icon': Icons.description_outlined, 'key': 'terms', 'subkey': ''},
    ];

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).dividerColor,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: settings.asMap().entries.map((entry) {
          final index = entry.key;
          final setting = entry.value;
          final isLast = index == settings.length - 1;
          final title = loc.t(setting['key'] as String);
          final sub = setting['subkey'] as String;
          final isAppearance = setting['key'] == 'appearance';
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 107, 53, 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    setting['icon'] as IconData,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: sub.isNotEmpty
                    ? Text(
                        sub,
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      )
                    : null,
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
                onTap: () {
                  if (isAppearance) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AppearanceScreen()),
                    );
                  }
                },
              ),
              if (!isLast) Divider(height: 1, indent: 70, color: Theme.of(context).dividerColor),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogout(LocalizationService loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: Text(
          loc.t('logout'),
          style: const TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(color: AppColors.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
