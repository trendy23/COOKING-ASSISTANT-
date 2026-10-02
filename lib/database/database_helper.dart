import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static const int maxDailyRecipes = 7;
  static Future<Database>? _databaseFuture;

  static Future<Database> initDatabase() async {
    return _databaseFuture ??= openDatabase(
      join(await getDatabasesPath(), 'cooking_assistant.db'),
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await createSchema(db);
        await _seedContent(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await createSchema(db);
        await _seedContent(db);
      },
    );
  }

  static Future<void> createSchema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        tier TEXT NOT NULL DEFAULT 'FREEMIUM'
          CHECK (tier IN ('FREEMIUM', 'PREMIUM'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Recipe (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        dietaryTags TEXT NOT NULL DEFAULT '',
        cultureTag TEXT NOT NULL DEFAULT 'International',
        prepTimeMinutes INTEGER,
        energyLevel TEXT NOT NULL DEFAULT 'medium',
        isStarterRecipe INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Step (
        id TEXT PRIMARY KEY,
        stepOrder INTEGER NOT NULL,
        instructionText TEXT NOT NULL,
        imageUrl TEXT NOT NULL DEFAULT '',
        recipe_id TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES Recipe(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Ingredient (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Recipe_Ingredient (
        recipe_id TEXT NOT NULL,
        ingredient_id TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES Recipe(id) ON DELETE CASCADE,
        FOREIGN KEY (ingredient_id) REFERENCES Ingredient(id),
        PRIMARY KEY (recipe_id, ingredient_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Profile_Recipe (
        profile_id TEXT NOT NULL,
        recipe_id TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES Profile(id),
        FOREIGN KEY (recipe_id) REFERENCES Recipe(id),
        PRIMARY KEY (profile_id, recipe_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Daily_Usage (
        profile_id TEXT NOT NULL,
        usage_date TEXT NOT NULL,
        recipe_id TEXT NOT NULL,
        FOREIGN KEY (profile_id) REFERENCES Profile(id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES Recipe(id) ON DELETE CASCADE,
        PRIMARY KEY (profile_id, usage_date, recipe_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS Redeem_Code (
        code TEXT PRIMARY KEY COLLATE NOCASE,
        is_used INTEGER NOT NULL DEFAULT 0,
        used_by TEXT,
        FOREIGN KEY (used_by) REFERENCES Profile(id)
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_daily_usage_profile_date '
      'ON Daily_Usage(profile_id, usage_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_recipe_step_order '
      'ON Step(recipe_id, stepOrder)',
    );
  }

  static Future<void> _seedContent(Database db) async {
    for (final code in const [
      'COOK-PREMIUM-001',
      'COOK-PREMIUM-002',
      'COOK-PREMIUM-003',
    ]) {
      await db.insert('Redeem_Code', {
        'code': code,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    final recipes = <_RecipeSeed>[
      _RecipeSeed(
        '1',
        'Jollof Rice',
        'Cameroonian',
        45,
        false,
        'vegetarian,gluten_free,dairy_free',
        'Blend tomato, red bell pepper, onion and scotch bonnet. Fry the blend in oil with garlic and ginger. Add rice, stock and bouillon, cook until rice is soft and has absorbed the sauce.',
        [
          'Rice',
          'Tomato',
          'Red bell pepper',
          'Onion',
          'Garlic',
          'Ginger',
          'Scotch bonnet pepper',
          'Vegetable oil',
          'Maggi/bouillon cube',
        ],
      ),
      _RecipeSeed(
        '2',
        'Fried Ripe Plantain',
        'Cameroonian',
        15,
        true,
        'vegan,vegetarian,gluten_free,dairy_free,nut_free',
        'Slice ripe plantain diagonally. Fry in hot oil until golden on both sides. Drain and season lightly with salt.',
        ['Plantain', 'Vegetable oil', 'Salt'],
      ),
      _RecipeSeed(
        '3',
        'Ndole (Bitter Leaf and Peanut Stew)',
        'Cameroonian',
        75,
        false,
        'gluten_free,dairy_free,no_pork',
        'Wash and boil the bitter leaf several times to remove bitterness. Blend groundnuts with onion, garlic and ginger into a paste. Boil the beef until tender. Combine with the groundnut paste, crayfish, palm oil and bitter leaf. Simmer until thickened.',
        [
          'Bitter leaf',
          'Groundnuts (peanuts)',
          'Ground crayfish',
          'Beef',
          'Onion',
          'Garlic',
          'Ginger',
          'Red palm oil',
          'Scotch bonnet pepper',
          'Maggi/bouillon cube',
          'Salt',
        ],
      ),
      _RecipeSeed(
        '4',
        'Nigerian Jollof Spaghetti',
        'Nigerian',
        35,
        false,
        'vegetarian,dairy_free',
        'Fry blended pepper mix. Add spaghetti and stock. Simmer until spaghetti absorbs the sauce.',
        [
          'Spaghetti',
          'Tomato',
          'Onion',
          'Scotch bonnet pepper',
          'Maggi/bouillon cube',
        ],
      ),
      _RecipeSeed(
        '5',
        'Egg Sauce',
        'Nigerian',
        15,
        true,
        'vegetarian,gluten_free,dairy_free',
        'Fry onion, tomato and pepper. Crack eggs directly into the pan and scramble together. Season to taste.',
        ['Egg', 'Tomato', 'Onion', 'Vegetable oil', 'Maggi/bouillon cube'],
      ),
      _RecipeSeed(
        '6',
        'Fried Rice (West African style)',
        'Nigerian',
        40,
        false,
        'vegetarian,gluten_free,dairy_free',
        'Par-cook rice. Saute chopped vegetables in oil. Mix in the rice, soy sauce and seasoning.',
        ['Rice', 'Carrot', 'Cabbage', 'Soy sauce', 'Vegetable oil'],
      ),
      _RecipeSeed(
        '7',
        'Spaghetti Aglio e Olio',
        'Italian',
        20,
        false,
        'vegan,vegetarian,dairy_free',
        'Cook spaghetti. Gently fry garlic in olive oil until golden. Toss the spaghetti in the oil and finish with black pepper.',
        ['Spaghetti', 'Garlic', 'Olive oil', 'Black pepper'],
      ),
      _RecipeSeed(
        '8',
        'Simple Tomato Pasta',
        'Italian',
        25,
        false,
        'vegetarian',
        'Cook pasta. Saute garlic and onion. Add tomato and simmer into a sauce. Toss pasta through and top with parmesan.',
        ['Spaghetti', 'Tomato', 'Onion', 'Garlic', 'Parmesan cheese'],
      ),
      _RecipeSeed(
        '9',
        'Garlic Butter Egg Toast',
        'Italian',
        10,
        true,
        'vegetarian',
        'Fry egg in garlic butter. Serve over toasted bread and season with salt and pepper.',
        ['Egg', 'Butter', 'Garlic', 'Salt', 'Black pepper'],
      ),
      _RecipeSeed(
        '10',
        'Egg Fried Rice',
        'Chinese',
        20,
        false,
        'vegetarian,gluten_free,dairy_free',
        'Scramble egg and set aside. Fry rice with soy sauce, spring onion and carrot. Mix the egg back in.',
        ['Rice', 'Egg', 'Soy sauce', 'Spring onion', 'Carrot'],
      ),
      _RecipeSeed(
        '11',
        'Ginger Garlic Chicken Stir Fry',
        'Chinese',
        30,
        false,
        'no_pork,dairy_free',
        'Marinate chicken in soy sauce, ginger and garlic. Stir fry with cabbage and carrot until the chicken is cooked through.',
        ['Chicken', 'Ginger', 'Garlic', 'Cabbage', 'Soy sauce', 'Carrot'],
      ),
      _RecipeSeed(
        '12',
        'Simple Egg Drop Soup',
        'Chinese',
        15,
        false,
        'vegetarian,gluten_free,dairy_free,no_pork',
        'Bring seasoned water or stock to a light boil. Drizzle in beaten egg while stirring. Finish with spring onion.',
        ['Water', 'Egg', 'Maggi/bouillon cube', 'Spring onion'],
      ),
      _RecipeSeed(
        '13',
        'Chicken Tacos',
        'Mexican',
        30,
        false,
        'no_pork,dairy_free',
        'Season and cook chicken thoroughly. Warm tortillas. Assemble with onion, cilantro and lime.',
        ['Chicken', 'Tortilla', 'Onion', 'Cilantro', 'Lime'],
      ),
      _RecipeSeed(
        '14',
        'Simple Beef Tacos',
        'Mexican',
        30,
        false,
        'no_pork,dairy_free',
        'Brown beef with onion and garlic. Season to taste. Serve in tortillas with lime and cilantro.',
        ['Beef', 'Tortilla', 'Onion', 'Garlic', 'Lime', 'Cilantro'],
      ),
      _RecipeSeed(
        '15',
        'Egg and Cheese Quesadilla',
        'Mexican',
        15,
        false,
        'vegetarian',
        'Scramble egg. Place it on a tortilla with cheese and fold. Toast in a dry pan until crisp.',
        ['Egg', 'Tortilla', 'Parmesan cheese'],
      ),
    ];

    for (final recipe in recipes) {
      await db.insert('Recipe', {
        'id': recipe.id,
        'name': recipe.name,
        'dietaryTags': recipe.dietaryTags,
        'cultureTag': recipe.culture,
        'prepTimeMinutes': recipe.minutes,
        'energyLevel': recipe.minutes < 20 ? 'low' : 'medium',
        'isStarterRecipe': recipe.isStarter ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      final instructions = recipe.instructions
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((step) => step.trim())
          .where((step) => step.isNotEmpty)
          .toList();
      for (var index = 0; index < instructions.length; index++) {
        await db.insert('Step', {
          'id': '${recipe.id}-${index + 1}',
          'stepOrder': index + 1,
          'instructionText': instructions[index],
          'imageUrl': '',
          'recipe_id': recipe.id,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }

      for (final ingredient in recipe.ingredients) {
        final ingredientId = ingredient.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '-',
        );
        await db.insert('Ingredient', {
          'id': ingredientId,
          'name': ingredient,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        await db.insert('Recipe_Ingredient', {
          'recipe_id': recipe.id,
          'ingredient_id': ingredientId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getRecipes() async {
    final db = await initDatabase();
    final rows = await db.query('Recipe', orderBy: 'name COLLATE NOCASE');
    return _attachIngredientSets(db, rows);
  }

  static Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return getRecipes();

    final db = await initDatabase();
    final rows = await db.rawQuery('''
      SELECT DISTINCT r.*
      FROM Recipe r
      LEFT JOIN Recipe_Ingredient ri ON ri.recipe_id = r.id
      LEFT JOIN Ingredient i ON i.id = ri.ingredient_id
      WHERE r.name LIKE ? COLLATE NOCASE
         OR r.cultureTag LIKE ? COLLATE NOCASE
         OR r.dietaryTags LIKE ? COLLATE NOCASE
         OR i.name LIKE ? COLLATE NOCASE
      ORDER BY r.name COLLATE NOCASE
      ''', List.filled(4, '%$normalized%'));
    return _attachIngredientSets(db, rows);
  }

  static Future<List<Map<String, dynamic>>> _attachIngredientSets(
    Database db,
    List<Map<String, dynamic>> recipes,
  ) async {
    final result = <Map<String, dynamic>>[];
    for (final recipe in recipes) {
      final ingredients = await db.rawQuery(
        '''
        SELECT i.name FROM Ingredient i
        JOIN Recipe_Ingredient ri ON ri.ingredient_id = i.id
        WHERE ri.recipe_id = ?
        ORDER BY i.name COLLATE NOCASE
        ''',
        [recipe['id']],
      );
      result.add({
        ...recipe,
        'ingredientSet': ingredients
            .map((row) => row['name'].toString().toLowerCase())
            .toSet(),
      });
    }
    return result;
  }

  static Future<List<Map<String, dynamic>>> getRecipeSteps(
    String recipeId,
  ) async {
    final db = await initDatabase();
    final steps = await db.query(
      'Step',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'stepOrder ASC',
    );
    return orderRecipeSteps(steps);
  }

  static Future<Map<String, dynamic>?> getRecipeById(
    Database db,
    String id,
  ) async {
    final results = await db.query('Recipe', where: 'id = ?', whereArgs: [id]);
    return results.isEmpty ? null : results.first;
  }

  static Future<void> insertRecipe(
    Database db,
    Map<String, dynamic> recipe,
  ) async {
    await db.insert('Recipe', recipe);
  }

  static Future<void> insertStep(Database db, Map<String, dynamic> step) async {
    await db.insert('Step', step);
  }

  static Future<List<Map<String, dynamic>>> getStepsByRecipeId(
    Database db,
    String recipeId,
  ) async {
    final rows = await db.query(
      'Step',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'stepOrder ASC',
    );
    return rows;
  }

  static double calculateCompatibilityScore(
    Set<String> recipeIngredients,
    Set<String> userIngredients,
  ) {
    if (recipeIngredients.isEmpty) return 0;
    final recipe = recipeIngredients
        .map((item) => item.trim().toLowerCase())
        .toSet();
    final user = userIngredients
        .map((item) => item.trim().toLowerCase())
        .toSet();
    return recipe.intersection(user).length / recipe.length;
  }

  static bool matchesDietaryRestriction(
    String recipeDietaryTags,
    String? userRestriction,
  ) {
    if (userRestriction == null || userRestriction.trim().isEmpty) return true;
    return recipeDietaryTags
        .split(',')
        .map((tag) => tag.trim().toLowerCase())
        .contains(userRestriction.trim().toLowerCase());
  }

  static List<Map<String, dynamic>> filterByDietaryRestriction(
    List<Map<String, dynamic>> allRecipes,
    String? userRestriction,
  ) {
    return allRecipes
        .where(
          (recipe) => matchesDietaryRestriction(
            recipe['dietaryTags']?.toString() ?? '',
            userRestriction,
          ),
        )
        .toList();
  }

  static List<Map<String, dynamic>> getRankedRecommendations(
    List<Map<String, dynamic>> allRecipes,
    Set<String> userIngredients,
    String? userRestriction,
  ) {
    final eligible = filterByDietaryRestriction(allRecipes, userRestriction);
    final ranked = eligible.map((recipe) {
      final ingredients = (recipe['ingredientSet'] as Set<String>? ?? {});
      return {
        ...recipe,
        'score': calculateCompatibilityScore(ingredients, userIngredients),
      };
    }).toList();
    ranked.sort(
      (first, second) =>
          (second['score'] as double).compareTo(first['score'] as double),
    );
    return ranked;
  }

  static List<Map<String, dynamic>> limitDailyRecipes(
    List<Map<String, dynamic>> recipes, {
    int maxPerDay = maxDailyRecipes,
  }) {
    if (maxPerDay <= 0) return const [];
    return recipes.take(maxPerDay).toList(growable: false);
  }

  static List<Map<String, dynamic>> orderRecipeSteps(
    List<Map<String, dynamic>> steps,
  ) {
    final ordered = List<Map<String, dynamic>>.from(steps);
    ordered.sort(
      (first, second) =>
          (first['stepOrder'] as num).compareTo(second['stepOrder'] as num),
    );
    return ordered;
  }

  static bool supportsOfflineMode({
    required bool hasInternetConnection,
    required List<Map<String, dynamic>> cachedRecipes,
    required List<Map<String, dynamic>> cachedSteps,
  }) {
    return hasInternetConnection ||
        (cachedRecipes.isNotEmpty && cachedSteps.isNotEmpty);
  }
}

class _RecipeSeed {
  const _RecipeSeed(
    this.id,
    this.name,
    this.culture,
    this.minutes,
    this.isStarter,
    this.dietaryTags,
    this.instructions,
    this.ingredients,
  );

  final String id;
  final String name;
  final String culture;
  final int minutes;
  final bool isStarter;
  final String dietaryTags;
  final String instructions;
  final List<String> ingredients;
}
