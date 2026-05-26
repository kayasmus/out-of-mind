import 'package:out_of_mind/models/location.dart';
import 'package:out_of_mind/models/planned_purchase.dart';
import 'package:out_of_mind/models/purchase.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  // Getter to provide the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  // Initialize the database and create tables
  Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'main_db.db');
    return await openDatabase(
    path,
    version: 2,
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
);
  }

  // Create table structure
  Future _onCreate(Database db, int version) async {
    await db.execute(
    "CREATE TABLE Purchases (id INTEGER PRIMARY KEY, mood TEXT, amount REAL, location TEXT, date DATETIME )");
      await db.execute(
     "CREATE TABLE Planned (id INTEGER PRIMARY KEY, name TEXT, amount REAL, reminder_date DATETIME, mood TEXT)");
      await db.execute(
      "CREATE TABLE Locations (id INTEGER PRIMARY KEY, name TEXT, link TEXT)");
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute("ALTER TABLE Planned ADD COLUMN notes TEXT");
    await db.execute("ALTER TABLE Planned ADD COLUMN created_at TEXT");
  }
}

  //Insert purchases
  Future<int> insertPurchase(Purchase purchase) async {
    Database db = await instance.database;
    return await db.insert('Purchases', purchase.toMap());
  }

  Future<int> insertPlanned(PlannedPurchase planned) async {
    Database db = await instance.database;
    return await db.insert('Planned', planned.toMap());
  }

  Future<int> insertLocations(Location locations) async {
    Database db = await instance.database;
    return await db.insert('Locations', locations.toMap());
  }

  Future<List<Purchase>> getPurchases() async{
      Database db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query('Purchases');
      return List.generate(maps.length, (i) => Purchase.fromMap(maps[i]));
  }

  Future<List<PlannedPurchase>> getPlanned() async{
      Database db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query('Planned');
      return List.generate(maps.length, (i) => PlannedPurchase.fromMap(maps[i]));
  }

  Future<List<Location>> getLocation() async{
      Database db = await instance.database;
      final List<Map<String, dynamic>> maps = await db.query('Locations');
      return List.generate(maps.length, (i) => Location.fromMap(maps[i]));
  }

  Future<int> deletePlanned(int id) async {
  Database db = await instance.database;
  return await db.delete('Planned', where: 'id = ?', whereArgs: [id]);
}

  Future<int> updatePlannedMood(int id, String mood) async {
    Database db = await instance.database;
    return await db.update(
      'Planned',
      {'mood': mood},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
