// lib/models/daily_report.dart

import 'package:shamsi_date/shamsi_date.dart';
import 'feed_consumption.dart';

class DailyReport {
  final int? id;
  final int cycleId;
  final String reportDate; // فرمت ذخیره شده: YYYY-MM-DD میلادی
  final int mortality;
  final String? medicine;
  final String? notes;
  final List<FeedConsumption> feedConsumed;

  DailyReport({
    this.id,
    required this.cycleId,
    required this.reportDate,
    required this.mortality,
    this.medicine,
    this.notes,
    this.feedConsumed = const [],
  });
  
  String get formattedReportDate {
    try {
      final dateTime = DateTime.parse(reportDate);
      final jalaliDate = Jalali.fromDateTime(dateTime);
      
      // ✅ اصلاح نهایی: رشته تاریخ را به صورت دستی با اجزای آن می‌سازیم
      return '${jalaliDate.formatter.yyyy}/${jalaliDate.formatter.mm}/${jalaliDate.formatter.dd}';
      
    } catch (e) {
      return reportDate;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'cycle_id': cycleId,
        'report_date': reportDate,
        'mortality': mortality,
        'medicine': medicine,
        'notes': notes,
      };

  factory DailyReport.fromMap(Map<String, dynamic> map) => DailyReport(
        id: map['id'],
        cycleId: map['cycle_id'],
        reportDate: map['report_date'],
        mortality: map['mortality'],
        medicine: map['medicine'],
        notes: map['notes'],
      );
}