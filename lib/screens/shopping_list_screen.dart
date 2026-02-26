import 'package:flutter/material.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/services/firebase_service.dart';
import 'package:ai_chef/services/gemini_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _gemini = GeminiService();
  Map<String, List<String>> _items = {};
  Map<String, bool> _checked = {};
  bool _loading = false;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() => _loading = true);
    final data = await FirebaseService.getShoppingList();
    if (mounted && data.isNotEmpty) {
      setState(() {
        final rawItems = data['items'];
        if (rawItems is Map) {
          _items = Map<String, List<String>>.from(
            rawItems.map((k, v) =>
                MapEntry(k.toString(), List<String>.from((v as List).map((e) => e.toString())))),
          );
        }
        final rawChecked = data['checked'];
        if (rawChecked is Map) {
          _checked = Map<String, bool>.from(
            rawChecked.map((k, v) => MapEntry(k.toString(), v == true)),
          );
        }
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _generateFromFavorites() async {
    setState(() => _generating = true);
    try {
      final recipes = await FirebaseService.getFavoriteRecipes();
      if (recipes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Save some recipes first!'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }
      final list = await _gemini.generateShoppingList(recipes);
      setState(() {
        _items = list;
        _checked = {};
      });
      await FirebaseService.saveShoppingList(_items, _checked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _toggleItem(String key) {
    setState(() => _checked[key] = !(_checked[key] ?? false));
    FirebaseService.saveShoppingList(_items, _checked);
  }

  void _clearChecked() {
    setState(() {
      final checkedKeys =
          _checked.entries.where((e) => e.value).map((e) => e.key).toList();
      for (final key in checkedKeys) {
        final parts = key.split('::');
        if (parts.length == 2) {
          _items[parts[0]]?.remove(parts[1]);
          if (_items[parts[0]]?.isEmpty ?? false) {
            _items.remove(parts[0]);
          }
        }
        _checked.remove(key);
      }
    });
    FirebaseService.saveShoppingList(_items, _checked);
  }

  int get _checkedCount => _checked.values.where((v) => v).length;
  int get _totalCount =>
      _items.values.fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (_checkedCount > 0)
            TextButton.icon(
              onPressed: _clearChecked,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text('Clear $_checkedCount'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _items.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Column(
        children: [
          if (_totalCount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_checkedCount / $_totalCount items',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${((_checkedCount / _totalCount) * 100).round()}%',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _totalCount > 0 ? _checkedCount / _totalCount : 0,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: _generating ? null : _generateFromFavorites,
            icon: _generating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              _generating ? 'Generating...' : 'Generate from saved recipes',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛍', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text('No items yet', style: AppTextStyles.title),
          const SizedBox(height: 8),
          Text(
            'Save recipes and generate\nyour shopping list automatically',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final categoryEmojis = {
      'Produce': '🥬',
      'Meat & Seafood': '🥩',
      'Dairy': '🧀',
      'Pantry': '🫙',
      'Spices': '🧂',
      'Frozen': '🧊',
      'Bakery': '🍞',
      'Beverages': '🥤',
    };

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _items.keys.length,
      itemBuilder: (context, index) {
        final category = _items.keys.elementAt(index);
        final items = _items[category] ?? [];
        final emoji = categoryEmojis[category] ?? '🛒';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(category, style: AppTextStyles.subtitle),
                    const Spacer(),
                    Text(
                      '${items.length} items',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ...items.map((item) {
                final key = '$category::$item';
                final isChecked = _checked[key] ?? false;
                return ListTile(
                  leading: GestureDetector(
                    onTap: () => _toggleItem(key),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isChecked ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: isChecked
                              ? AppColors.primary
                              : AppColors.border,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isChecked
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  title: Text(
                    item,
                    style: AppTextStyles.body.copyWith(
                      decoration: isChecked
                          ? TextDecoration.lineThrough
                          : null,
                      color: isChecked
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () => _toggleItem(key),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
