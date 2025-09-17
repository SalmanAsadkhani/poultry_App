// lib/screens/cycle_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart'; // <<-- برای کار با تاریخ شمسی
import '../../helpers/database_helper.dart';
import '../../models/breeding_cycle.dart';
import '../../models/daily_report.dart';
import '../../models/expense.dart';
import '../../models/income.dart';
import '../../models/feed.dart';
import '../../services/feed_consumption_analytics.dart';
import '../reports/add_daily_report_screen.dart';
import '../expenses/expense_category_screen.dart';
import '../incomes/income_category_screen.dart';
import '../reports/reports_screen.dart';
import '../tabs/summary_tab.dart';

class CycleDashboardScreen extends StatefulWidget {
  final BreedingCycle cycle;
  const CycleDashboardScreen({super.key, required this.cycle});

  @override
  State<CycleDashboardScreen> createState() => _CycleDashboardScreenState();
}

class _CycleDashboardScreenState extends State<CycleDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<DailyReport> _reports = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  int _chickAge = 0;
  int _totalMortality = 0;
  int _totalChickensSold = 0;
  double _totalWeightSold = 0.0;
  int _remainingChicks = 0;
  double _totalFeedWeight = 0;
  Map<String, double> _feedWeightSummary = {};
  Map<String, int> _feedBagCountSummary = {};
  double? _fcr;
  double? _productionIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// [اصلاح شده] سن گله را با مدیریت تاریخ شمسی و میلادی محاسبه می‌کند
// در فایل lib/screens/cycle_dashboard_screen.dart و داخل کلاس _CycleDashboardScreenState

/// [نسخه نهایی و صحیح] سن گله را با مدیریت تاریخ شمسی و میلادی محاسبه می‌کند
int _calculateChickAge(BreedingCycle cycle) {
  if (cycle.startDate.isEmpty) return 0;

  try {
    // ۱. [اصلاح شده] تاریخ شروع شمسی را به صورت دستی و با اطمینان پارس می‌کنیم
    Jalali? startDateJalali;
    // ابتدا هر دو فرمت YYYY/MM/DD و YYYY-MM-DD را پشتیبانی می‌کنیم
    final dateParts = cycle.startDate.replaceAll('/', '-').split('-');
    
    if (dateParts.length == 3) {
      final year = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final day = int.tryParse(dateParts[2]);

      // اگر تمام بخش‌ها به درستی به عدد تبدیل شدند، آبجکت Jalali را می‌سازیم
      if (year != null && month != null && day != null) {
        startDateJalali = Jalali(year, month, day);
      }
    }

    // اگر تبدیل تاریخ شمسی ناموفق بود، صفر برمی‌گردانیم
    if (startDateJalali == null) {
      debugPrint('فرمت تاریخ شروع شمسی نامعتبر است: ${cycle.startDate}');
      return 0;
    }
    
    final DateTime startDate = startDateJalali.toDateTime();

    // ۲. تاریخ پایان محاسبه را مشخص می‌کنیم
    DateTime endDate;
    if (cycle.isActive) {
      // اگر دوره فعال است، تا امروز محاسبه کن
      endDate = DateTime.now();
    } else {
      // اگر دوره پایان یافته، تاریخ پایان میلادی را پارس کن
      endDate = (cycle.endDate != null && cycle.endDate!.isNotEmpty)
          ? DateTime.tryParse(cycle.endDate!) ?? DateTime.now()
          : DateTime.now();
    }
    
    // ۳. اختلاف روزها را محاسبه و ۱ روز اضافه می‌کنیم
    final ageInDays = endDate.difference(startDate).inDays;
    return ageInDays < 0 ? 0 : ageInDays + 1;
    
  } catch (e) {
    debugPrint('خطا در محاسبه سن گله: $e');
    return 0;
  }
}


  /// [بازنویسی کامل] متد اصلی برای لود و محاسبه تمام اطلاعات به روش صحیح
  Future<void> _loadAllData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // ۱. گرفتن تمام دیتاهای لازم از دیتابیس (شامل انبار دان)
      final results = await Future.wait([
        DatabaseHelper.instance.getAllReportsForCycle(widget.cycle.id!),
        DatabaseHelper.instance.getExpensesForCycle(widget.cycle.id!),
        DatabaseHelper.instance.getIncomesForCycle(widget.cycle.id!),
        DatabaseHelper.instance.getFeeds(), // <<-- این خط بسیار مهم است
      ]);

      final reports = results[0] as List<DailyReport>;
      final expenses = results[1] as List<Expense>;
      final incomes = results[2] as List<Income>;
      final allFeeds = results[3] as List<Feed>;

      // ۲. اجرای موتور محاسباتی قدرتمند انبار
      final analytics = FeedConsumptionAnalytics(feeds: allFeeds, dailyReports: reports);
      final analyticsResult = analytics.getAnalytics();

      // ۳. محاسبه مقادیر خلاصه از منابع صحیح
      final totalMortality = reports.fold<int>(0, (sum, r) => sum + r.mortality);
      final totalIncome = incomes.fold<double>(0, (sum, i) => sum + (i.totalPrice ?? 0));
      final totalExpense = expenses.fold<double>(0, (sum, e) => sum + (e.totalPrice ?? 0));
      
      final soldChickensIncomes = incomes.where((i) => i.category == 'فروش مرغ').toList();
      final totalChickensSold = soldChickensIncomes.fold<int>(0, (sum, i) => sum + (i.quantity ?? 0));
      final totalSoldWeight = soldChickensIncomes.fold<double>(0, (sum, i) => sum + (i.weight ?? 0));
      
      final remainingChicks = widget.cycle.chickCount - totalMortality - totalChickensSold;

      // ۴. گرفتن خلاصه دان از نتیجه صحیح آنالیز (نه محاسبه دستی و اشتباه)
     // =========================

