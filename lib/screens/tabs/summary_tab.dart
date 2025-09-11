// lib/screens/tabs/summary_tab.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/breeding_cycle.dart';

class SummaryTab extends StatelessWidget {
  final bool isLoading;
  final int chickAge;
  final int remainingChicks;
  final int totalMortality;
  final int totalChickensSold; // ✅ پارامتر جدید
  final double totalFeedWeight;
  final Map<String, int> feedBagCountSummary;
  final Map<String, double> feedWeightSummary;
  final double totalIncome;
  final double totalExpense;
  final BreedingCycle cycle;
  final VoidCallback onRefresh;

  const SummaryTab({
    super.key,
    required this.isLoading,
    required this.chickAge,
    required this.remainingChicks,
    required this.totalMortality,
    required this.totalChickensSold, // ✅ اضافه شده به سازنده
    required this.totalFeedWeight,
    required this.feedBagCountSummary,
    required this.feedWeightSummary,
    required this.totalIncome,
    required this.totalExpense,
    required this.cycle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    final formatter = NumberFormat.decimalPattern('en_us');
    final profitOrLoss = totalIncome - totalExpense;

    if (isLoading) {
      return Center(
        child: FadeTransition(
          opacity: const AlwaysStoppedAnimation(1.0), // انیمیشن fade برای لودینگ
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: primaryColor,
      backgroundColor: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Card خلاصه مالی با گرادیان header
          _buildGradientCard(
            context,
            gradient: LinearGradient(
              colors: [primaryColor, const Color.fromARGB(255, 6, 109, 99)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.account_balance_wallet_outlined,
            title: 'خلاصه مالی',
            children: [
              _buildInfoRow('کل درآمد:', '${formatter.format(totalIncome)} تومان', color: Colors.green.shade600),
              _buildInfoRow('کل هزینه:', '${formatter.format(totalExpense)} تومان', color: Colors.red.shade600),
              const Divider(thickness: 1, height: 20, color: Colors.grey),
              AnimatedScale(
                scale: profitOrLoss.abs() > 0 ? 1.05 : 1.0, // انیمیشن scale برای highlight
                duration: const Duration(milliseconds: 500),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: profitOrLoss >= 0 ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: profitOrLoss >= 0 ? Colors.green.shade300 : Colors.red.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        profitOrLoss >= 0 ? 'سود خالص:' : 'زیان خالص:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: profitOrLoss >= 0 ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                      Text(
                        '${formatter.format(profitOrLoss.abs())} تومان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: profitOrLoss >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
         
          _buildGradientCard(
            context,
            gradient: LinearGradient(
              colors: [const Color.fromARGB(255, 10, 101, 180), const Color.fromARGB(255, 6, 73, 128)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.info_outline,
            title: 'آمار گله',
            children: [
              _buildInfoRow('سن گله:', '$chickAge روز', color: Colors.blue.shade600),
              _buildInfoRow('تعداد اولیه:', formatter.format(cycle.chickCount), color: Colors.blue.shade600),
              _buildInfoRow('تعداد تلفات:', formatter.format(totalMortality), color: Colors.red.shade600),
              _buildInfoRow('تعداد فروش رفته:', formatter.format(totalChickensSold), color: Colors.orange.shade600),
              const Divider(thickness: 1, height: 20, color: Colors.grey),
              _buildInfoRow('تعداد باقی‌مانده:', formatter.format(remainingChicks), isBold: true, color: primaryColor),
            ],
          ),
          const SizedBox(height: 16),
          // Card خلاصه مصرف دان با رنگ سبز متنوع
          _buildGradientCard(
            context,
            gradient: LinearGradient(
              colors: [Colors.green.shade600, const Color.fromARGB(255, 5, 75, 9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            icon: Icons.restaurant_menu,
            title: 'خلاصه مصرف دان',
            children: [
              _buildInfoRow('جمع کل:', '${totalFeedWeight.toStringAsFixed(1)} کیلوگرم', color: const Color.fromARGB(255, 71, 64, 26)),
              if (feedWeightSummary.isNotEmpty) ...[
                const Divider(thickness: 0.5, height: 24, color: Colors.grey),
                ...feedWeightSummary.entries.map((e) {
                  final feedType = e.key;
                  final totalWeight = e.value;
                  final totalBags = feedBagCountSummary[feedType] ?? 0;
                  return _buildInfoRow(
                    '$feedType:',
                    '${totalWeight.toStringAsFixed(1)} کیلوگرم (از $totalBags کیسه)',
                    color: const Color.fromARGB(255, 26, 71, 27),
                  );
                }),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Widget جدید برای Card با گرادیان header (جذاب‌تر از Card معمولی)
  Widget _buildGradientCard(
    BuildContext context, {
    required Gradient gradient,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header با گرادیان
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // InfoRow بهبودیافته با رنگ متغیر
  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.grey[700],
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}