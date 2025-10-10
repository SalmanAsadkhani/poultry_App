
// lib/screens/tabs/summary_tab.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/breeding_cycle.dart';
import '../../helpers/database_helper.dart';

class SummaryTab extends StatefulWidget {
  final bool isLoading;
  final int chickAge;
  final int remainingChicks;
  final int totalMortality;
  final int totalChickensSold;
  final double totalWeightSold;
  final double totalFeedWeight;
  final Map<String, int> feedBagCountSummary;
  final Map<String, double> feedWeightSummary;
  final Map<String, int> feedRemainingBagSummary;
  final double totalIncome;
  final double totalExpense;
  final BreedingCycle cycle;
  final VoidCallback onRefresh;
  final double? fcr;
  final double? productionIndex;

  const SummaryTab({
    super.key,
    required this.isLoading,
    required this.chickAge,
    required this.remainingChicks,
    required this.totalMortality,
    required this.totalChickensSold,
    required this.totalWeightSold,
    required this.totalFeedWeight,
    required this.feedBagCountSummary,
    required this.feedWeightSummary,
    required this.feedRemainingBagSummary,
    required this.totalIncome,
    required this.totalExpense,
    required this.cycle,
    required this.onRefresh,
    this.fcr,
    this.productionIndex,
  });

  @override
  State<SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<SummaryTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Map<String, int> _currentCycleRemainingBags = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (!widget.isLoading) {
      _animationController.forward();
    }
    