// =========================
// جمع مصرف دان
// =========================
final allConsumedFeeds = reports.expand((r) => r.feedConsumed).toList();

// مجموع وزن کل
final totalFeedWeight = allConsumedFeeds.fold(0.0, (s, f) => s + f.quantity);

// خلاصه بر اساس نوع دان
final feedWeightSummary = <String, double>{};
final feedBagCountSummary = <String, int>{};
for (var feed in allConsumedFeeds) {
  feedWeightSummary.update(feed.feedType, (v) => v + feed.quantity, ifAbsent: () => feed.quantity);
  feedBagCountSummary.update(feed.feedType, (v) => v + feed.bagCount, ifAbsent: () => feed.bagCount);
}


      
      double? fcr;
      double? productionIndex;
      if (!widget.cycle.isActive && totalSoldWeight > 0 && totalChickensSold > 0) {
        // FCR = وزن کل دان مصرفی / وزن کل مرغ فروخته شده
        fcr = totalFeedWeight / totalSoldWeight;
        
        final chickAgeAtSale = _calculateChickAge(widget.cycle); // سن در زمان پایان دوره
        
          final liveability = (widget.cycle.chickCount - totalMortality) / widget.cycle.chickCount * 100;
          final averageWeight = totalSoldWeight / totalChickensSold;
          // فرمول استاندارد شاخص تولید اروپایی (EPEF)
          productionIndex = (liveability * averageWeight) / (fcr * chickAgeAtSale) * 100;
        
      }

      // ۶. آپدیت نهایی وضعیت (State) با تمام مقادیر صحیح
      if (mounted) {
        setState(() {
          _reports = reports;
          _chickAge = _calculateChickAge(widget.cycle);
          _totalMortality = totalMortality;
          _totalIncome = totalIncome;
          _totalExpense = totalExpense;
          _totalChickensSold = totalChickensSold;
          _totalWeightSold = totalSoldWeight;
          _remainingChicks = remainingChicks;
          _totalFeedWeight = totalFeedWeight;
          _feedWeightSummary = feedWeightSummary;
          _feedBagCountSummary = feedBagCountSummary;
          _fcr = fcr;
          _productionIndex = productionIndex;
          _isLoading = false;

        });
      }
    } catch (e, s) {
      debugPrint("خطا در لود کردن اطلاعات داشبورد: $e");
      debugPrint(s.toString());
      if (mounted) setState(() => _isLoading = false);
    }
  }


  Future<void> _navigateAndAddReport() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDailyReportScreen(cycleId: widget.cycle.id!),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('گزارش با موفقیت ثبت شد.'),
          backgroundColor: Color.fromARGB(255, 5, 141, 96),
        ),
      );
      _loadAllData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... متد build شما بدون تغییر باقی می‌ماند ...
    // ... Your build method remains unchanged ...
    final primaryColor = const Color.fromARGB(255, 83, 138, 155);
    final cycleName = 'دوره: ';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(cycleName + widget.cycle.name),
        foregroundColor: const Color.fromARGB(255, 14, 39, 53),
        elevation: 1,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, const Color.fromARGB(255, 9, 136, 87)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color.fromARGB(255, 141, 52, 52),
          labelColor: const Color.fromARGB(255, 168, 61, 61),
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: const [
            Tab(text: 'خلاصه', icon: Icon(Icons.dashboard)),
            Tab(text: 'گزارشات', icon: Icon(Icons.article)),
            Tab(text: 'هزینه‌ها', icon: Icon(Icons.payment)),
            Tab(text: 'درآمدها', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: Color.fromARGB(255, 36, 6, 90)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                SummaryTab(
                  isLoading: _isLoading,
                  cycle: widget.cycle,
                  chickAge: _chickAge,
                  remainingChicks: _remainingChicks,
                  totalMortality: _totalMortality,
                  totalChickensSold: _totalChickensSold,
                  totalWeightSold: _totalWeightSold, 
                  totalFeedWeight: _totalFeedWeight,
                  feedBagCountSummary: _feedBagCountSummary,
                  feedWeightSummary: _feedWeightSummary,
                  totalIncome: _totalIncome,
                  totalExpense: _totalExpense,
                  fcr: _fcr,
                  productionIndex: _productionIndex,
                  onRefresh: _loadAllData,
                ),
                ReportsScreen(
                  cycle: widget.cycle,
                  reports: _reports,
                  onDataChanged: _loadAllData,
                  

                ),
                ExpenseCategoryScreen(cycleId: widget.cycle.id!),
                IncomeCategoryScreen(cycleId: widget.cycle.id!,remainingChicks: _remainingChicks,),
              ],
            ),
    );
  }
}