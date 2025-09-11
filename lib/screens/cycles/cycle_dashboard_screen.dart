// lib/screens/cycle_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../helpers/database_helper.dart';
import '../../models/breeding_cycle.dart';
import '../../models/daily_report.dart';
import '../../models/expense.dart';
import '../../models/income.dart';
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

class _CycleDashboardScreenState extends State<CycleDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  List<DailyReport> _reports = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  int _chickAge = 0;
  int _totalMortality = 0;
  int _totalChickensSold = 0;
  int _remainingChicks = 0;
  double _totalFeedWeight = 0;
  Map<String, double> _feedWeightSummary = {};
  Map<String, int> _feedBagCountSummary = {};
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted && _tabController.index != _currentTabIndex) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DatabaseHelper.instance.getAllReportsForCycle(widget.cycle.id!),
        DatabaseHelper.instance.getExpensesForCycle(widget.cycle.id!),
        DatabaseHelper.instance.getIncomesForCycle(widget.cycle.id!),
      ]);
      _reports = results[0] as List<DailyReport>;
      final allExpenses = results[1] as List<Expense>;
      final allIncomes = results[2] as List<Income>;
      _totalExpense = allExpenses.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      _totalIncome = allIncomes.fold(0.0, (sum, item) => sum + item.totalPrice);
      _totalChickensSold = allIncomes
          .where((i) => i.category == 'فروش مرغ')
          .fold(0, (sum, i) => sum + (i.quantity ?? 0));
      final dateParts = widget.cycle.startDate.replaceAll('/', '-').split('-');
      final startDate = Jalali(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );
      _chickAge =
          Jalali.now().toDateTime().difference(startDate.toDateTime()).inDays +
          1;
      _totalMortality = _reports.fold(0, (sum, r) => sum + r.mortality);
      _remainingChicks =
          widget.cycle.chickCount - _totalMortality - _totalChickensSold;

      final allFeeds = _reports.expand((r) => r.feedConsumed).toList();
      _totalFeedWeight = allFeeds.fold(0.0, (s, f) => s + f.quantity);
      _feedWeightSummary = {};
      _feedBagCountSummary = {};
      for (var feed in allFeeds) {
        _feedWeightSummary.update(
          feed.feedType,
          (v) => v + feed.quantity,
          ifAbsent: () => feed.quantity,
        );
        _feedBagCountSummary.update(
          feed.feedType,
          (v) => v + feed.bagCount,
          ifAbsent: () => feed.bagCount,
        );
      }
    } catch (e) {
      debugPrint("Error loading all data: $e");
    } finally {
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
    if (result == true) {
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
    final primaryColor = Color.fromARGB(255, 5, 104, 134);
    const reportsTabIndex = 1;
    final cycleName = 'دوره: ';

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text(cycleName + widget.cycle.name),
        foregroundColor: Color.fromARGB(255, 14, 39, 53),
        elevation: 1,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Colors.teal.shade300],
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
          unselectedLabelColor: const Color.fromARGB(
            255,
            255,
            255,
            255,
          ).withOpacity(0.7),
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
                color: Color.fromARGB(255, 36, 6, 90),
              ),
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
                  totalFeedWeight: _totalFeedWeight,
                  feedBagCountSummary: _feedBagCountSummary,
                  feedWeightSummary: _feedWeightSummary,
                  totalIncome: _totalIncome,
                  totalExpense: _totalExpense,
                  onRefresh: _loadAllData,
                ),
                ReportsScreen(
                  cycle: widget.cycle,
                  reports: _reports,
                  onDataChanged: _loadAllData,
                ),
                ExpenseCategoryScreen(cycleId: widget.cycle.id!),
                IncomeCategoryScreen(cycleId: widget.cycle.id!),
              ],
            ),
      floatingActionButton: _currentTabIndex == reportsTabIndex
          ? FloatingActionButton.extended(
              onPressed: _navigateAndAddReport,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "ثبت گزارش روزانه",
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            )
          : null,
    );
  }
}
