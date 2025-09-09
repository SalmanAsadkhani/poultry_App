import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/breeding_cycle.dart';

class DatabaseHelper {
  static const _databaseName = "PoultryApp.db";
  static const _databaseVersion = 1;

  static const tableCycles = 'breeding_cycles';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCycles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        chick_count INTEGER NOT NULL,
        is_active INTEGER NOT NULL
      )
    ''');
    
    // ⚠️ در آینده اگر جدول‌های وابسته داری (مثلاً cycle_records)، اینجا هم تعریف کن.
  }

  // ─────────────── CRUD ───────────────

  // ۱. Insert
  Future<int> insertCycle(BreedingCycle cycle) async {
    final db = await instance.database;
    return await db.insert(tableCycles, cycle.toMap());
  }

  // ۲. Select all
  Future<List<BreedingCycle>> getAllCycles() async {
    final db = await instance.database;
    final maps = await db.query(tableCycles, orderBy: "id DESC");
    return List.generate(maps.length, (i) => BreedingCycle.fromMap(maps[i]));
  }

  // ۳. Update
  Future<int> updateCycle(BreedingCycle cycle) async {
    final db = await instance.database;
    return await db.update(
      tableCycles,
      cycle.toMap(),
      where: "id = ?",
      whereArgs: [cycle.id],
    );
  }

  // ۴. Delete
  Future<int> deleteCycle(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableCycles,
      where: "id = ?",
      whereArgs: [id],
    );
  }

  // ─────────────── Helpers ───────────────

  // بررسی اینکه این دوره داده وابسته دارد یا نه
  Future<bool> hasRelatedData(int cycleId) async {
    final db = await instance.database;

    // ⚠️ اینجا فرضی نوشتم، باید جایگزین جدول واقعی کنی
    // مثلا جدول 'cycle_records' اگر رکورد وابسته داری
    final result = await db.query(
      "cycle_records", // اینو باید با جدول واقعی‌ات جایگزین کنی
      where: "cycle_id = ?",
      whereArgs: [cycleId],
    );

    return result.isNotEmpty;
  }
}
