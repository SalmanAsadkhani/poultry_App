import 'package:sqflite/sqflite.dart';
import '../models/breeding_cycle.dart';
import '../models/daily_report.dart';
import '../models/feed_consumption.dart';
import '../models/expense.dart';
import '../models/income.dart';
import 'dart:io';
import 'package:flutter/scheduler.dart';
import 'package:path/path.dart';
import 'dart:typed_data';
import '../models/feed.dart';

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

    print("==========================================================");
    print("Database Path on Device: $path");
    print("==========================================================");

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // تغییرات schema اگر لازم باشه
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
        CREATE TABLE $tableCycles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT,
          chick_count INTEGER NOT NULL,
           isActive INTEGER NOT NULL DEFAULT true
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

    await db.execute('''
        CREATE TABLE feed_consumptions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          report_id INTEGER NOT NULL,
          feed_type TEXT NOT NULL,
          quantity REAL NOT NULL,
          bag_count INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (report_id) REFERENCES daily_reports (id) ON DELETE CASCADE
        )
      ''');

    await db.execute('''
        CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          cycle_id INTEGER NOT NULL,
          category TEXT NOT NULL,
          title TEXT NOT NULL,
          date TEXT NOT NULL,
          quantity INTEGER,
          unit_price REAL,
          description TEXT,
          bag_count INTEGER,
          weight REAL,
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
          weight REAL,
          unit_price REAL,
          description TEXT,
          FOREIGN KEY (cycle_id) REFERENCES breeding_cycles (id) ON DELETE CASCADE
        )
      ''');

    await db.execute('''
        CREATE TABLE feeds (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          expense_id INTEGER,
          name TEXT NOT NULL,
          quantity REAL NOT NULL,
          bag_count INTEGER NOT NULL,
          remaining_bags INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (expense_id) REFERENCES expenses (id) ON DELETE SET NULL
        )
      ''');
  }

  // ================== CRUD برای cycles ==================

  Future<int> insertCycle(BreedingCycle cycle) async {
    final db = await database;
    print('========================================================');
      print('دوره ذخیره شد: ${cycle.toMap()}');
    print('========================================================');

    return await db.insert(tableCycles, {
      'name': cycle.name,
      'start_date': cycle.startDate,
      'end_date': cycle.endDate,
      'chick_count': cycle.chickCount,
      'isActive': cycle.isActive, // اطمینان از استفاده از نام صحیح
    });
  }

  Future<List<BreedingCycle>> getAllCycles() async {
    final db = await instance.database;
    final maps = await db.query(tableCycles, orderBy: "id ASC");
    return List.generate(maps.length, (i) => BreedingCycle.fromMap(maps[i]));
  }

  Future<int> updateCycle(BreedingCycle cycle) async {
    final db = await instance.database;
    return await db.update(
      tableCycles,
      cycle.toMap(),
      where: "id = ?",
      whereArgs: [cycle.id],
    );
  }

  Future<int> deleteCycle(int id) async {
    
    final db = await instance.database;
    return await db.delete(tableCycles, where: "id = ?", whereArgs: [id]);
  }

  Future<bool> hasRelatedData(int cycleId) async {
    final db = await instance.database;
    final reportsResult = await db.query(
      'daily_reports',
      where: "cycle_id = ?",
      whereArgs: [cycleId],
      limit: 1,
    );
    if (reportsResult.isNotEmpty) return true;
    final expensesResult = await db.query(
      'expenses',
      where: "cycle_id = ?",
      whereArgs: [cycleId],
      limit: 1,
    );
    if (expensesResult.isNotEmpty) return true;
    return false;
  }

  // ================== گزارش روزانه ==================
  Future<void> insertDailyReport(
    DailyReport report,
    List<FeedConsumption> feeds,
  ) async {
    final db = await instance.database;

    // بررسی وضعیت دوره
    final cycle = await db.query(
      'breeding_cycles',
      where: 'id = ?',
      whereArgs: [report.cycleId],
    );
    if (cycle.isEmpty || cycle.first['isActive'] == 0) {
      throw Exception('نمی‌توانید برای دوره غیرفعال گزارش ثبت کنید.');
    }
    await db.transaction((txn) async {
      final reportId = await txn.insert('daily_reports', report.toMap());
      for (final feed in feeds) {
        final feedMap = Map<String, dynamic>.from(feed.toMap());
        feedMap['report_id'] = reportId;
        await txn.insert('feed_consumptions', feedMap);
      }
    });
    await _recalculateAndUpdateAllFeeds();
  }

  Future<void> updateDailyReport(
    DailyReport report,
    List<FeedConsumption> feeds,
  ) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.update(
        'daily_reports',
        report.toMap(),
        where: 'id = ?',
        whereArgs: [report.id],
      );
      await txn.delete(
        'feed_consumptions',
        where: 'report_id = ?',
        whereArgs: [report.id],
      );
      for (final feed in feeds) {
        final feedMap = Map<String, dynamic>.from(feed.toMap());
        feedMap['report_id'] = report.id;
        await txn.insert('feed_consumptions', feedMap);
      }
    });
    await _recalculateAndUpdateAllFeeds();
  }

  Future<void> deleteDailyReport(int reportId) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        'feed_consumptions',
        where: 'report_id = ?',
        whereArgs: [reportId],
      );
      await txn.delete('daily_reports', where: 'id = ?', whereArgs: [reportId]);
    });
    await _recalculateAndUpdateAllFeeds();
  }

  Future<List<DailyReport>> getAllReportsForCycle(int cycleId) async {
    final db = await instance.database;
    final reportMaps = await db.query(
      'daily_reports',
      where: 'cycle_id = ?',
      whereArgs: [cycleId],
      orderBy: 'report_date ASC',
    );

    if (reportMaps.isEmpty) return [];
    final List<DailyReport> reports = [];
    for (var reportMap in reportMaps) {
      final feedMaps = await db.query(
        'feed_consumptions',
        where: 'report_id = ?',
        whereArgs: [reportMap['id']],
      );
      final feeds = feedMaps
          .map((feed) => FeedConsumption.fromMap(feed))
          .toList();

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

  // ================== هزینه‌ها و درآمد ==================
  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    final expenseId = await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (expense.category == 'دان') {
      final feed = Feed(
        expenseId: expenseId,
        name: expense.title,
        quantity: expense.weight,
        bagCount: expense.bagCount,
      );
      await insertFeed(feed);
      await _recalculateAndUpdateAllFeeds();
    }
    return expenseId;
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;

    if (expense.category == 'دان') {
      await db.update(
        'feeds',
        {
          'name': expense.title,
          'quantity': expense.weight,
          'bag_count': expense.bagCount,
        },
        where: 'expense_id = ?',
        whereArgs: [expense.id],
      );
      await _recalculateAndUpdateAllFeeds();
    }

    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final expense = Expense.fromMap(maps.first);
      if (expense.category == 'دان') {
        await db.delete('feeds', where: 'expense_id = ?', whereArgs: [id]);
        await _recalculateAndUpdateAllFeeds();
      }
    }
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpensesForCycle(
    int cycleId, {
    String? category,
  }) async {
    final db = await instance.database;
    List<Map<String, dynamic>> maps;
    if (category != null) {
      maps = await db.query(
        'expenses',
        where: 'cycle_id = ? AND category = ?',
        whereArgs: [cycleId, category],
        orderBy: 'id ASC',
      );
    } else {
      maps = await db.query(
        'expenses',
        where: 'cycle_id = ?',
        whereArgs: [cycleId],
        orderBy: 'id ASC',
      );
    }
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }

  Future<int> insertIncome(Income income) async {
    final db = await database;
    return await db.insert(
      'incomes',
      income.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateIncome(Income income) async {
    final db = await database;
    return await db.update(
      'incomes',
      income.toMap(),
      where: 'id = ?',
      whereArgs: [income.id],
    );
  }

  Future<int> deleteIncome(int id) async {
    final db = await database;
    return await db.delete('incomes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Income>> getIncomesForCycle(
    int cycleId, {
    String? category,
  }) async {
    final db = await database;
    List<Map<String, dynamic>> maps;
    if (category != null) {
      maps = await db.query(
        'incomes',
        where: 'cycle_id = ? AND category = ?',
        whereArgs: [cycleId, category],
        orderBy: 'id ASC',
      );
    } else {
      maps = await db.query(
        'incomes',
        where: 'cycle_id = ?',
        whereArgs: [cycleId],
        orderBy: 'id ASC',
      );
    }
    return List.generate(maps.length, (i) => Income.fromMap(maps[i]));
  }

  // ================== پشتیبان‌گیری ==================
  Future<Uint8List> exportDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }

    final dbFolder = await getDatabasesPath();
    final dbPath = join(dbFolder, _databaseName);
    final dbFile = File(dbPath);

    // باز شدن دوباره دیتابیس بعد از بکاپ
    SchedulerBinding.instance.addPostFrameCallback((_) async => await database);

    return dbFile.readAsBytes();
  }

  Future<void> importDatabase(Uint8List backupBytes) async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
    final tempDir = Directory.systemTemp;
    final tempPath = join(
      tempDir.path,
      'temp_backup_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    // ذخیره بکاپ موقت
    await File(tempPath).writeAsBytes(backupBytes);
    final tempDb = await openDatabase(tempPath);
    try {
      // دریافت تمام دوره‌ها از بکاپ
      final List<Map<String, dynamic>> tempCycles = await tempDb.query(
        'breeding_cycles',
      );
      if (tempCycles.isEmpty) {
        throw Exception('هیچ دوره‌ای در فایل پشتیبان یافت نشد');
      }

      // باز کردن دیتابیس اصلی
      final mainDb = await database;

      // غیرفعال کردن foreign keys برای عملیات ایمن (هرچند cascade وجود دارد، اما برای insert/delete ایمن‌تر)
      await mainDb.execute('PRAGMA foreign_keys = OFF;');

      // پردازش هر دوره در بکاپ
      for (final tempCycle in tempCycles) {
        final String? cycleName =
            tempCycle['name']; // فیلد 'name' برای شناسایی دوره
        if (cycleName == null) {
          print('هشدار: دوره‌ای بدون نام در بکاپ یافت شد، نادیده گرفته می‌شود');
          continue;
        }

        // جستجوی دوره موجود با نام مشابه در دیتابیس اصلی
        final List<Map<String, dynamic>> existingCycles = await mainDb.query(
          'breeding_cycles',
          where: 'name = ?',
          whereArgs: [cycleName],
        );

        bool isReplace = existingCycles.isNotEmpty;
        int? existingCycleId;
        if (isReplace) {
          existingCycleId = existingCycles.first['id'] as int;

          // قبل از حذف cycle، feeds مربوط به expenses این cycle را حذف کنیم (چون SET NULL است)
          final existingExpenses = await mainDb.query(
            'expenses',
            where: 'cycle_id = ?',
            whereArgs: [existingCycleId],
          );
          for (final exp in existingExpenses) {
            await mainDb.delete(
              'feeds',
              where: 'expense_id = ?',
              whereArgs: [exp['id']],
            );
          }

          // حالا حذف cycle (cascade: expenses, incomes, daily_reports -> feed_consumptions)
          await mainDb.delete(
            'breeding_cycles',
            where: 'id = ?',
            whereArgs: [existingCycleId],
          );
        }

        // درج دوره جدید (بدون id برای auto-increment)
        final Map<String, dynamic> cycleInsert = Map<String, dynamic>.from(
          tempCycle,
        )..remove('id');
        await mainDb.insert('breeding_cycles', cycleInsert);
        final newCycleId = Sqflite.firstIntValue(
          await mainDb.rawQuery('SELECT last_insert_rowid()'),
        )!;

        // درج daily_reports با cycle_id جدید
        final List<Map<String, dynamic>> tempDailyReports = await tempDb.query(
          'daily_reports',
          where: 'cycle_id = ?',
          whereArgs: [tempCycle['id']],
        );
        for (final tempReport in tempDailyReports) {
          final Map<String, dynamic> reportInsert =
              Map<String, dynamic>.from(tempReport)
                ..['cycle_id'] = newCycleId
                ..remove('id');
          final newReportId = await mainDb.insert(
            'daily_reports',
            reportInsert,
          );

          // درج feed_consumptions با report_id جدید
          final List<Map<String, dynamic>> tempFeedConsumptions = await tempDb
              .query(
                'feed_consumptions',
                where: 'report_id = ?',
                whereArgs: [tempReport['id']],
              );
          for (final tempFeed in tempFeedConsumptions) {
            final Map<String, dynamic> feedInsert =
                Map<String, dynamic>.from(tempFeed)
                  ..['report_id'] = newReportId
                  ..remove('id');
            await mainDb.insert('feed_consumptions', feedInsert);
          }
        }

        // درج expenses با cycle_id جدید
        final List<Map<String, dynamic>> tempExpenses = await tempDb.query(
          'expenses',
          where: 'cycle_id = ?',
          whereArgs: [tempCycle['id']],
        );
        for (final tempExpense in tempExpenses) {
          final Map<String, dynamic> expenseInsert =
              Map<String, dynamic>.from(tempExpense)
                ..['cycle_id'] = newCycleId
                ..remove('id');
          final newExpenseId = await mainDb.insert('expenses', expenseInsert);

          // درج feeds با expense_id جدید (فقط اگر category == 'دان' باشد، اما برای کامل بودن، همه feeds را درج می‌کنیم)
          final List<Map<String, dynamic>> tempFeeds = await tempDb.query(
            'feeds',
            where: 'expense_id = ?',
            whereArgs: [tempExpense['id']],
          );
          for (final tempFeed in tempFeeds) {
            final Map<String, dynamic> feedInsert =
                Map<String, dynamic>.from(tempFeed)
                  ..['expense_id'] = newExpenseId
                  ..remove('id');
            await mainDb.insert('feeds', feedInsert);
          }
        }

        // درج incomes با cycle_id جدید
        final List<Map<String, dynamic>> tempIncomes = await tempDb.query(
          'incomes',
          where: 'cycle_id = ?',
          whereArgs: [tempCycle['id']],
        );
        for (final tempIncome in tempIncomes) {
          final Map<String, dynamic> incomeInsert =
              Map<String, dynamic>.from(tempIncome)
                ..['cycle_id'] = newCycleId
                ..remove('id');
          await mainDb.insert('incomes', incomeInsert);
        }
      }

      // فعال کردن مجدد foreign keys
      await mainDb.execute('PRAGMA foreign_keys = ON;');

      // باز محاسبه feeds اگر لازم (چون feeds جدید درج شده)
      await _recalculateAndUpdateAllFeeds();
    } catch (e) {
      print('خطا در importDatabase: $e');
      rethrow;
    } finally {
      await tempDb.close();
      await File(tempPath).delete();
    }

    // باز کردن مجدد دیتابیس
    SchedulerBinding.instance.addPostFrameCallback((_) async => await database);
  }

  // ================== انبار دان ==================
  Future<int> insertFeed(Feed feed) async {
    final db = await instance.database;
    final feedMap = Map<String, dynamic>.from(feed.toMap());
    feedMap['remaining_bags'] = feed.bagCount ?? 0;
    feedMap['created_at'] = DateTime.now().toIso8601String();
    return await db.insert('feeds', feedMap);
  }

  Future<List<Feed>> getFeeds() async {
    final db = await instance.database;
    final maps = await db.query('feeds', orderBy: 'created_at ASC');
    return List.generate(maps.length, (i) => Feed.fromMap(maps[i]));
  }


  Future<List<Feed>> getFeedsByCycleId(int cycleId) async {
    final db = await instance.database;
    final maps = await db.rawQuery('''
      SELECT f.* 
      FROM feeds f
      INNER JOIN expenses e ON f.expense_id = e.id
      WHERE e.cycle_id = ?
      ORDER BY f.created_at ASC
    ''', [cycleId]);
    return List.generate(maps.length, (i) => Feed.fromMap(maps[i]));
  }

  // ✅ متد جدید: خلاصه باقی‌مانده انبار برای دوره جاری
  Future<Map<String, int>> getRemainingFeedBagsByCycleId(int cycleId) async {
    final feeds = await getFeedsByCycleId(cycleId);
    final Map<String, int> summary = {};
    for (var feed in feeds) {
      summary[feed.name.trim()] = feed.remainingBags ?? 0;
    }
    return summary;
  }

  // ✅ متد جدید: فقط expenseهای یک category خاص در cycle مشخص
  Future<List<Expense>> getExpensesByCategoryAndCycle(
    String category, 
    int cycleId
  ) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'category = ? AND cycle_id = ?',
      whereArgs: [category, cycleId],
    );
    return List.generate(maps.length, (i) => Expense.fromMap(maps[i]));
  }


  // ================== باز محاسبه FIFO ==================
  Future<void> _recalculateAndUpdateAllFeeds() async {
  final db = await database;

  // تمام دوره‌ها
  final cycles = await db.query('breeding_cycles');

  for (var cycle in cycles) {
    final int cycleId = cycle['id'] as int;

    // گرفتن خرید دان‌های مربوط به همین دوره
    final feedPurchases = await db.rawQuery('''
      SELECT f.*, e.cycle_id 
      FROM feeds f
      INNER JOIN expenses e ON f.expense_id = e.id
      WHERE e.cycle_id = ?
      ORDER BY f.created_at ASC
    ''', [cycleId]);

    if (feedPurchases.isEmpty) continue;

    final feedsCopy = feedPurchases
        .map((f) => Map<String, dynamic>.from(f))
        .toList();

    // همه دان‌ها رو با مقدار اولیه تنظیم کن
    for (var feed in feedsCopy) {
      feed['remaining_bags'] = feed['bag_count'];
    }

    // گزارش‌های روزانه فقط همین دوره
    final dailyReports = await db.query(
      'daily_reports',
      where: 'cycle_id = ?',
      whereArgs: [cycleId],
      orderBy: 'report_date ASC',
    );

    for (var report in dailyReports) {
      final feedConsumptions = await db.query(
        'feed_consumptions',
        where: 'report_id = ?',
        whereArgs: [report['id']],
      );

      for (var consumption in feedConsumptions) {
        int neededBags = consumption['bag_count'] as int;

        for (var feed in feedsCopy) {
          if (feed['name'] == consumption['feed_type'] && neededBags > 0) {
            final available = feed['remaining_bags'] as int;
            if (available >= neededBags) {
              feed['remaining_bags'] = available - neededBags;
              neededBags = 0;
            } else {
              feed['remaining_bags'] = 0;
              neededBags -= available;
            }
          }
        }
      }
    }

    // به‌روزرسانی موجودی دان‌های همین دوره در دیتابیس
    for (var feed in feedsCopy) {
      await db.update(
        'feeds',
        {'remaining_bags': feed['remaining_bags']},
        where: 'id = ?',
        whereArgs: [feed['id']],
      );
    }
  }
}


  // ================== همه گزارش‌ها ==================
  Future<List<DailyReport>> getAllReportsForAllCycles() async {
    final db = await instance.database;
    final reportMaps = await db.query(
      'daily_reports',
      orderBy: 'report_date ASC',
    );
    if (reportMaps.isEmpty) return [];

    final List<DailyReport> reports = [];
    for (var reportMap in reportMaps) {
      final feedMaps = await db.query(
        'feed_consumptions',
        where: 'report_id = ?',
        whereArgs: [reportMap['id']],
      );
      final feeds = feedMaps
          .map((feed) => FeedConsumption.fromMap(feed))
          .toList();

      final baseReport = DailyReport.fromMap(reportMap);
      reports.add(
        DailyReport(
          id: baseReport.id,
          cycleId: baseReport.cycleId,
          reportDate: baseReport.reportDate,
          mortality: baseReport.mortality,
          medicine: baseReport.medicine,
          notes: baseReport.notes,
          feedConsumed: feeds,
        ),
      );
    }
    return reports;
  }

