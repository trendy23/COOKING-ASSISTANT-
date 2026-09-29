import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> initDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'cooking_assistant.db'),
      onCreate: (db, version) async {
        // Your CREATE TABLE statements go here, one execute() call each
        await db.execute('PRAGMA foreign_keys = ON');
        await db.execute('''CREATE TABLE Profile (
    id TEXT PRIMARY KEY,                                        -- unique ID for each profile row
    name TEXT NOT NULL,                                         -- must always have a name
    tier TEXT NOT NULL CHECK (tier IN ('FREEMIUM','PREMIUM')) DEFAULT 'FREEMIUM'  -- only 2 legal values, defaults to FREEMIUM
);''');
        
        await db.execute('''CREATE TABLE Recipe (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    dietaryTags TEXT NOT NULL,
    cultureTag TEXT NOT NULL,
    prepTimeMinutes INTEGER,
    energyLevel TEXT NOT NULL,
    isStarterRecipe INTEGER DEFAULT 0
);''');
        await db.execute('''CREATE TABLE Step (
    id TEXT PRIMARY KEY,                          -- unique ID for THIS step row
    stepOrder INTEGER NOT NULL,                    -- position within its recipe (can repeat across recipes)
    instructionText TEXT NOT NULL,
    imageUrl TEXT NOT NULL,
    recipe_id TEXT NOT NULL,                       -- which Recipe this step belongs to
    FOREIGN KEY (recipe_id) REFERENCES Recipe(id)  -- enforces that link
);''');
        
        await db.execute('''CREATE TABLE Ingredient (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL
);''');
        await db.execute ('''CREATE TABLE Recipe_Ingredient (
    recipe_id TEXT NOT NULL,
    ingredient_id TEXT NOT NULL,
    FOREIGN KEY (recipe_id) REFERENCES Recipe(id),
    FOREIGN KEY (ingredient_id) REFERENCES Ingredient(id),
    PRIMARY KEY (recipe_id, ingredient_id)
);''');
        await db.execute('''CREATE TABLE Profile_Recipe (                                                                                                                                                        
    profile_id TEXT NOT NULL,
    recipe_id TEXT NOT NULL,
    FOREIGN KEY (profile_id) REFERENCES Profile(id),
    FOREIGN KEY (recipe_id) REFERENCES Recipe(id),
    PRIMARY KEY (profile_id, recipe_id)
);''');
      },
      version: 1,
    );
  }

// CRUD Database Access//

  static Future<void> insertIngredient(Database db, Map<String, dynamic> ingredient) async {
  await db.insert('Ingredient', ingredient);
}

static Future<Map<String, dynamic>?> getIngredientById(Database db, String id) async {
  final results = await db.query(
    'Ingredient',
    where: 'id = ?',
    whereArgs: [id],
  );
  if (results.isEmpty) return null;
  return results.first;
}

static Future<int> deleteIngredient(Database db, String id) async {
  return await db.delete(
    'Ingredient',
    where: 'id = ?',
    whereArgs: [id],
  );
}

static Future<int> updateIngredient(Database db, String id, Map<String, dynamic> newValues) async {
  return await db.update(
    'Ingredient',
    newValues,
    where: 'id = ?',
    whereArgs: [id],
  );
}

static Future<void> insertRecipe(Database db, Map<String, dynamic> recipe) async {
  await db.insert ('Recipe', recipe);
}

static Future<Map<String, dynamic>?> getRecipeById(Database db, String id) async {
  final results = await db.query(
    'Recipe',
    where: 'id = ?',
    whereArgs: [id],
  );
  if (results.isEmpty) return null;
  return results.first;
}

static Future<int> deleteRecipe(Database db, String id) async {
  return await db.delete(
    'Recipe',
    where: 'id = ?',
    whereArgs: [id],
  );
}

static Future<int> updateRecipe(Database db, String id, Map<String, dynamic> newValues) async {
  return await db.update(
    'Recipe',
    newValues,
    where: 'id = ?',
    whereArgs: [id],
  );
}

static Future<void> insertProfile(Database db, Map<String, dynamic> profile) async {
  await db.insert('Profile', profile);
}

static Future<Map<String, dynamic>?> getProfileById(Database db, String id) async {
  final results = await db.query(
    'Profile',
     where: 'id = ?',
     whereArgs: [id]);
     if (results.isEmpty) return null;
     
     return results.first;
}

static Future<int> updateProfileTier(Database db, String id, String newTier) async {
  return await db.update(
    'Profile', 
    {'tier': newTier} ,
    where: 'id = ?' , 
    whereArgs: [id]);

}

static Future<void> insertStep(Database db, Map<String, dynamic> step) async {
  await db.insert('Step', step);
}

static Future<List<Map<String, dynamic>>> getStepsByRecipeId(Database db, String recipe_id,) async {
  final results = await db.query(
    'Step' ,
    where: 'recipe_id = ?',
    whereArgs: [recipe_id]
  );
  return results;
}
// Recommendation logic engine//

static double calculateCompatibilityScore(Set<String> recipeIngredients, Set<String> userIngredients) {
  if (recipeIngredients.isEmpty) return 0.0;
  Set<String> overlap = recipeIngredients.intersection(userIngredients);
  double score = overlap.length / recipeIngredients.length;
  return score;
}

static bool matchesDietaryRestriction(String recipeDietaryTags, String? userRestriction) {
  if (userRestriction == null || userRestriction.isEmpty) {
    return true;
  }
  List<String> tags = recipeDietaryTags.split(',');
  return tags.contains(userRestriction);
}

static List<Map<String, dynamic>> filterByDietaryRestriction(List<Map<String, dynamic>> allRecipes, String? userRestriction) {
  List<Map<String, dynamic>> eligible = [];
  for (var recipe in allRecipes) {
    if (matchesDietaryRestriction(recipe['dietaryTags'], userRestriction)) {
      eligible.add(recipe);
    }
  }
  return eligible;
}

static List<Map<String, dynamic>> getRankedRecommendations(
  List<Map<String, dynamic>> allRecipes,
  Set<String> userIngredients,
  String? userRestriction,
) {
  List<Map<String, dynamic>> eligible = filterByDietaryRestriction(allRecipes, userRestriction);

  for (var recipe in eligible) {
    Set<String> recipeIngredients = recipe['ingredientSet'];
    recipe['score'] = calculateCompatibilityScore(recipeIngredients, userIngredients);
  }

  eligible.sort((a, b) => b['score'].compareTo(a['score']));

  return eligible;
}
}