// lib/screens/reports_screen.dart

import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:collection/collection.dart';

import '../../helpers/database_helper.dart';
import '../../models/breeding_cycle.dart';
import '../../models/daily_report.dart';
import 'add_daily_report_screen.dart';
import 'report_detail_screen.dart';

// --- توابع کمکی ---
Future<void> _onViewDetails(BuildContext context, DailyReport report) async {
  await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ReportDetailScreen(report: report)),
  );
}

Future<void> _onEditReport(
  BuildContext context,
  DailyReport? report,
  int cycleId,
  Future<void> Function() onDataChanged, {
  required bool hasReportToday,
}) async {
  if (report == null && hasReportToday) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('گزارش امروز قبلاً ثبت شده است.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    return;
  }

  final result = await Navigator.push<bool?>(
    context,
    MaterialPageRoute(builder: (context) => AddDailyReportScreen(cycleId: cycleId, report: report)),
  );
  if (result == true) {
    await onDataChanged();
  }
}

Future<bool?> _onDeleteReport(
    BuildContext context, DailyReport report, Future<void> Function() onDataChanged) async {
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
    try {
      await DatabaseHelper.instance.deleteDailyReport(report.id!);
      await onDataChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('گزارش حذف شد.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف گزارش: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }
  return confirm;
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
    )..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _selectedWeek = null;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _hasReportForToday() {
    final today = DateTime.now();
    return widget.reports.any((report) {
      final reportDate = DateTime.parse(report.reportDate);
      return reportDate.year == today.year &&
          reportDate.month == today.month &&
          reportDate.day == today.day;
    });
  }

  int _calculateAgeInDays(String cycleStartDate, String reportDate) {
    try {
      final startParts = cycleStartDate.replaceAll('/', '-').split('-');
      final startJalali = Jalali(int.parse(startParts[0]), int.parse(startParts[1]), int.parse(startParts[2]));
      final startGregorian = startJalali.toDateTime();
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

  double _calculateWeeklyFeed(List<DailyReport> reports) {
    return reports.fold(0.0, (sum, r) => sum + r.feedConsumed.fold(0.0, (s, f) => s + f.quantity));
  }

  int _calculateWeeklyMortality(List<DailyReport> reports) {
    return reports.fold(0, (sum, r) => sum + r.mortality);
  }

  Widget _buildSummaryCard() {
    if (widget.reports.isEmpty) return const SizedBox.shrink();

    final totalMortality = widget.reports.fold(0, (sum, r) => sum + r.mortality);
    final totalFeed = widget.reports.fold(0.0, (sum, r) => sum + r.feedConsumed.fold(0.0, (s, f) => s + f.quantity));
    int flockAge = widget.reports.isNotEmpty
        ? _calculateAgeInDays(
            widget.cycle.startDate,
            widget.reports
                .reduce((a, b) =>
                    DateTime.parse(a.reportDate).isAfter(DateTime.parse(b.reportDate)) ? a : b)
                .reportDate)
        : 0;

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
              const Text(
                'خلاصه کل دوره',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _buildStatChip(Icons.airline_seat_flat_angled, 'تلفات کل', '$totalMortality قطعه',
                      Colors.red.shade400),
                  _buildStatChip(Icons.grain, 'دان کل', '${totalFeed.toStringAsFixed(1)} کیلوگرم',
                      Colors.green.shade400),
                  _buildStatChip(Icons.calendar_today, 'سن گله', '$flockAge روزه', Colors.blue.shade400),
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

  Widget _buildWeeklyReportSummary(List<DailyReport> reports) {
    final weeklyMortality = _calculateWeeklyMortality(reports);
    final weeklyFeed = _calculateWeeklyFeed(reports);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade100, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: Colors.teal, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${reports.length} گزارش در هفته',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700),
            ),
          ),
          _buildStatChip(Icons.airline_seat_flat_angled, 'تلفات', '$weeklyMortality قطعه', Colors.red.shade400),
          const SizedBox(width: 8),
          _buildStatChip(Icons.grain, 'دان', '${weeklyFeed.toStringAsFixed(1)} کیلوگرم', Colors.green.shade400),
        ],
      ),
    );
  }

  Widget _buildReportListItem(BuildContext context, DailyReport report, double dailyTotalFeed, int ageOnReportDay) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        child: InkWell(
          onTap: () => _onViewDetails(context, report),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$ageOnReportDay',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.formattedReportDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14, color: Color.fromARGB(255, 8, 128, 114)),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.airline_seat_flat_angled, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text("تلفات: ${report.mortality}", style: const TextStyle(fontSize: 12, color: Colors.red)),
                          const SizedBox(width: 16),
                          const Icon(Icons.grain, size: 14, color: Colors.green),
                          const SizedBox(width: 4),
                          Text("${dailyTotalFeed.toStringAsFixed(1)}kg",
                              style: const TextStyle(fontSize: 12, color: Colors.green)),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (widget.cycle.isActive)
                      IconButton(
                        onPressed: () => _onEditReport(
                          context,
                          report,
                          widget.cycle.id!,
                          widget.onDataChanged,
                          hasReportToday: _hasReportForToday(),
                        ),
                        icon: const Icon(Icons.edit, size: 18, color: Colors.orange),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'ویرایش',
                      ),
                    if (widget.cycle.isActive)
                      IconButton(
                        onPressed: () => _onDeleteReport(context, report, widget.onDataChanged),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'حذف',
                      ),
                    if (!widget.cycle.isActive)
                      const Text(
                        'دوره پایان یافته',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasReportToday = _hasReportForToday();
    final weeks = _getWeeks();

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
                Text(
                  'هنوز گزارشی ثبت نشده است.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomButton(hasReportToday),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش‌ها', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        toolbarHeight: 48,
        backgroundColor: Colors.teal.shade700,
        elevation: 2,
        flexibleSpace: Container(
          padding: const EdgeInsets.only(top: 12.0, left: 8.0, right: 8.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(189, 84, 218, 128), Color.fromARGB(255, 0, 128, 128)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          DropdownButton<int?>(
            value: _selectedWeek,
            hint: const Text('همه هفته‌ها', style: TextStyle(color: Colors.white)),
            icon: const Icon(Icons.filter_list, color: Colors.white),
            dropdownColor: Colors.teal.shade700,
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox(),
            items: [
              const DropdownMenuItem(value: null, child: Text('همه هفته‌ها')),
              ...weeks.map((w) => DropdownMenuItem(value: w, child: Text('هفته $w'))),
            ],
            onChanged: (value) => setState(() => _selectedWeek = value),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: widget.onDataChanged,
        color: Colors.teal,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Builder(
            builder: (context) {
              final filteredReports = _selectedWeek == null
                  ? widget.reports
                  : groupBy(widget.reports, (DailyReport r) {
                      final days = _calculateAgeInDays(widget.cycle.startDate, r.reportDate);
                      return (days ~/ 7) + 1;
                    })[_selectedWeek] ?? [];

              if (filteredReports.isEmpty) {
                return const Center(child: Text('هیچ گزارشی در این هفته یافت نشد.'));
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: (_selectedWeek != null ? 1 : 0) + filteredReports.length,
                itemBuilder: (context, index) {
                  if (_selectedWeek != null && index == 0) {
                    return _buildWeeklyReportSummary(filteredReports);
                  }

                  final report = filteredReports[index - (_selectedWeek != null ? 1 : 0)];
                  final dailyTotalFeed = report.feedConsumed.fold(0.0, (sum, f) => sum + f.quantity);
                  final ageOnReportDay = _calculateAgeInDays(widget.cycle.startDate, report.reportDate);

                  return _buildReportListItem(context, report, dailyTotalFeed, ageOnReportDay);
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(hasReportToday),
    );
  }

  Widget _buildBottomButton(bool hasReportToday) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: (widget.cycle.isActive && !hasReportToday)
            ? () => _onEditReport(
                  context,
                  null,
                  widget.cycle.id!,
                  widget.onDataChanged,
                  hasReportToday: hasReportToday,
                )
            : null,
        icon: const Icon(Icons.add, size: 24),
        label: Text(
          widget.cycle.isActive
              ? (hasReportToday ? 'گزارش امروز ثبت شده است' : 'ثبت گزارش روزانه')
              : 'دوره پایان یافته است',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: (widget.cycle.isActive && !hasReportToday)
              ? Colors.teal.shade600
              : Colors.grey.shade400,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}
