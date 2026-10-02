import 'package:cooking_assistant/access/local_access_manager.dart';
import 'package:cooking_assistant/database/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Recipe compatibility algorithm', () {
    test('returns a perfect score when ingredients fully match', () {
      final score = DatabaseHelper.calculateCompatibilityScore(
        {'tomato', 'garlic', 'onion'},
        {'tomato', 'garlic', 'onion'},
      );

      expect(score, 1.0);
    });

    test('returns a partial score for partially compatible ingredient lists', () {
      final score = DatabaseHelper.calculateCompatibilityScore(
        {'tomato', 'garlic', 'onion', 'pepper'},
        {'tomato', 'garlic', 'basil'},
      );

      expect(score, closeTo(0.5, 0.0001));
    });

    test('returns zero when no ingredients overlap', () {
      final score = DatabaseHelper.calculateCompatibilityScore(
        {'tomato', 'garlic'},
        {'lentils', 'rice'},
      );

      expect(score, 0.0);
    });

    test('ranks recipes by compatibility while honoring dietary restrictions', () {
      final recipes = [
        {
          'name': 'Tomato Soup',
          'dietaryTags': 'vegan',
          'ingredientSet': {'tomato', 'garlic', 'onion'},
        },
        {
          'name': 'Chicken Curry',
          'dietaryTags': 'non-vegetarian',
          'ingredientSet': {'tomato', 'chicken', 'coconut'},
        },
        {
          'name': 'Lentil Bowl',
          'dietaryTags': 'vegan',
          'ingredientSet': {'lentils', 'rice', 'tomato'},
        },
      ];

      final ranked = DatabaseHelper.getRankedRecommendations(
        recipes,
        {'tomato', 'garlic', 'onion'},
        'vegan',
      );

      expect(ranked.map((recipe) => recipe['name']).toList(), [
        'Tomato Soup',
        'Lentil Bowl',
      ]);
      expect(ranked.first['score'], 1.0);
    });
  });

  group('Seven recipe daily limit', () {
    test('limits suggestions to seven recipes per daily cycle', () {
      final recipes = List.generate(12, (index) => {'name': 'Recipe $index'});

      final limited = DatabaseHelper.limitDailyRecipes(recipes, maxPerDay: 7);

      expect(limited.length, 7);
      expect(limited.first['name'], 'Recipe 0');
      expect(limited.last['name'], 'Recipe 6');
    });
  });

  group('Step-by-step flow', () {
    test('orders steps by their recipe sequence', () {
      final steps = [
        {'stepOrder': 3, 'instructionText': 'Finish and serve'},
        {'stepOrder': 1, 'instructionText': 'Prep the ingredients'},
        {'stepOrder': 2, 'instructionText': 'Cook the mixture'},
      ];

      final ordered = DatabaseHelper.orderRecipeSteps(steps);

      expect(
        ordered.map((step) => step['instructionText']).toList(),
        [
          'Prep the ingredients',
          'Cook the mixture',
          'Finish and serve',
        ],
      );
    });
  });

  group('Offline readiness', () {
    test('allows offline support when cached recipes and steps are available', () {
      final supported = DatabaseHelper.supportsOfflineMode(
        hasInternetConnection: false,
        cachedRecipes: [{'id': 'r1'}],
        cachedSteps: [{'recipe_id': 'r1', 'stepOrder': 1}],
      );

      expect(supported, isTrue);
    });

    test('blocks offline access when data cache is empty', () {
      final supported = DatabaseHelper.supportsOfflineMode(
        hasInternetConnection: false,
        cachedRecipes: const [],
        cachedSteps: const [],
      );

      expect(supported, isFalse);
    });
  });

  group('Backend integration', () {
    test('inserts and reads recipe data through SQLite', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) async {
          await database.execute('PRAGMA foreign_keys = ON');
          await database.execute('''
            CREATE TABLE Recipe (
              id TEXT NOT NULL PRIMARY KEY,
              name TEXT NOT NULL,
              dietaryTags TEXT NOT NULL,
              cultureTag TEXT NOT NULL,
              prepTimeMinutes INTEGER,
              energyLevel TEXT NOT NULL,
              isStarterRecipe INTEGER DEFAULT 0
            );
          ''');
          await database.execute('''
            CREATE TABLE Step (
              id TEXT PRIMARY KEY,
              stepOrder INTEGER NOT NULL,
              instructionText TEXT NOT NULL,
              imageUrl TEXT NOT NULL,
              recipe_id TEXT NOT NULL,
              FOREIGN KEY (recipe_id) REFERENCES Recipe(id)
            );
          ''');
        },
      );

      try {
        await DatabaseHelper.insertRecipe(db, {
          'id': 'recipe-1',
          'name': 'Tomato Soup',
          'dietaryTags': 'vegan',
          'cultureTag': 'African',
          'prepTimeMinutes': 25,
          'energyLevel': 'easy',
          'isStarterRecipe': 1,
        });

        await DatabaseHelper.insertStep(db, {
          'id': 'step-1',
          'stepOrder': 1,
          'instructionText': 'Chop ingredients.',
          'imageUrl': 'https://example.invalid/image-1.png',
          'recipe_id': 'recipe-1',
        });

        await DatabaseHelper.insertStep(db, {
          'id': 'step-2',
          'stepOrder': 2,
          'instructionText': 'Simmer until smooth.',
          'imageUrl': 'https://example.invalid/image-2.png',
          'recipe_id': 'recipe-1',
        });

        final recipe = await DatabaseHelper.getRecipeById(db, 'recipe-1');
        final steps = await DatabaseHelper.getStepsByRecipeId(db, 'recipe-1');

        expect(recipe, isNotNull);
        expect(recipe!['name'], 'Tomato Soup');
        expect(steps.length, 2);
        expect(DatabaseHelper.orderRecipeSteps(steps).first['stepOrder'], 1);
      } finally {
        await db.close();
      }
    });

    test('tracks free daily usage, resets by date, and unlocks premium', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (database, version) => DatabaseHelper.createSchema(database),
      );
      try {
        for (var index = 1; index <= 9; index++) {
          await db.insert('Recipe', {
            'id': 'daily-$index',
            'name': 'Daily recipe $index',
            'dietaryTags': '',
            'cultureTag': 'Test',
            'energyLevel': 'low',
          });
        }
        await db.insert('Redeem_Code', {'code': 'TEST-PREMIUM'});

        final access = LocalAccessManager(database: db, profileId: 'test-user');
        final today = DateTime(2026, 10, 3, 12);
        for (var index = 1; index <= 7; index++) {
          expect(await access.consumeRecipe('daily-$index', now: today), isTrue);
        }
        expect(await access.consumeRecipe('daily-8', now: today), isFalse);
        expect(await access.consumeRecipe('daily-1', now: today), isTrue);
        expect((await access.load(now: today)).recipesUsedToday, 7);

        expect(
          await access.consumeRecipe(
            'daily-8',
            now: today.add(const Duration(days: 1)),
          ),
          isTrue,
        );
        expect(await access.redeemCode('invalid-code'), isFalse);
        expect(await access.redeemCode(' test-premium '), isTrue);
        expect((await access.load(now: today)).isPremium, isTrue);
        expect(await access.consumeRecipe('daily-9', now: today), isTrue);
      } finally {
        await db.close();
      }
    });
  });
}
