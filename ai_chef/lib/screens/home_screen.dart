import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/models/recipe.dart';
import 'package:ai_chef/services/firebase_service.dart';
import 'package:ai_chef/services/localization_service.dart';
import 'package:ai_chef/screens/scan_screen.dart';
import 'package:ai_chef/screens/chat_screen.dart';
import 'package:ai_chef/screens/favorites_screen.dart';
import 'package:ai_chef/screens/meal_plan_screen.dart';
import 'package:ai_chef/screens/profile_screen.dart';
import 'package:ai_chef/screens/recipe_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Recipe> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final favorites = await FirebaseService.getFavoriteRecipes();
    if (mounted) setState(() => _favorites = favorites);
  }

  String _getGreeting(LocalizationService loc) {
    final hour = DateTime.now().hour;
    if (hour < 12) return loc.t('good_morning');
    if (hour < 17) return loc.t('good_afternoon');
    return loc.t('good_evening');
  }

  String _getDisplayName(User? user) {
    if (user == null) return '';
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    final email = user.email;
    if (email == null || !email.contains('@')) return '';
    return email.split('@').first;
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: true);
    final user = FirebaseAuth.instance.currentUser;
    final greeting = _getGreeting(loc);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _currentIndex == 0
          ? _buildHome(greeting, user, loc)
          : _currentIndex == 1
              ? const ScanScreen()
              : _currentIndex == 2
                  ? const ChatScreen()
                  : _currentIndex == 3
                      ? const FavoritesScreen()
                      : const ProfileScreen(),
      bottomNavigationBar: _buildBottomNav(loc),
    );
  }

  Widget _buildHome(String greeting, User? user, LocalizationService loc) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(greeting, user),
            _buildSearchBar(loc),
            _buildQuickActions(loc),
            _buildFavoritesSection(loc),
            _buildTipsSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String greeting, User? user) {
    final name = _getDisplayName(user);
    final greetingText = name.isEmpty
        ? '$greeting! 👋'
        : '$greeting, $name! 👋';
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greetingText,
            style: AppTextStyles.caption.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 4),
          Consumer<LocalizationService>(
            builder: (_, loc, __) => Text(
              loc.t('what_cook'),
              style: AppTextStyles.title.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(LocalizationService loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = 2),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).dividerColor,
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search, color: Theme.of(context).textTheme.bodyMedium?.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.t('search_placeholder'),
                  style: AppTextStyles.body.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(LocalizationService loc) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(loc.t('quick_actions'), style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  emoji: '📷',
                  title: loc.t('scan_ingredients'),
                  subtitle: loc.t('ai_recipe_magic'),
                  gradient: [AppColors.gradient1, AppColors.gradient2],
                  onTap: () => setState(() => _currentIndex = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  emoji: '💬',
                  title: loc.t('chat_chef'),
                  subtitle: loc.t('ask_anything'),
                  gradient: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                  onTap: () => setState(() => _currentIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _buildActionCard(
              emoji: '📅',
              title: loc.t('meal_planner'),
              subtitle: loc.t('seven_day'),
              gradient: [const Color(0xFF11998E), const Color(0xFF38EF7D)],
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MealPlanScreen())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 118,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(
                  (gradient.first.r * 255).round().clamp(0, 255),
                  (gradient.first.g * 255).round().clamp(0, 255),
                  (gradient.first.b * 255).round().clamp(0, 255),
                  0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesSection(LocalizationService loc) {
    if (_favorites.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('saved_recipes'), style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('🍳', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    loc.t('no_saved_yet'),
                    style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.t('search_placeholder'),
                    style: AppTextStyles.caption.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(loc.t('saved_recipes'), style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 3),
                child: Text(
                  loc.t('see_all'),
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _favorites.length,
              itemBuilder: (context, index) {
                final recipe = _favorites[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipe: recipe),
                    ),
                  ),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color.fromRGBO(255, 107, 53, 0.8),
                                AppColors.gradient2,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              '🍳',
                              style: TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '⏱ ${recipe.cookTime} min',
                                style: AppTextStyles.caption.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = [
      {
        'emoji': '🧄',
        'tip':
            'Store garlic in a cool, dark place for up to 6 months'
      },
      {
        'emoji': '🥩',
        'tip':
            'Let meat rest 5 minutes after cooking for juicier results'
      },
      {
        'emoji': '🧂',
        'tip':
            'Salt pasta water generously - it should taste like the sea'
      },
      {
        'emoji': '🔪',
        'tip': 'A sharp knife is safer than a dull one'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Chef Tips 💡', style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tips.length,
              itemBuilder: (context, index) {
                final tip = tips[index];
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tip['emoji']!,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tip['tip']!,
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(LocalizationService loc) {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': loc.t('home')},
      {
        'icon': Icons.camera_alt_outlined,
        'activeIcon': Icons.camera_alt,
        'label': loc.t('scan')
      },
      {'icon': Icons.chat_outlined, 'activeIcon': Icons.chat, 'label': loc.t('chef_ai')},
      {
        'icon': Icons.favorite_outline,
        'activeIcon': Icons.favorite,
        'label': loc.t('saved')
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': loc.t('profile')
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (index) {
              final isActive = _currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Color.fromRGBO(255, 107, 53, 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive
                              ? items[index]['activeIcon'] as IconData
                              : items[index]['icon'] as IconData,
                          color: isActive
                              ? AppColors.primary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            items[index]['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              color: isActive
                                  ? AppColors.primary
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
