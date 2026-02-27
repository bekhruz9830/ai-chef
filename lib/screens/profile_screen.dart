import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/services/firebase_service.dart';
import 'package:ai_chef/screens/onboarding_screen.dart';

const _avatarEmojiKey = 'user_avatar_emoji';
const _appLanguageKey = 'app_language';

const _avatarEmojis = [
  '👨‍🍳', '👩‍🍳', '🧑‍🍳', '😎', '🤩', '🥳', '😋', '🤤', '🍽️', '⭐',
  '🔥', '💪', '🌟', '🎯', '🏆', '💎', '🚀', '✨', '🎪', '🍀',
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
  String _selectedLanguageCode = 'en';

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
      _selectedLanguageCode = prefs.getString(_appLanguageKey) ?? 'en';
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text(
              'Log out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Choose avatar', style: AppTextStyles.subtitle),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
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
                      color: AppColors.surface,
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog() {
    final nameController = TextEditingController(
      text: user?.displayName ?? _getDisplayName() ?? '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit name'),
        content: SingleChildScrollView(
          child: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Your name',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => _saveName(value, context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _saveName(nameController.text.trim(), context),
            child: const Text('Save'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Name updated'),
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
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Language 🌍', style: AppTextStyles.subtitle),
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
                    final isSelected = _selectedLanguageCode == code;
                    return ListTile(
                      leading: Text(flag, style: const TextStyle(fontSize: 24)),
                      title: Text('$native ($name)'),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.primary, size: 28)
                          : null,
                      onTap: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(_appLanguageKey, code);
                        if (mounted) setState(() => _selectedLanguageCode = code);
                        Navigator.pop(context);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Language changed to $name! Restart may be needed.',
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
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

  Map<String, String> get _selectedLanguage {
    return _languages.firstWhere(
      (l) => l['code'] == _selectedLanguageCode,
      orElse: () => _languages.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(),
            _buildLanguageCard(),
            _buildStylePreferences(),
            _buildSettings(),
            _buildLogout(),
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
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _showEmojiPicker,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
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
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showEditNameDialog,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('✏️', style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildStatItem('🍳', '$_recipesCount', 'Recipes scanned')),
          _buildDivider(),
          Expanded(child: _buildStatItem('❤️', '$_favoritesCount', 'Saved recipes')),
          _buildDivider(),
          Expanded(child: _buildStatItem('📅', '7', 'Day streak')),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 50,
      width: 1,
      color: AppColors.border,
    );
  }

  Widget _buildLanguageCard() {
    final lang = _selectedLanguage;
    final flag = lang['flag'] ?? '🇺🇸';
    final name = lang['name'] ?? 'English';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Language 🌍', style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showLanguagePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(flag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text(
                    name,
                    style: AppTextStyles.body,
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylePreferences() {
    final preferences = [
      'Quick meals',
      'Healthy',
      'Budget-friendly',
      'Italian',
      'Asian',
      'Vegetarian',
    ];

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Food Preferences', style: AppTextStyles.subtitle),
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
                        color: Color.fromRGBO(255, 107, 53, 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        pref,
                        style: const TextStyle(
                          color: AppColors.primary,
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

  Widget _buildSettings() {
    final settings = [
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifications',
        'subtitle': 'Daily cooking reminders'
      },
      {
        'icon': Icons.restaurant_menu_outlined,
        'title': 'Dietary restrictions',
        'subtitle': 'Set your preferences'
      },
      {
        'icon': Icons.share_outlined,
        'title': 'Share AI Chef',
        'subtitle': 'Tell your friends'
      },
      {
        'icon': Icons.star_outline,
        'title': 'Rate the app',
        'subtitle': 'Support us with a review'
      },
      {'icon': Icons.privacy_tip_outlined, 'title': 'Privacy Policy', 'subtitle': ''},
      {'icon': Icons.description_outlined, 'title': 'Terms of Service', 'subtitle': ''},
    ];

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: settings.asMap().entries.map((entry) {
          final index = entry.key;
          final setting = entry.value;
          final isLast = index == settings.length - 1;
          return Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(255, 107, 53, 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    setting['icon'] as IconData,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  setting['title'] as String,
                  style: AppTextStyles.body,
                ),
                subtitle: (setting['subtitle'] as String).isNotEmpty
                    ? Text(
                        setting['subtitle'] as String,
                        style: AppTextStyles.caption,
                      )
                    : null,
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textLight,
                ),
                onTap: () {},
              ),
              if (!isLast) const Divider(height: 1, indent: 70),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text(
          'Log out',
          style: TextStyle(color: AppColors.error),
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
