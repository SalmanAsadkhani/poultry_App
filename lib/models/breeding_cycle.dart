import 'package:shamsi_date/shamsi_date.dart';

class BreedingCycle {
  final int? id;
  final String name;
  final String startDate; // فرمت: YYYY-MM-DD (شمسی)
  final String endDate;
  final int chickCount;
  final bool isActive;

  BreedingCycle({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.chickCount,
    required this.isActive,
  });

  /// تاریخ شروع با فرمت yyyy/MM/dd برای نمایش
  String get formattedStartDate {
    try {
      final parts = startDate.split('-');
      if (parts.length != 3) return startDate;

      final year = parts[0];
      final month = parts[1].padLeft(2, '0');
      final day = parts[2].padLeft(2, '0');

      return '$year/$month/$day';
    } catch (e) {
      return startDate;
    }
  }

  /// تاریخ شمسی Jalali
  String get jalaliStartDate {
    try {
      final parts = startDate.split('-'); // YYYY-MM-DD
      if (parts.length != 3) return startDate;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      final jalaliDate = Jalali(y, m, d);
      return '${jalaliDate.formatter.yyyy}/${jalaliDate.formatter.mm}/${jalaliDate.formatter.dd}';
    } catch (e) {
      return startDate;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'start_date': startDate,
        'end_date': endDate,
        'chick_count': chickCount,
        'is_active': isActive ? 1 : 0,
      };

  factory BreedingCycle.fromMap(Map<String, dynamic> map) => BreedingCycle(
        id: map['id'],
        name: map['name'],
        startDate: map['start_date'],
        endDate: map['end_date'],
        chickCount: map['chick_count'],
        isActive: map['is_active'] == 1,
      );
}
