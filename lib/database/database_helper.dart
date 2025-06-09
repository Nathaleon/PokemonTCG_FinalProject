import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<String> getDatabasePath() async {
    return await getDatabasesPath();
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pokemon_tcg.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        email TEXT UNIQUE,
        password_hash TEXT,
        full_name TEXT,
        age INTEGER,
        country TEXT,
        city TEXT,
        profile_image TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE favorite_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        card_id TEXT,
        name TEXT,
        image_url TEXT,
        type TEXT,
        rarity TEXT,
        price REAL,
        added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        UNIQUE(user_id, card_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tournament_registrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        tournament_name TEXT NOT NULL,
        tournament_location TEXT NOT NULL,
        tournament_date TEXT NOT NULL,
        registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        status TEXT DEFAULT 'registered',
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        total_amount REAL NOT NULL,
        currency TEXT NOT NULL,
        purchase_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER,
        card_id TEXT NOT NULL,
        name TEXT NOT NULL,
        image_url TEXT NOT NULL,
        price REAL NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES purchase_history (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS purchase_items');
    await db.execute('DROP TABLE IF EXISTS purchase_history');
    await db.execute('DROP TABLE IF EXISTS tournament_registrations');
    await db.execute('DROP TABLE IF EXISTS favorite_cards');
    await db.execute('DROP TABLE IF EXISTS users');

    await _onCreate(db, newVersion);
  }

  // User Operations
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<bool> isEmailTaken(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty;
  }

  Future<int> updateUser(int userId, Map<String, dynamic> userData) async {
    Database db = await database;
    return await db.update(
      'users',
      userData,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Favorite Cards Operations
  Future<int> addFavoriteCard(Map<String, dynamic> card) async {
    Database db = await database;
    // Check if card already exists for this user
    List<Map<String, dynamic>> existing = await db.query(
      'favorite_cards',
      where: 'user_id = ? AND card_id = ?',
      whereArgs: [card['user_id'], card['card_id']],
    );

    if (existing.isEmpty) {
      return await db.insert('favorite_cards', card);
    }
    return 0; // Card already exists
  }

  Future<List<Map<String, dynamic>>> getFavoriteCards(int userId) async {
    Database db = await database;
    return await db.query(
      'favorite_cards',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'added_at DESC',
    );
  }

  Future<int> removeFavoriteCard(int userId, String cardId) async {
    Database db = await database;
    return await db.delete(
      'favorite_cards',
      where: 'user_id = ? AND card_id = ?',
      whereArgs: [userId, cardId],
    );
  }

  Future<bool> isCardFavorite(int userId, String cardId) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'favorite_cards',
      where: 'user_id = ? AND card_id = ?',
      whereArgs: [userId, cardId],
    );
    return result.isNotEmpty;
  }

  // Tournament Registration Operations
  Future<int> registerTournament(Map<String, dynamic> registration) async {
    Database db = await database;

    // Ensure all required fields are present
    if (!registration.containsKey('tournament_name') ||
        !registration.containsKey('tournament_location') ||
        !registration.containsKey('tournament_date') ||
        !registration.containsKey('user_id')) {
      throw Exception('Missing required fields for tournament registration');
    }

    return await db.insert('tournament_registrations', registration);
  }

  Future<List<Map<String, dynamic>>> getUserTournaments(int userId) async {
    Database db = await database;
    return await db.query(
      'tournament_registrations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tournament_date ASC',
    );
  }

  Future<bool> isUserRegisteredForTournament(
    int userId,
    String tournamentName,
  ) async {
    Database db = await database;

    try {
      List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT * FROM tournament_registrations WHERE user_id = ? AND tournament_name = ?',
        [userId, tournamentName],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking tournament registration: $e');
      return false;
    }
  }

  Future<int> cancelTournamentRegistration(
    int userId,
    String tournamentName,
  ) async {
    Database db = await database;
    return await db.delete(
      'tournament_registrations',
      where: 'user_id = ? AND tournament_name = ?',
      whereArgs: [userId, tournamentName],
    );
  }

  Future<int> updateUserProfileImage(int userId, String imagePath) async {
    Database db = await database;
    return await db.update(
      'users',
      {'profile_image': imagePath},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Purchase History Operations
  Future<int> addPurchase(
    Map<String, dynamic> purchase,
    List<Map<String, dynamic>> items,
  ) async {
    Database db = await database;
    final purchaseId = await db.insert('purchase_history', purchase);

    for (var item in items) {
      item['purchase_id'] = purchaseId;
      await db.insert('purchase_items', item);
    }

    return purchaseId;
  }

  Future<List<Map<String, dynamic>>> getUserPurchases(int userId) async {
    Database db = await database;
    return await db.query(
      'purchase_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'purchase_date DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPurchaseItems(int purchaseId) async {
    Database db = await database;
    return await db.query(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
  }

  Future<int> deletePurchase(int purchaseId) async {
    Database db = await database;
    await db.delete(
      'purchase_items',
      where: 'purchase_id = ?',
      whereArgs: [purchaseId],
    );
    return await db.delete(
      'purchase_history',
      where: 'id = ?',
      whereArgs: [purchaseId],
    );
  }

  Future<void> clearPurchaseHistory(int userId) async {
    Database db = await database;
    final purchases = await getUserPurchases(userId);
    for (var purchase in purchases) {
      await deletePurchase(purchase['id']);
    }
  }

  // Helper method to delete the database (useful for testing and debugging)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'pokemon_tcg.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // Helper method to check if table exists
  Future<bool> _tableExists(Database db, String tableName) async {
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return result.isNotEmpty;
  }

  // Helper method to get table info
  Future<List<Map<String, dynamic>>> _getTableInfo(
    Database db,
    String tableName,
  ) async {
    return await db.rawQuery('PRAGMA table_info($tableName)');
  }

  Future<List<Map<String, dynamic>>> getUpcomingTournaments() async {
    Database db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.query(
      'tournament_registrations',
      where: 'tournament_date > ?',
      whereArgs: [now],
      orderBy: 'tournament_date ASC',
      limit: 3,
    );
  }
}
