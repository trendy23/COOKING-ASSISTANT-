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
}