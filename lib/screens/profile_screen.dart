import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/theme.dart';
import '../services/firebase_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  int _recipesCount = 0;
  int _favoritesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final favorites = await FirebaseService.getFavoriteRecipes();
    final all = await FirebaseService.getAllRecipes();
    if (mounted) setState(() {
      _favoritesCount = favorites.length;
      _recipesCount = all.length;
    });
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
              await FirebaseService.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradient1, AppColors.gradient2],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Center(
              child: Text('👨‍🍳', style: TextStyle(fontSize: 44)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.displayName ?? 'Chef',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
          _buildStatItem('🍳', '$_recipesCount', 'Recipes'),
          _buildDivider(),
          _buildStatItem('❤️', '$_favoritesCount', 'Saved'),
          _buildDivider(),
          _buildStatItem('📅', '7', 'Day streak'),
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
        Text(label, style: AppTextStyles.caption),
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

  Widget _buildStylePreferences() {
    final preferences = [
      'Quick meals', 'Healthy', 'Budget-friendly',
      'Italian', 'Asian', 'Vegetarian',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
            children: preferences.map((pref) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pref,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    final settings = [
      {'icon': Icons.notifications_outlined, 'title': 'Notifications', 'subtitle': 'Daily cooking reminders'},
      {'icon': Icons.restaurant_menu_outlined, 'title': 'Dietary restrictions', 'subtitle': 'Set your preferences'},
      {'icon': Icons.share_outlined, 'title': 'Share AI Chef', 'subtitle': 'Tell your friends'},
      {'icon': Icons.star_outline, 'title': 'Rate the app', 'subtitle': 'Support us with a review'},
      {'icon': Icons.privacy_tip_outlined, 'title': 'Privacy Policy', 'subtitle': ''},
      {'icon': Icons.description_outlined, 'title': 'Terms of Service', 'subtitle': ''},
    ];

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                    color: AppColors.primary.withOpacity(0.1),
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
              if (!isLast)
                const Divider(height: 1, indent: 70),
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