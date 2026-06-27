// lib/screens/cycles/cycle_aggregate_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/breeding_cycle.dart';
import '../../models/daily_report.dart';
import '../../models/income.dart';
import '../../models/expense.dart';
import '../../helpers/database_helper.dart';
import 'hall_selection_screen.dart';

class CycleAggregateDashboardScreen extends StatefulWidget {
  final BreedingCycle parent;
  final List<BreedingCycle> halls;

  const CycleAggregateDashboardScreen({
    super.key,
    required this.parent,
    required this.halls,
  });

  @override
  State<CycleAggregateDashboardScreen> createState() => _CycleAggregateDashboardScreenState();
}

class _CycleAggregateDashboardScreenState extends State<CycleAggregateDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  int totalMortality = 0;
  int totalRemainingChicks = 0;
  int totalSoldCount = 0;
  double totalFeedConsumedKg = 0;
  double totalIncome = 0;
  double totalExpense = 0;
  double totalProfit = 0;

  List<_HallSummary> _hallSummaries = [];

  String _num(num v) => NumberFormat('#,###', 'en_US').format(v);
  String _numD(double v) => NumberFormat('#,##0.#', 'en_US').format(v);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAggregatedData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAggregatedData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final db = DatabaseHelper.instance;

      final allReports = await Future.wait(widget.halls.map((h) => db.getReportsForCycle(h.id!)));
      final allIncomes = await Future.wait(widget.halls.map((h) => db.getIncomesForCycle(h.id!)));
      final allExpenses = await Future.wait(widget.halls.map((h) => db.getExpensesForCycle(h.id!)));
      final allFeedOut = await Future.wait(widget.halls.map((h) => db.getTotalFeedOut(h.id!)));

      int mort = 0, sold = 0;
      double feedOut = 0, income = 0, expense = 0;
      final summaries = <_HallSummary>[];

      for (int i = 0; i < widget.halls.length; i++) {
        final hall = widget.halls[i];

        int hMort = allReports[i].fold(0, (sum, r) => sum + r.mortality);
        int hSold = 0;
        double hIncome = 0;
        for (final Income inc in allIncomes[i]) {
          hIncome += inc.totalPrice;
          if (inc.category == 'فروش مرغ') hSold += inc.quantity ?? 0;
        }
        double hExpense = allExpenses[i].fold(0, (sum, e) => sum + e.totalPrice);
        double hFeed = allFeedOut[i];

        mort += hMort;
        sold += hSold;
        feedOut += hFeed;
        income += hIncome;
        expense += hExpense;

        summaries.add(_HallSummary(
          hallNumber: hall.hallNumber,
          initialCount: hall.chickCount,
          mortality: hMort,
          soldCount: hSold,
          feedConsumedKg: hFeed,
          income: hIncome,
          expense: hExpense,
        ));
      }

      if (mounted) {
        setState(() {
          totalMortality = mort;
          totalSoldCount = sold;
          totalRemainingChicks = widget.parent.chickCount - mort - sold;
          totalFeedConsumedKg = feedOut;
          totalIncome = income;
          totalExpense = expense;
          totalProfit = income - expense;
          _hallSummaries = summaries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('خطا در داشبورد کلی: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('داشبورد کلی', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            Text(widget.parent.name, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00695C), Color(0xFF00897B), Color(0xFF26A69A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.door_sliding_outlined, color: Colors.white),
            tooltip: 'انتخاب سالن',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HallSelectionScreen(parent: widget.parent, halls: widget.halls)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.red.shade900,
          labelColor: Colors.white70,
          unselectedLabelColor: Colors.white,
          tabs: const [
            Tab(text: 'خلاصه کلی'),
            Tab(text: 'تفکیک سالن‌ها'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00695C)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSummaryTab(),
                _buildHallBreakdownTab(),
              ],
            ),
    );
  }

  // ── تب خلاصه کلی ─────────────────────────────────────
  Widget _buildSummaryTab() {
    final totalChicks = widget.parent.chickCount;
    final mortalityPct = totalChicks > 0 ? totalMortality / totalChicks * 100 : 0.0;
    final soldPct = totalChicks > 0 ? totalSoldCount / totalChicks * 100 : 0.0;
    final remainingPct = totalChicks > 0 ? totalRemainingChicks / totalChicks * 100 : 0.0;

    return RefreshIndicator(
      onRefresh: _loadAggregatedData,
      color: const Color(0xFF00695C),
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildTopBanner(),
          const SizedBox(height: 16),
          _SectionTitle('وضعیت گله'),
          const SizedBox(height: 8),
          _FlockCard(
            totalCount: totalChicks,
            mortality: totalMortality,
            remaining: totalRemainingChicks,
            sold: totalSoldCount,
            mortalityPct: mortalityPct,
            remainingPct: remainingPct,
            soldPct: soldPct,
            numFn: _num,
          ),
          const SizedBox(height: 16),
          _SectionTitle('مصرف دان'),
          const SizedBox(height: 8),
          _WideStatCard(
            icon: Icons.set_meal,
            title: 'کل دان مصرفی',
            value: '${_numD(totalFeedConsumedKg)} کیلوگرم',
            color: Colors.orange.shade700,
          ),
          const SizedBox(height: 16),
          _SectionTitle('وضعیت مالی'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _MiniFinCard(icon: Icons.trending_up, label: 'درآمد', value: _num(totalIncome.round()), color: const Color(0xFF2E7D32))),
              const SizedBox(width: 12),
              Expanded(child: _MiniFinCard(icon: Icons.trending_down, label: 'هزینه', value: _num(totalExpense.round()), color: Colors.red.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          _ProfitCard(profit: totalProfit, numFn: (v) => _num(v.abs().round())),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00695C), Color(0xFF00897B)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BannerStat('${_num(widget.parent.chickCount)}', 'جوجه اولیه', Icons.catching_pokemon),
          _BannerStat('${widget.halls.length}', 'سالن', Icons.apartment_rounded),
          _BannerStat(widget.parent.formattedStartDate, 'تاریخ شروع', Icons.calendar_today),
        ],
      ),
    );
  }

  // ── تب تفکیک سالن‌ها ─────────────────────────────
  Widget _buildHallBreakdownTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: _hallSummaries.length,
      itemBuilder: (context, index) {
        final h = _hallSummaries[index];
        final remaining = h.initialCount - h.mortality - h.soldCount;
        final remainingPct = h.initialCount > 0 ? remaining / h.initialCount * 100 : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showHallDetailBottomSheet(h),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFF00695C),
                    child: Text('${h.hallNumber}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('سالن ${h.hallNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5)),
                        Text('${_num(h.initialCount)} جوجه • ${_numD(h.feedConsumedKg)} دان',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${remainingPct.toStringAsFixed(0)}٪', style: const TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      Text('${_num(h.mortality)} تلفات', style: TextStyle(color: Colors.red.shade700, fontSize: 13.5, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showHallDetailBottomSheet(_HallSummary h) {
    final profit = h.income - h.expense;
    final remaining = h.initialCount - h.mortality - h.soldCount;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 16),
            Text('سالن ${h.hallNumber}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const Divider(thickness: 1),
            _DetailRow('جوجه اولیه', '${_num(h.initialCount)} قطعه'),
            _DetailRow('تلفات', '${_num(h.mortality)} قطعه', Colors.red),
            _DetailRow('فروش شده', '${_num(h.soldCount)} قطعه', const Color(0xFF00695C)),
            _DetailRow('موجودی فعلی', '${_num(remaining)} قطعه', Colors.blue),
            const Divider(),
            _DetailRow('مصرف دان', '${_numD(h.feedConsumedKg)} کیلوگرم' , Colors.orange),
            // _DetailRow('درآمد', '${_num(h.income.round())} تومان', const Color(0xFF2E7D32)),
            // _DetailRow('هزینه', '${_num(h.expense.round())} تومان', Colors.red),
            // const Divider(thickness: 1.5),
            // // Row(
            // //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            // //   children: [
            // //     const Text('سود / زیان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            // //     Text('${profit >= 0 ? "+" : ""}${_num(profit.round())} تومان',
            // //         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: profit >= 0 ? const Color(0xFF2E7D32) : Colors.red)),
            // //   ],
            // // ),
          ],
        ),
      ),
    );
  }
}