    _loadCurrentCycleRemainingBags();
  }

  Future<void> _loadCurrentCycleRemainingBags() async {
    final remainingBags = await DatabaseHelper.instance.getRemainingFeedBagsByCycleId(widget.cycle.id!);
    
    if (mounted) {
      setState(() {
        _currentCycleRemainingBags = remainingBags;
      });
    }
  }

  @override
  void didUpdateWidget(covariant SummaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      _animationController.forward(from: 0.0);
    }
    if (oldWidget.cycle.id != widget.cycle.id) {
      _loadCurrentCycleRemainingBags();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00796B)),
      );
    }

    final List<Widget> summaryWidgets = [
      _buildFinancialCard(),
      _buildFlockStatsCard(),
      _buildFeedSummaryCard(),
      _buildPerformanceCard(context),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
        await _loadCurrentCycleRemainingBags();
      },
      color: const Color(0xFF00796B),
      child: ListView.builder(
        itemCount: summaryWidgets.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (context, index) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: summaryWidgets[index],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialCard() {
    final formatter = NumberFormat.decimalPattern('en_us');
    final profitOrLoss = widget.totalIncome - widget.totalExpense;

    return _SummaryCard(
      title: 'خلاصه مالی',
      icon: Icons.account_balance_wallet,
      gradientColors: const [Color(0xFF00796B), Color(0xFF004D40)],
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.arrow_upward,
            label: 'کل درآمد',
            value: '${formatter.format(widget.totalIncome)} تومان',
            color: Colors.green.shade700,
          ),
          _buildInfoRow(
            icon: Icons.arrow_downward,
            label: 'کل هزینه',
            value: '${formatter.format(widget.totalExpense)} تومان',
            color: Colors.red.shade700,
          ),
          const Divider(height: 24, thickness: 0.5),
          _buildInfoRow(
            icon: profitOrLoss >= 0 ? Icons.trending_up : Icons.trending_down,
            label: profitOrLoss >= 0 ? 'سود خالص' : 'زیان خالص',
            value: '${formatter.format(profitOrLoss.abs())} تومان',
            color: profitOrLoss >= 0
                ? const Color(0xFF004D40)
                : Colors.red.shade800,
            isBold: true,
            valueSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildFlockStatsCard() {
    final formatter = NumberFormat.decimalPattern('en_us');
    return _SummaryCard(
      title: 'آمار گله',
      icon: Icons.info,
      gradientColors: const [Color(0xFF1976D2), Color(0xFF0D47A1)],
      child: Column(
        children: [
          _buildInfoRow(
              icon: Icons.cake,
              label: 'سن گله',
              value: '${widget.chickAge} روز'),
          _buildInfoRow(
              icon: Icons.numbers,
              label: 'تعداد اولیه',
              value: formatter.format(widget.cycle.chickCount)),
          _buildInfoRow(
              icon: Icons.cancel,
              label: 'تلفات کل',
              value: formatter.format(widget.totalMortality),
              color: Colors.red.shade600),
          _buildInfoRow(
              icon: Icons.local_shipping,
              label: 'تعداد فروش رفته',
              value: formatter.format(widget.totalChickensSold)),
          _buildInfoRow(
              icon: Icons.scale,
              label: 'وزن کل فروش رفته',
              value: '${widget.totalWeightSold.toStringAsFixed(1)} کیلوگرم'),
          const Divider(height: 24, thickness: 0.5),
          _buildInfoRow(
            icon: Icons.home,
            label: 'تعداد باقی‌مانده',
            value: formatter.format(widget.remainingChicks),
            color: const Color(0xFF0D47A1),
            isBold: true,
            valueSize: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedSummaryCard() {
    return _SummaryCard(
      title: 'خلاصه مصرف دان',
      icon: Icons.restaurant,
      gradientColors: const [Color(0xFFF57C00), Color(0xFFE65100)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.scale,
            label: 'جمع کل وزن مصرفی',
            value: '${widget.totalFeedWeight.toStringAsFixed(1)} کیلوگرم',
            color: const Color(0xFFE65100),
            isBold: true,
          ),
          if (widget.feedWeightSummary.isNotEmpty) ...[
            const Divider(height: 24, thickness: 0.5),
            ...widget.feedWeightSummary.entries.map((entry) {
              final bagCount = widget.feedBagCountSummary[entry.key] ?? 0;
              final remainingBags = _currentCycleRemainingBags[entry.key] ?? 0;
              final consumedWeight = entry.value;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag,
                              color: Color(0xFFF57C00)),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'مصرف: ${consumedWeight.toStringAsFixed(1)} کیلو  (${bagCount} کیسه)',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (remainingBags > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'باقی‌مانده در انبار : $remainingBags کیسه',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(BuildContext context) {
    return ProductionIndexCard(
      cycle: widget.cycle,
      fcr: widget.fcr,
      productionIndex: widget.productionIndex,
    );
  }

  Widget _buildInfoRow({
    IconData? icon,
    required String label,
    required String value,
    Color? color,
    bool isBold = false,
    double valueSize = 16,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: color ?? Colors.grey.shade600),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: valueSize,
              color: color ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradientColors;
  final Widget child;

  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.gradientColors,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}

class ProductionIndexCard extends StatelessWidget {
  final BreedingCycle cycle;
  final double? fcr;
  final double? productionIndex;

  const ProductionIndexCard({
    super.key,
    required this.cycle,
    this.fcr,
    this.productionIndex,
  });

  static const Color _primaryColor = Color(0xFF673AB7);
  static const Color _accentColor = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, Colors.deepPurple.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: const [
                Icon(Icons.bar_chart, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'شاخص‌های عملکرد',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildMetricRow(
                    context: context,
                    icon: Icons.sync_alt,
                    title: 'ضریب تبدیل (FCR)',
                    value: fcr != null ? fcr!.toStringAsFixed(2) : " - ",
                    infoText:
                        'ضریب تبدیل =\n (وزن کل دان مصرفی) ÷ (وزن کل مرغ فروخته شده)\n\nهرچه کمتر، بهتر.',
                  ),
                  const Divider(
                      height: 24, thickness: 0.5, indent: 16, endIndent: 16),
                  cycle.isActive
                      ? _buildLockedProductionIndex(context)
                      : _buildMetricRow(
                          context: context,
                          icon: Icons.trending_up,
                          title: 'شاخص تولید',
                          value: productionIndex != null
                              ? productionIndex!.toStringAsFixed(2)
                              : " - ",
                          infoText:
                              'شاخص تولید = (درصد زنده‌مانی × میانگین وزن) ÷ (FCR × سن گله) × 100',
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String infoText,
  }) {
    return Row(
      children: [
        Icon(icon, color: _primaryColor, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: _primaryColor),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.grey, size: 22),
          onPressed: () => _showInfoDialog(context, title, infoText),
        ),
      ],
    );
  }

  Widget _buildLockedProductionIndex(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.trending_up, color: _primaryColor, size: 28),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'شاخص تولید',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Row(
              children: [
                Icon(Icons.lock, color: Colors.grey, size: 18),
                SizedBox(width: 6),
                Text(
                  " - ",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
          ],
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.grey, size: 22),
          onPressed: () => _showInfoDialog(
            context,
            "شاخص تولید",
            "شاخص تولید = \n(درصد زنده‌مانی × میانگین وزن)\n ÷ ( ضریب تبدیل × سن گله) × 100\n\n"
            "⚠️ توجه: این شاخص فقط پس از پایان دوره محاسبه و نمایش داده می‌شود.",
          ),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info, color: _accentColor),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          content,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'متوجه شدم',
              style: TextStyle(
                  color: _primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}