Future<void> endCycle(int cycleId, DateTime endDate) async {
  final db = await database;
  await db.update(
    tableCycles,
    {
      'isActive': false,
      'end_date': endDate.toIso8601String().substring(0, 10),
    },
    where: 'id = ?',
    whereArgs: [cycleId],
  );
  print('دوره ذخیره شد: $tableCycles');
}



  // گرفتن اطلاعات یک دوره
Future<BreedingCycle?> getCycleById(int cycleId) async {
  final db = await instance.database;
  final result = await db.query(
    'breeding_cycles',
    where: 'id = ?',
    whereArgs: [cycleId],
    limit: 1,
  );
  if (result.isNotEmpty) {
    return BreedingCycle.fromMap(result.first);
  }
  return null;
}

// محاسبه مجموع تلفات یک دوره
Future<int> getTotalMortality(int cycleId) async {
  final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(mortality) as total FROM daily_reports WHERE cycle_id = ?',
    [cycleId],
  );
  final total = result.first['total'] as int?;
  return total ?? 0;
}

// محاسبه مجموع فروش یک دوره
Future<int> getTotalSold(int cycleId) async {
  final db = await instance.database;
  final result = await db.rawQuery(
    'SELECT SUM(quantity) as total FROM incomes WHERE cycle_id = ?',
    [cycleId],
  );
  final total = result.first['total'] as int?;
  return total ?? 0;
}


