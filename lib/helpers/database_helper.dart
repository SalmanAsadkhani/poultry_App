import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/breeding_cycle.dart';
import '../models/daily_report.dart';
import '../models/feed_consumption.dart';
import '../models/expense.dart';
import '../models/income.dart';

class DatabaseHelper {
  static const _databaseName = "PoultryApp.db";
  static const _databaseVersion = 2; // ✅ افزایش version برای migration
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
      onUpgrade: _onUpgrade, // ✅ اضافه شد برای migration
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // اگر تغییری در schema داری، اینجا اعمال کن (مثل ALTER TABLE ADD COLUMN)
      // برای مثال، اگر weight رو به REAL تغییر دادی:
      // await db.execute('ALTER TABLE expenses ADD COLUMN weight REAL;');
      // اما چون جدول کامل rebuild می‌شه، معمولاً لازم نیست
    }
  }

  // در فایل lib/helpers/database_helper.dart
  Future _onCreate(Database db, int version) async {
    // ... (جدول breeding_cycles و daily_reports بدون تغییر باقی می‌مانند) ...
    await db.execute('''
      CREATE TABLE $tableCycles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        chick_count INTEGER NOT NULL,
        is_active INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cycle_id INTEGER NOT NULL,
        report_date TEXT NOT NULL,
        mortality INTEGER NOT NULL DEFAULT 0,
        medicine TEXT,
        notes TEXT,
        FOREIGN KEY (cycle_id) REFERENCES $tableCycles (id) ON DELETE CASCADE
      )
    ''');

    // ✅ تغییر در این جدول اعمال شده است
    await db.execute('''
      CREATE TABLE feed_consumptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        report_id INTEGER NOT NULL,
        feed_type TEXT NOT NULL,
        quantity REAL NOT NULL,
        bag_count INTEGER NOT NULL DEFAULT 0, -- ✅ ستون جدید اضافه شد
        FOREIGN KEY (report_id) REFERENCES daily_reports (id) ON DELETE CASCADE
      )
    ''');

    // در فایل lib/helpers/database_helper.dart داخل متد _onCreate
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cycle_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unit_price REAL,
        description TEXT,
        bag_count INTEGER,
        weight REAL, -- ✅ از INTEGER به REAL تغییر کرد
        FOREIGN KEY (cycle_id) REFERENCES breeding_cycles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE incomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cycle_id INTEGER NOT NULL,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        quantity INTEGER,
        weight REAL, -- ✅ از INTEGER به REAL تغییر کرد
        unit_price REAL,
        description TEXT,
        FOREIGN KEY (cycle_id) REFERENCES breeding_cycles (id) ON DELETE CASCADE
      )
    ''');
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
  // بررسی اینکه آیا یک دوره، داده وابسته (گزارش روزانه یا هزینه) دارد یا نه
  Future<bool> hasRelatedData(int cycleId) async {
    final db = await instance.database;
    // ۱. ابتدا جدول گزارشات روزانه را بررسی کن
    final reportsResult = await db.query(
      'daily_reports', // ✅ نام جدول صحیح
      where: "cycle_id = ?",
      whereArgs: [cycleId],
      limit: 1, // فقط به یک نتیجه نیاز داریم تا بفهمیم داده وجود دارد یا نه
    );
    // اگر حتی یک گزارش پیدا شد، یعنی داده وابسته وجود دارد و ادامه نده
    if (reportsResult.isNotEmpty) {
      return true;
    }
    // ۲. اگر گزارشی نبود، حالا جدول هزینه‌ها را بررسی کن
    final expensesResult = await db.query(
      'expenses', // ✅ نام جدول صحیح
      where: "cycle_id = ?",
      whereArgs: [cycleId],
      limit: 1, // اینجا هم یک نتیجه کافیست
    );
    // اگر هزینه‌ای پیدا شد، باز هم یعنی داده وابسته وجود دارد
    if (expensesResult.isNotEmpty) {
      return true;
    }
    // اگر هیچکدام از موارد بالا داده‌ای برنگرداندند، یعنی دوره خالی است و قابل حذف
    return false;
  }

  // این کد را به انتهای کلاس DatabaseHelper اضافه کن
  // درج گزارش روزانه و دان‌های مصرفی آن (با استفاده از Transaction)
  Future<void> insertDailyReport(DailyReport report, List<FeedConsumption> feeds) async {
    final db = await instance.database;
    // Transaction تضمین می‌کند که یا همه‌ی عملیات با موفقیت انجام می‌شود یا هیچکدام
    await db.transaction((txn) async {
      // 1. گزارش اصلی را درج کن و ID آن را بگیر
      final reportId = await txn.insert('daily_reports', report.toMap());
      // 2. به ازای هر آیتم در لیست دان، آن را با reportId جدید درج کن
      for (final feed in feeds) {
        // یک کپی از مپ می‌سازیم تا بتوانیم آن را تغییر دهیم
        final feedMap = Map<String, dynamic>.from(feed.toMap());
        feedMap['report_id'] = reportId; // اتصال به گزارش اصلی
        await txn.insert('feed_consumptions', feedMap);
      }
    });
  }

  // واکشی تمام گزارشات یک دوره به همراه دان‌های مصرفی
  // در فایل lib/helpers/database_helper.dart
  // واکشی تمام گزارشات یک دوره به همراه دان‌های مصرفی
  Future<List<DailyReport>> getAllReportsForCycle(int cycleId) async {
    final db = await instance.database;

    // ✅✅✅ تغییر اصلی اینجاست: DESC به ASC تغییر کرد ✅✅✅
    final reportMaps = await db.query(
      'daily_reports',
      where: 'cycle_id = ?',
      whereArgs: [cycleId],
      orderBy: 'report_date ASC' // مرتب‌سازی صعودی (از قدیمی به جدید)
    );

    if (reportMaps.isEmpty) return [];
    final List<DailyReport> reports = [];
    for (var reportMap in reportMaps) {
      final feedMaps = await db.query('feed_consumptions', where: 'report_id = ?', whereArgs: [reportMap['id']]);
      final feeds = feedMaps.map((feed) => FeedConsumption.fromMap(feed)).toList();

      final report = DailyReport.fromMap(reportMap);
      reports.add(
        DailyReport(
          id: report.id,
          cycleId: report.cycleId,
          reportDate: report.reportDate,
          mortality: report.mortality,
          medicine: report.medicine,
          notes: report.notes,
          feedConsumed: feeds,
        ),
      );
    }
    return reports;
  }

  // این کد را به انتهای کلاس DatabaseHelper اضافه کنید
  // --- CRUD برای هزینه‌ها (Expenses) ---
  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); // ✅ اضافه شد برای safety
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    return await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // گرفتن تمام هزینه‌های یک دوره، با قابلیت فیلتر بر اساس دسته‌بندی
  Future<List<Expense>> getExpensesForCycle(int cycleId, {String? category}) async {
    final db = await instance.database;
    List<Map<String, dynamic>> maps;
    if (category != null) {
      maps = await db.query(
        'expenses', 
        where: 'cycle_id = ? AND category = ?', 
        whereArgs: [cycleId, category], 
        orderBy: 'id ASC'  // ✅ تغییر به id ASC (۱، ۲، ۳، ...)
      );
    } else {
      maps = await db.query(
        'expenses', 
        where: 'cycle_id = ?', 
        whereArgs: [cycleId], 
        orderBy: 'id ASC'  // ✅ یکسان برای همه
      );
    }
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  // در انتهای کلاس DatabaseHelper اضافه شود
  // آپدیت کردن یک گزارش روزانه و دان‌های مصرفی آن
  Future<void> updateDailyReport(DailyReport report, List<FeedConsumption> feeds) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // ۱. اطلاعات اصلی گزارش را آپدیت کن
      await txn.update(
        'daily_reports',
        report.toMap(),
        where: 'id = ?',
        whereArgs: [report.id],
      );
      // ۲. تمام رکوردهای دان مصرفی قبلی مربوط به این گزارش را حذف کن
      await txn.delete('feed_consumptions', where: 'report_id = ?', whereArgs: [report.id]);
      // ۳. رکوردهای جدید دان مصرفی را درج کن
      for (final feed in feeds) {
        final feedMap = Map<String, dynamic>.from(feed.toMap());
        feedMap['report_id'] = report.id;
        await txn.insert('feed_consumptions', feedMap);
      }
    });
  }

  // در انتهای کلاس DatabaseHelper اضافه شود
  // حذف یک گزارش روزانه و تمام داده‌های وابسته‌ی آن
  Future<void> deleteDailyReport(int reportId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      // ابتدا تمام رکوردهای دان مصرفی مربوط به این گزارش را حذف می‌کنیم
      await txn.delete('feed_consumptions', where: 'report_id = ?', whereArgs: [reportId]);
      // سپس خود گزارش اصلی را حذف می‌کنیم
      await txn.delete('daily_reports', where: 'id = ?', whereArgs: [reportId]);
    });
  }

  // این کد را به انتهای کلاس DatabaseHelper اضافه کنید
  // --- CRUD برای درآمدها (Incomes) ---
  Future<int> insertIncome(Income income) async {
    final db = await database;
    return await db.insert('incomes', income.toMap(), conflictAlgorithm: ConflictAlgorithm.replace); // ✅ اضافه شد
  }

  Future<int> updateIncome(Income income) async {
    final db = await database;
    return await db.update('incomes', income.toMap(), where: 'id = ?', whereArgs: [income.id]);
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Income>> getIncomesForCycle(int cycleId, {String? category}) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (category != null) {
      maps = await db.query('incomes', where: 'cycle_id = ? AND category = ?', whereArgs: [cycleId, category], orderBy: 'id ASC'); // ✅ مشابه برای incomes
    } else {
      maps = await db.query('incomes', where: 'cycle_id = ?', whereArgs: [cycleId], orderBy: 'id ASC'); // ✅
    }
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }
}