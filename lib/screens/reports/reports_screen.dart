// lib/screens/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:collection/collection.dart';
import '../../helpers/database_helper.dart';
import '../../models/breeding_cycle.dart';
import '../../models/daily_report.dart';
import 'add_daily_report_screen.dart';
import 'report_detail_screen.dart';

// --- توابع کمکی برای مدیریت عملیات ---

Future<void> _onViewDetails(BuildContext context, DailyReport report) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ReportDetailScreen(report: report)),
  );
}

Future<void> _onEditReport(BuildContext context, DailyReport? report, int cycleId, VoidCallback onDataChanged) async {
  final result = await Navigator.push<bool?>(
    context,
    MaterialPageRoute(builder: (context) => AddDailyReportScreen(cycleId: cycleId, report: report)),
  );
  if (result == true) {
    onDataChanged();
  }
}

Future<void> _onDeleteReport(BuildContext context, DailyReport report, VoidCallback onDataChanged) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('حذف گزارش'),
      content: Text('آیا از حذف گزارش ${report.formattedReportDate} مطمئن هستید؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
      ],
    ),
  );

  if (confirm == true) {
    await DatabaseHelper.instance.deleteDailyReport(report.id!);
    onDataChanged();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('گزارش حذف شد.'), backgroundColor: Colors.green),
      );
    }
  }
}

// --- ویجت اصلی صفحه گزارشات ---

class ReportsScreen extends StatefulWidget {
  final BreedingCycle cycle;
  final List<DailyReport> reports;
  final Future<void> Function() onDataChanged;