Future<int> getRemainingFlock(int cycleId) async {
  final cycle = await getCycleById(cycleId);
  if (cycle == null) return 0;

  final totalMortality = await getTotalMortality(cycleId);
  final totalSold = await getTotalSold(cycleId);

  final remaining = cycle.chickCount - totalMortality - totalSold;
  return remaining < 0 ? 0 : remaining;
}


Future<Map<String, int>> getRemainingFeedBags() async {
  final feeds = await getFeeds(); // تمام دان‌های موجود در انبار
  final Map<String, int> summary = {};
  for (var feed in feeds) {
    summary[feed.name.trim()] = feed.remainingBags ?? 0;
  }
  return summary;
}

Future<Map<String, double>> getRemainingFeedWeight() async {
  final feeds = await getFeeds();
  final Map<String, double> summary = {};
  for (var feed in feeds) {
    final remaining = feed.remainingBags ?? 0;
    final quantityPerBag = (feed.quantity ?? 0) / (feed.bagCount ?? 1);
    summary[feed.name.trim()] = remaining * quantityPerBag;
  }
  return summary;
}


// در helpers/database_helper.dart

Future<List<DailyReport>> getReportsForCycle(int cycleId) async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query(
    'daily_reports',
    where: 'cycleId = ?',
    whereArgs: [cycleId],
    orderBy: 'reportDate ASC',
  );
  return maps.map((map) => DailyReport.fromMap(map)).toList();
}

}
