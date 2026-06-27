import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  

  bool _showFinancialCard = true;
  bool _isLoadingPref = true;

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

    _initData();
  }

  Future<void> _initData() async {
    // بارگذاری با fallback و timeout برای جلوگیری از قفل شدن UI
    await _loadShowFinancialPrefWithFallback();
    if (mounted) setState(() => _isLoadingPref = false);
  }

  /// بارگذاری امن SharedPreferences با timeout و fallback
  Future<void> _loadShowFinancialPrefWithFallback() async {
    const timeoutDur = Duration(seconds: 3);
    try {
      final prefsFuture = SharedPreferences.getInstance();
      final prefs = await prefsFuture.timeout(timeoutDur);
      final key = _prefsKeyForCycle(widget.cycle.id);
      final savedValue = prefs.getBool(key);
      if (mounted) {
        setState(() {
          _showFinancialCard = savedValue ?? true;
        });
      }
    } on TimeoutException catch (e) {
      debugPrint('⚠️ SharedPreferences timeout: $e');
      if (mounted) setState(() => _showFinancialCard = true);
    } catch (e) {
      // هر خطای دیگری — لاگ بزن و مقدار پیش‌فرض رو ست کن
      debugPrint('⚠️ SharedPreferences load failed: $e');
      if (mounted) setState(() => _showFinancialCard = true);
    }
  }

  Future<void> _saveShowFinancialPrefSafely(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _prefsKeyForCycle(widget.cycle.id);
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('⚠️ SharedPreferences save failed: $e');
      // نادیده بگیر — مهم اینه که UI به‌روز شود
    }
  }

  String _prefsKeyForCycle(Object? cycleId) {
    final idStr = cycleId?.toString() ?? 'default';
    return 'showFinancialCard_$idStr';
  }

  @override
  void didUpdateWidget(covariant SummaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) {
      _animationController.forward(from: 0.0);
    }
    if (oldWidget.cycle.id != widget.cycle.id) {
      _initData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // اگر در حال لود prefs هستیم، نشانگر ساده یا متن بدهیم تا UI قفل نشود
    if (widget.isLoading || _isLoadingPref) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00796B)),
      );
    }

    final List<Widget> summaryWidgets = [
      if (_showFinancialCard) _buildFinancialCard(),
      _buildFlockStatsCard(),
      _buildFeedSummaryCard(),
      _buildPerformanceCard(context),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
      },
      color: const Color(0xFF00796B),
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // کنترل نمایش/پنهان‌سازی کارت مالی
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                _showFinancialCard ? 'پنهان‌کردن خلاصه مالی' : 'نمایش خلاصه مالی',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Switch(
                value: _showFinancialCard,
                activeColor: const Color(0xFF00796B),
                onChanged: (value) async {
                  setState(() => _showFinancialCard = value);
                  await _saveShowFinancialPrefSafely(value);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // محتوای کارت‌ها
          ...summaryWidgets.map(
            (w) => FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------
  // 💰 خلاصه مالی
  // -------------------------------
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
            color:
                profitOrLoss >= 0 ? const Color(0xFF004D40) : Colors.red.shade800,
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
          _buildInfoRow(icon: Icons.cake, label: 'سن گله', value: '${widget.chickAge} روز'),
          _buildInfoRow(icon: Icons.numbers, label: 'تعداد اولیه', value: formatter.format(widget.cycle.chickCount)),
          _buildInfoRow(icon: Icons.cancel, label: 'تلفات کل', value: formatter.format(widget.totalMortality), color: Colors.red.shade600),
          _buildInfoRow(icon: Icons.local_shipping, label: 'تعداد فروش رفته', value: formatter.format(widget.totalChickensSold)),
          _buildInfoRow(icon: Icons.scale, label: 'وزن کل فروش رفته', value: '${widget.totalWeightSold.toStringAsFixed(1)} کیلوگرم'),
          const Divider(height: 24, thickness: 0.5),
          _buildInfoRow(icon: Icons.home, label: 'تعداد باقی‌مانده', value: formatter.format(widget.remainingChicks), color: const Color(0xFF0D47A1), isBold: true, valueSize: 18),
        ],
      ),
    );
  }

  // ✅ [اصلاح شده] - تمام موجودی‌های دان را نمایش دهید
  Widget _buildFeedSummaryCard() {
    final formatter = NumberFormat.decimalPattern('en_us');
    
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
            
            // ✅ [اصلاح]: هر نوع دان را با تمام موجودی‌های آن نمایش دهید
            ...widget.feedWeightSummary.entries.map((entry) {
              final feedType = entry.key;
              final bagCount = widget.feedBagCountSummary[feedType] ?? 0;
              
              // ✅ [اصلاح شده]: feedRemainingBagSummary کل موجودی‌ها را دارد
              final remainingBags = widget.feedRemainingBagSummary[feedType] ?? 0;
              
              final consumedWeight = entry.value;
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.shopping_bag, color: Color(0xFFF57C00)),
                          SizedBox(width: 8),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        feedType,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // مصرف شده
                      Text(
                        'مصرف: ${consumedWeight.toStringAsFixed(1)} کیلو  (${bagCount} کیسه)',
                        style: const TextStyle(fontSize: 14),
                      ),
                      
                      // ✅ موجودی باقی‌مانده
                      if (remainingBags > 0) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            '📦 باقی‌مانده در انبار: $remainingBags کیسه',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ]
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
      child: Row(children: [
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
      ]),
    );
  }
}

// --------------- سایر کلاس‌ها بدون تغییر --------------------

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
      child: Column(children: [
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
        Padding(padding: const EdgeInsets.all(16.0), child: child),
      ]),
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(children: [
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
                      'ضریب تبدیل = وزن دان مصرفی / وزن مرغ فروش رفته\nهرچه کمتر، بهتر است',
                ),
                const Divider(height: 24, thickness: 0.5, indent: 16, endIndent: 16),
                cycle.isActive
                    ? _buildLockedProductionIndex(context)
                    : _buildMetricRow(
                        context: context,
                        icon: Icons.trending_up,
                        title: 'شاخص تولید',
                        value: productionIndex != null
                            ? productionIndex!.toStringAsFixed(0)
                            : " - ",
                        infoText:
                            'شاخص تولید = (زنده‌مانی × وزن متوسط) / (FCR × سن روز) × 100\nهرچه بیشتر، بهتر است',
                      ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  static Widget _buildMetricRow({
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.grey, size: 22),
          onPressed: () => _showInfoDialog(context, title, infoText),
        ),
      ],
    );
  }

  static Widget _buildLockedProductionIndex(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.trending_up, color: _primaryColor, size: 28),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'شاخص تولید',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
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
            "شاخص تولید = \n(درصد زنده‌مانی × وزن متوسط) / (FCR × سن روز) × 100\nدر دوره‌های فعال قابل محاسبه نیست",
          ),
        ),
      ],
    );
  }

  static void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(content, style: const TextStyle(height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تایید'),
          ),
        ],
      ),
    );
  }
}