  const ReportsScreen({
    super.key,
    required this.cycle,
    required this.reports,
    required this.onDataChanged,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? _selectedWeek;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _selectedWeek = null; // همه رو نشون بده
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  int _calculateAgeInDays(String cycleStartDate, String reportDate) {
    try {
      // فرض: cycleStartDate در فرمت '1402/01/01' (جلالی)
      final startParts = cycleStartDate.replaceAll('/', '-').split('-');
      final startJalali = Jalali(int.parse(startParts[0]), int.parse(startParts[1]), int.parse(startParts[2]));
      final startGregorian = startJalali.toDateTime();

      // reportDate در فرمت ISO '2023-01-15'
      final reportGregorian = DateTime.parse(reportDate);
      return reportGregorian.difference(startGregorian).inDays + 1;
    } catch (e) {
      return 0;
    }
  }

  List<int> _getWeeks() {
    final groupedReports = groupBy(widget.reports, (DailyReport report) {
      final days = _calculateAgeInDays(widget.cycle.startDate, report.reportDate);
      return (days ~/ 7) + 1;
    });
    return groupedReports.keys.toList()..sort((a, b) => b.compareTo(a));
  }

  Widget _buildSummaryCard() {
  if (widget.reports.isEmpty) return const SizedBox.shrink();

  final totalMortality = widget.reports.fold(0, (sum, r) => sum + r.mortality);
  final totalFeed = widget.reports.fold(0.0, (sum, r) => sum + r.feedConsumed.fold(0.0, (s, f) => s + f.quantity));

  // محاسبه سن گله بر اساس جدیدترین گزارش (آخرین reportDate)
  int flockAge = 0;
  if (widget.reports.isNotEmpty) {
    final latestReport = widget.reports.reduce((a, b) => DateTime.parse(a.reportDate).isAfter(DateTime.parse(b.reportDate)) ? a : b);
    flockAge = _calculateAgeInDays(widget.cycle.startDate, latestReport.reportDate);
  }

  return FadeTransition(
    opacity: _fadeAnimation,
    child: Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'خلاصه کل دوره',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal.shade800),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(Icons.airline_seat_flat_angled, 'تلفات کل', '$totalMortality قطعه', Colors.red.shade400),
                _buildStatChip(Icons.grain, 'دان کل', '${totalFeed.toStringAsFixed(1)} کیلوگرم', Colors.green.shade400),
                _buildStatChip(Icons.calendar_today, 'سن گله ', '$flockAge روزه', const Color.fromARGB(192, 27, 35, 73)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reports.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Scaffold(
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('هنوز گزارشی ثبت نشده است.', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    final weeks = _getWeeks();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'گزارش‌ها',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        toolbarHeight: 48,
        backgroundColor: Colors.teal.shade700,
        elevation: 2,
        flexibleSpace: Container(
          padding: const EdgeInsets.only(top: 12.0, left: 8.0, right: 8.0), // فاصله از بالا برای فضای خالی
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color.fromARGB(189, 84, 218, 128), Colors.teal.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'all') {
                setState(() => _selectedWeek = null);
              } else {
                final weekNum = int.tryParse(value.replaceFirst('week_', ''));
                if (weekNum != null) {
                  setState(() => _selectedWeek = weekNum);
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Row(children: [Icon(Icons.list), SizedBox(width: 8), Text('همه هفته‌ها')])),
              ...weeks.map((w) => PopupMenuItem(value: 'week_$w', child: Row(children: [Icon(Icons.calendar_today), SizedBox(width: 8), Text('هفته $w')]))),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: widget.onDataChanged,
        color: Colors.teal,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildSummaryCard()),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (_selectedWeek != null && _selectedWeek != weeks[index]) return const SizedBox.shrink();
                    final week = weeks[index];
                    final reportsInWeek = groupBy(widget.reports, (DailyReport r) {
                      final days = _calculateAgeInDays(widget.cycle.startDate, r.reportDate);
                      return (days ~/ 7) + 1;
                    })[week] ?? [];
                    final ageInDays = reportsInWeek.isNotEmpty ? _calculateAgeInDays(widget.cycle.startDate, reportsInWeek.first.reportDate) : 0;

                    return FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(0.0, 1.0, curve: Curves.easeInOut),
                        ),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 4,
                        shadowColor: const Color.fromARGB(110, 0, 150, 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$week',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade700,
                              ),
                            ),
                          ),
                          title: Text(
                            "گزارش‌های هفته $week",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          subtitle: Text(
                            "سن گله: $ageInDays روزه",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          iconColor: Colors.teal,
                          collapsedIconColor: Colors.teal,
                          childrenPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          children: reportsInWeek.map((report) => _buildReportListItem(context, report)).toList(),
                        ),
                      ),
                    );
                  },
                  childCount: weeks.length,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onEditReport(context, null, widget.cycle.id!, widget.onDataChanged),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'افزودن گزارش جدید',
      ),
    );
  }

  // ✅✅✅ بازطراحی فشرده‌تر آیتم هر گزارش ✅✅✅
  Widget _buildReportListItem(BuildContext context, DailyReport report) {
    final dailyTotalFeed = report.feedConsumed.fold(0.0, (sum, f) => sum + f.quantity);
    final ageOnReportDay = _calculateAgeInDays(widget.cycle.startDate, report.reportDate);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () => _onViewDetails(context, report),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // سن جوجه فشرده
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ageOnReportDay > 0 ? '$ageOnReportDay' : '?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.teal.shade700),
              ),
            ),
            const SizedBox(width: 12),
            // اطلاعات در یک خط فشرده
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(report.formattedReportDate, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.airline_seat_flat_angled, size: 14, color: Colors.red.shade500),
                      const SizedBox(width: 4),
                      Text("تلفات: ${report.mortality}", style: TextStyle(fontSize: 12, color: Colors.red.shade600)),
                      const SizedBox(width: 12),
                      Icon(Icons.grain, size: 14, color: Colors.green.shade500),
                      const SizedBox(width: 4),
                      Text("${dailyTotalFeed.toStringAsFixed(1)}kg", style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
                    ],
                  ),
                ],
              ),
            ),
            // عملیات فشرده
            Row(
              children: [
                IconButton(
                  onPressed: () => _onEditReport(context, report, widget.cycle.id!, widget.onDataChanged),
                  icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'ویرایش',
                ),
                IconButton(
                  onPressed: () => _onDeleteReport(context, report, widget.onDataChanged),
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}