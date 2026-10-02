import 'package:cooking_assistant/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class AccessStatus {
  const AccessStatus({
    this.tier = 'FREEMIUM',
    this.recipesUsedToday = 0,
    this.dailyLimit = DatabaseHelper.maxDailyRecipes,
  });

  final String tier;
  final int recipesUsedToday;
  final int dailyLimit;

  bool get isPremium => tier == 'PREMIUM';
  int get recipesRemainingToday =>
      isPremium ? -1 : (dailyLimit - recipesUsedToday).clamp(0, dailyLimit).toInt();
}

class LocalAccessManager {
  LocalAccessManager({
    Database? database,
    this.profileId = 'local-user',
  }) {
    _database = database;
  }

  final String profileId;
  Database? _database;

  Future<Database> get _db async =>
      _database ??= await DatabaseHelper.initDatabase();

  Future<void> _ensureProfile(DatabaseExecutor db) async {
    await db.insert(
      'Profile',
      {'id': profileId, 'name': 'Local cook', 'tier': 'FREEMIUM'},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<AccessStatus> load({DateTime? now}) async {
    final db = await _db;
    await _ensureProfile(db);
    final profile = await db.query(
      'Profile',
      columns: ['tier'],
      where: 'id = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (profile.isEmpty) {
      throw StateError('Local profile could not be initialized.');
    }
    final tier = profile.first['tier']! as String;
    final usage = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM Daily_Usage '
      'WHERE profile_id = ? AND usage_date = ?',
      [profileId, _dateKey(now ?? DateTime.now())],
    );
    final used = (usage.first['total']! as num).toInt();
    return AccessStatus(tier: tier, recipesUsedToday: used);
  }

  Future<bool> redeemCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return false;
    final db = await _db;

    return db.transaction((txn) async {
      await _ensureProfile(txn);
      final profile = await txn.query(
        'Profile',
        columns: ['tier'],
        where: 'id = ?',
        whereArgs: [profileId],
        limit: 1,
      );
      if (profile.first['tier'] == 'PREMIUM') return true;

      final matchingCodes = await txn.query(
        'Redeem_Code',
        columns: ['code'],
        where: 'code = ? AND is_used = 0',
        whereArgs: [normalized],
        limit: 1,
      );
      if (matchingCodes.isEmpty) return false;

      final claimed = await txn.update(
        'Redeem_Code',
        {'is_used': 1, 'used_by': profileId},
        where: 'code = ? AND is_used = 0',
        whereArgs: [matchingCodes.first['code']],
      );
      if (claimed != 1) return false;

      await txn.update(
        'Profile',
        {'tier': 'PREMIUM'},
        where: 'id = ?',
        whereArgs: [profileId],
      );
      return true;
    });
  }

  Future<bool> consumeRecipe(String recipeId, {DateTime? now}) async {
    final db = await _db;
    final day = _dateKey(now ?? DateTime.now());

    return db.transaction((txn) async {
      await _ensureProfile(txn);
      final profile = await txn.query(
        'Profile',
        columns: ['tier'],
        where: 'id = ?',
        whereArgs: [profileId],
        limit: 1,
      );
      if (profile.isEmpty) {
        throw StateError('Local profile could not be initialized.');
      }

      final alreadyUsed = await txn.query(
        'Daily_Usage',
        columns: ['recipe_id'],
        where: 'profile_id = ? AND usage_date = ? AND recipe_id = ?',
        whereArgs: [profileId, day, recipeId],
        limit: 1,
      );
      if (alreadyUsed.isNotEmpty) return true;

      if (profile.first['tier'] != 'PREMIUM') {
        final usage = await txn.rawQuery(
          'SELECT COUNT(*) AS total FROM Daily_Usage '
          'WHERE profile_id = ? AND usage_date = ?',
          [profileId, day],
        );
        if ((usage.first['total']! as num).toInt() >=
            DatabaseHelper.maxDailyRecipes) {
          return false;
        }
      }

      await txn.insert('Daily_Usage', {
        'profile_id': profileId,
        'usage_date': day,
        'recipe_id': recipeId,
      });
      return true;
    });
  }

  static String _dateKey(DateTime date) {
    final localDate = date.toLocal();
    final year = localDate.year.toString().padLeft(4, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
