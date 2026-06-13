import 'package:out_of_mind/models/planned_purchase.dart';
import 'package:out_of_mind/models/purchase.dart';
import 'package:out_of_mind/models/tracked_location.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  Future<Database> initDB() async {
    final path = join(await getDatabasesPath(), 'main_db.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Purchases (
        id INTEGER PRIMARY KEY,
        mood TEXT,
        amount REAL,
        location TEXT,
        date DATETIME,
        impulse INTEGER DEFAULT 3,
        name TEXT,
        notes TEXT,
        tag TEXT DEFAULT 'Want'
      )
    ''');
    await db.execute('''
      CREATE TABLE Planned (
        id INTEGER PRIMARY KEY,
        name TEXT,
        amount REAL,
        reminder_date DATETIME,
        mood TEXT,
        notes TEXT,
        created_at TEXT,
        status TEXT DEFAULT 'active',
        won_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE TrackedLocations (
        id INTEGER PRIMARY KEY,
        name TEXT,
        latitude REAL,
        longitude REAL,
        radius_meters REAL DEFAULT 200,
        created_at TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE Planned ADD COLUMN notes TEXT');
      await db.execute('ALTER TABLE Planned ADD COLUMN created_at TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE Purchases ADD COLUMN impulse INTEGER DEFAULT 3');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE Purchases ADD COLUMN name TEXT');
      await db.execute('ALTER TABLE Purchases ADD COLUMN notes TEXT');
      await db.execute("ALTER TABLE Purchases ADD COLUMN tag TEXT DEFAULT 'Want'");
      await db.execute("ALTER TABLE Planned ADD COLUMN status TEXT DEFAULT 'active'");
      await db.execute('ALTER TABLE Planned ADD COLUMN won_at TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS TrackedLocations (
          id INTEGER PRIMARY KEY,
          name TEXT,
          latitude REAL,
          longitude REAL,
          radius_meters REAL DEFAULT 200,
          created_at TEXT
        )
      ''');
    }
  }

  // ─── Purchases ─────────────────────────────────────────────────────────────

  Future<int> insertPurchase(Purchase purchase) async {
    final db = await instance.database;
    return await db.insert('Purchases', purchase.toMap());
  }

  Future<List<Purchase>> getPurchases() async {
    final db = await instance.database;
    final maps = await db.query('Purchases', orderBy: 'date DESC');
    return maps.map(Purchase.fromMap).toList();
  }

  Future<int> updatePurchase(Purchase purchase) async {
    final db = await instance.database;
    return await db.update(
      'Purchases',
      purchase.toMap(),
      where: 'id = ?',
      whereArgs: [purchase.id],
    );
  }

  Future<int> deletePurchase(int id) async {
    final db = await instance.database;
    return await db.delete('Purchases', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Planned ───────────────────────────────────────────────────────────────

  Future<int> insertPlanned(PlannedPurchase planned) async {
    final db = await instance.database;
    return await db.insert('Planned', planned.toMap());
  }

  /// Active items only (status = 'active' or legacy rows with NULL status).
  Future<List<PlannedPurchase>> getPlanned() async {
    final db = await instance.database;
    final maps = await db.query(
      'Planned',
      where: "status = 'active' OR status IS NULL",
    );
    return maps.map(PlannedPurchase.fromMap).toList();
  }

  /// Items the user successfully resisted buying.
  Future<List<PlannedPurchase>> getWins() async {
    final db = await instance.database;
    final maps = await db.query(
      'Planned',
      where: "status = 'won'",
      orderBy: 'won_at DESC',
    );
    return maps.map(PlannedPurchase.fromMap).toList();
  }

  /// Mark a planned item as won (user resisted the urge).
  Future<int> markAsWon(int id) async {
    final db = await instance.database;
    return await db.update(
      'Planned',
      {'status': 'won', 'won_at': DateTime.now().toString()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Move a planned item to purchases and mark it as bought.
  Future<void> confirmPlanned(PlannedPurchase planned) async {
    final db = await instance.database;
    final purchase = Purchase(
      mood: planned.mood,
      amount: planned.amount ?? 0,
      location: 'Planned purchase',
      date: DateTime.now().toString(),
      name: planned.name,
      tag: 'Want',
    );
    await insertPurchase(purchase);
    await db.update(
      'Planned',
      {'status': 'bought'},
      where: 'id = ?',
      whereArgs: [planned.id],
    );
  }

  Future<int> deletePlanned(int id) async {
    final db = await instance.database;
    return await db.delete('Planned', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updatePlannedMood(int id, String mood) async {
    final db = await instance.database;
    return await db.update(
      'Planned',
      {'mood': mood},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ─── Tracked Locations ─────────────────────────────────────────────────────

  Future<int> insertTrackedLocation(TrackedLocation loc) async {
    final db = await instance.database;
    return await db.insert('TrackedLocations', loc.toMap());
  }

  Future<List<TrackedLocation>> getTrackedLocations() async {
    final db = await instance.database;
    final maps =
        await db.query('TrackedLocations', orderBy: 'created_at DESC');
    return maps.map(TrackedLocation.fromMap).toList();
  }

  Future<int> deleteTrackedLocation(int id) async {
    final db = await instance.database;
    return await db.delete('TrackedLocations',
        where: 'id = ?', whereArgs: [id]);
  }
}