// ── مدل و ویجت‌های کمکی ─────────────────────────────────────
class _HallSummary {
  final int hallNumber, initialCount, mortality, soldCount;
  final double feedConsumedKg, income, expense;

  _HallSummary({
    required this.hallNumber,
    required this.initialCount,
    required this.mortality,
    required this.soldCount,
    required this.feedConsumedKg,
    required this.income,
    required this.expense,
  });
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00695C)),
      );
}

class _BannerStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _BannerStat(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.5)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11.5)),
        ],
      );
}

class _FlockCard extends StatelessWidget {
  final int totalCount, mortality, remaining, sold;
  final double mortalityPct, remainingPct, soldPct;
  final String Function(num) numFn;

  const _FlockCard({
    required this.totalCount,
    required this.mortality,
    required this.remaining,
    required this.sold,
    required this.mortalityPct,
    required this.remainingPct,
    required this.soldPct,
    required this.numFn,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            _ProgressRow('موجودی فعلی', numFn(remaining), remainingPct, Colors.blue.shade700, Icons.people),
            const SizedBox(height: 12),
            _ProgressRow('فروش شده', numFn(sold), soldPct, const Color(0xFF00695C), Icons.sell),
            const SizedBox(height: 12),
            _ProgressRow('تلفات', numFn(mortality), mortalityPct, Colors.red.shade600, Icons.trending_down),
          ],
        ),
      );
}

class _ProgressRow extends StatelessWidget {
  final String label, value;
  final double pct;
  final Color color;
  final IconData icon;

  const _ProgressRow(this.label, this.value, this.pct, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(icon, size: 18, color: color), const SizedBox(width: 8), Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87))]),
              Text('$value (${pct.toStringAsFixed(1)}٪)', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (pct / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      );
}

class _WideStatCard extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color color;

  const _WideStatCard({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: color)),
              ],
            ),
          ],
        ),
      );
}

class _MiniFinCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _MiniFinCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
            Text('$value تومان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: color)),
          ],
        ),
      );
}

class _ProfitCard extends StatelessWidget {
  final double profit;
  final String Function(double) numFn;

  const _ProfitCard({required this.profit, required this.numFn});

  @override
  Widget build(BuildContext context) {
    final isProfit = profit >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isProfit ? [const Color(0xFFE8F5E9), const Color(0xFFA5D6A7)] : [const Color(0xFFFCE4EC), const Color(0xFFEF9A9A)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(isProfit ? Icons.trending_up : Icons.trending_down, color: isProfit ? const Color(0xFF2E7D32) : Colors.red, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('سود / زیان کل', style: TextStyle(fontSize: 13, color: Colors.black54)),
              Text('${isProfit ? "+" : ""}${numFn(profit)} تومان', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isProfit ? const Color(0xFF2E7D32) : Colors.red)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;

  const _DetailRow(this.label, this.value, [this.valueColor]);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: valueColor)),
          ],
        ),
      );
}