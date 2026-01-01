// lib/screens/report_detail_screen.dart
import 'package:flutter/material.dart';
import '../../models/daily_report.dart';

class ReportDetailScreen extends StatelessWidget {
  final DailyReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
  

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "جزئیات گزارش روز ${report.formattedReportDate}",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 8, 128, 114)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 8, 128, 114), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildDetailCard(
                context: context,
                title: ' آمار کلی',
                icon: Icons.assessment,
                children: [
                  _buildInfoRow(Icons.calendar_today, 'تاریخ:', report.formattedReportDate, const Color.fromARGB(255, 56, 142, 128)),
                  _buildInfoRow(Icons.warning_amber_rounded, 'تلفات:', '${report.mortality} قطعه', Colors.redAccent),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailCard(
                context: context,
                title: ' دان مصرفی',
                icon: Icons.grain,
                children: report.feedConsumed.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Center(
                            child: Text('موردی ثبت نشده است.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ),
                        ),
                      ]
                    : report.feedConsumed.map((feed) {
                        return _buildInfoRow(
                          Icons.grass,
                          '${feed.feedType}:',
                          '${feed.bagCount} کیسه (${feed.quantity.toStringAsFixed(1)} کیلوگرم)',
                          Colors.green.shade700,
                        );
                      }).toList(),
              ),
              const SizedBox(height: 16),
              _buildDetailCard(
                context: context,
                title: ' دارو و واکسن',
                icon: Icons.medical_services,
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
              const SizedBox(height: 16),
              _buildDetailCard(
                context: context,
                title: ' ملاحظات',
                icon: Icons.notes,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 6,
      shadowColor: Colors.green.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.green.shade200, thickness: 1.5),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, [Color? iconColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (iconColor ?? Colors.green.shade700).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor ?? Colors.green.shade700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }
}