// lib/screens/report_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart'; // برای فرمت تاریخ جلالی
import '../../models/daily_report.dart';

class ReportDetailScreen extends StatelessWidget {
  final DailyReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern('en_us');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "جزئیات گزارش روز ${report.formattedReportDate}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          FadeTransition(
            opacity: const AlwaysStoppedAnimation(1.0), // انیمیشن برای نمایش
            child: _buildDetailCard(
              context: context,
              title: '📊 آمار کلی',
              children: [
                _buildInfoRow(Icons.calendar_today, 'تاریخ:', report.formattedReportDate),
                _buildInfoRow(Icons.airline_seat_flat_angled, 'تلفات:', '${report.mortality} قطعه', Colors.redAccent),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: const AlwaysStoppedAnimation(1.0),
            child: _buildDetailCard(
              context: context,
              title: '🍽️ دان مصرفی',
              children: report.feedConsumed.isEmpty
                  ? [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('موردی ثبت نشده است.', style: TextStyle(color: Colors.grey)),
                      ),
                    ]
                  : report.feedConsumed.map((feed) {
                      return _buildInfoRow(
                        Icons.grain,
                        '${feed.feedType}:',
                        '${feed.bagCount} کیسه (${feed.quantity.toStringAsFixed(1)} کیلوگرم)',
                        Colors.green,
                      );
                    }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: const AlwaysStoppedAnimation(1.0),
            child: _buildDetailCard(
              context: context,
              title: '💊 دارو و واکسن',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    report.medicine != null && report.medicine!.isNotEmpty
                        ? report.medicine!
                        : 'موردی ثبت نشده است.',
                    style: TextStyle(
                      fontSize: 16,
                      color: report.medicine != null && report.medicine!.isNotEmpty ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FadeTransition(
            opacity: const AlwaysStoppedAnimation(1.0),
            child: _buildDetailCard(
              context: context,
              title: '📝 ملاحظات',
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    report.notes != null && report.notes!.isNotEmpty
                        ? report.notes!
                        : 'موردی ثبت نشده است.',
                    style: TextStyle(
                      fontSize: 16,
                      color: report.notes != null && report.notes!.isNotEmpty ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.teal.shade100, width: 1),
      ),
      elevation: 6,
      shadowColor: Colors.teal.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _getIconForTitle(title),
                  color: Colors.teal.shade600,
                  size: 20,
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1.5, color: Colors.teal),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, [Color? iconColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? Colors.teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title) {
      case '📊 آمار کلی':
        return Icons.bar_chart;
      case '🍽️ دان مصرفی':
        return Icons.local_dining;
      case '💊 دارو و واکسن':
        return Icons.local_hospital;
      case '📝 ملاحظات':
        return Icons.note;
      default:
        return Icons.info;
    }
  }
}