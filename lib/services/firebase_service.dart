import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ai_chef/models/recipe.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Auth
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<void> signUp(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Recipes
  static Future<void> saveRecipe(Recipe recipe) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('recipes')
        .doc(recipe.id)
        .set(recipe.toJson());
  }

  static Future<List<Recipe>> getFavoriteRecipes() async {
    try {
      final user = currentUser;
      if (user == null) return [];
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('recipes')
          .where('isFavorite', isEqualTo: true)
          .get();
      return snapshot.docs.map((doc) => Recipe.fromJson(doc.data())).toList();
    } catch (e) {
      print('getFavoriteRecipes error: $e');
      return [];
    }
  }

  static Future<List<Recipe>> getAllRecipes() async {
    try {
      final user = currentUser;
      if (user == null) return [];
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('recipes')
          .get();
      return snapshot.docs.map((doc) => Recipe.fromJson(doc.data())).toList();
    } catch (e) {
      print('getAllRecipes error: $e');
      return [];
    }
  }

  static Future<void> toggleFavorite(String recipeId, bool isFavorite) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('recipes')
        .doc(recipeId)
        .update({'isFavorite': isFavorite});
  }

  static Future<void> deleteRecipe(String recipeId) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('recipes')
        .doc(recipeId)
        .delete();
  }

  // Shopping list
  static Future<void> saveShoppingList(
    Map<String, List<String>> items,
    Map<String, bool> checked,
  ) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    final checkedSerialized = checked.map((k, v) => MapEntry(k, v));
    await _db
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .doc('current')
        .set({
      'items': items,
      'checked': checkedSerialized,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, dynamic>> getShoppingList() async {
    final userId = currentUser?.uid;
    if (userId == null) return {};

    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .doc('current')
        .get();

    if (!doc.exists) return {};
    return doc.data() ?? {};
  }

  // Meal plan
  static Future<void> saveMealPlan(Map<String, List<Recipe>> mealPlan) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    final data = mealPlan.map(
        (day, recipes) => MapEntry(day, recipes.map((r) => r.toJson()).toList()));

    await _db
        .collection('users')
        .doc(userId)
        .collection('meal_plans')
        .doc('current')
        .set({
      'plan': data,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<Map<String, List<Recipe>>> getMealPlan() async {
    final userId = currentUser?.uid;
    if (userId == null) return {};

    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('meal_plans')
        .doc('current')
        .get();

    if (!doc.exists) return {};
    final planData = doc.data()?['plan'];
    if (planData == null || planData is! Map) return {};

    final plan = planData as Map<String, dynamic>;
    final result = <String, List<Recipe>>{};
    for (final entry in plan.entries) {
      final list = entry.value;
      if (list is! List) continue;
      result[entry.key] = list
          .map((r) => Recipe.fromJson(
              r is Map<String, dynamic> ? r : Map<String, dynamic>.from(r as Map)))
          .toList();
    }
    return result;
  }

  // User profile
  static Future<void> saveUserProfile(Map<String, dynamic> data) async {
    final userId = currentUser?.uid;
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>> getUserProfile() async {
    final userId = currentUser?.uid;
    if (userId == null) return {};

    final doc = await _db.collection('users').doc(userId).get();
    return doc.data() ?? {};
  }
}
