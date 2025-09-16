import 'package:shamsi_date/shamsi_date.dart';

class BreedingCycle {
  final int? id;
  final String name;
  final String startDate; // فرمت: YYYY-MM-DD (شمسی)
  final String endDate;   // فرمت: YYYY-MM-DD (شمسی)
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

  /// تاریخ شروع میلادی (برای محاسبات)
  DateTime? get startDateTime {
    try {
      final parts = startDate.split('-'); // YYYY-MM-DD
      if (parts.length != 3) return null;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return Jalali(y, m, d).toDateTime();
    } catch (e) {
      return null;
    }
  }

  /// تاریخ پایان میلادی (برای محاسبات)
  DateTime? get endDateTime {
    try {
      final parts = endDate.split('-'); // YYYY-MM-DD
      if (parts.length != 3) return null;
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return Jalali(y, m, d).toDateTime();
    } catch (e) {
      return null;
    }
  }

  /// تاریخ شروع شمسی با فرمت yyyy/MM/dd برای نمایش
  String get formattedStartDate {
    try {
      final parts = startDate.split('-');
      if (parts.length != 3) return startDate;
      final y = parts[0];
      final m = parts[1].padLeft(2, '0');
      final d = parts[2].padLeft(2, '0');
      return '$y/$m/$d';
    } catch (e) {
      return startDate;
    }
  }

  /// تاریخ پایان شمسی با فرمت yyyy/MM/dd برای نمایش

String get formattedEndDate {
  try {
    final parts = endDate.split('-'); // فرمت YYYY-MM-DD
    if (parts.length != 3) return endDate;

    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);

    // تبدیل میلادی به شمسی
    final gregorianDate = Gregorian(y, m, d);
    final jalaliDate = gregorianDate.toJalali();

    final formattedYear = jalaliDate.year.toString().padLeft(4, '0');
    final formattedMonth = jalaliDate.month.toString().padLeft(2, '0');
    final formattedDay = jalaliDate.day.toString().padLeft(2, '0');

    return '$formattedYear/$formattedMonth/$formattedDay';
  } catch (e) {
    return endDate;
  }
}

  /// تاریخ شروع شمسی با فرمت Jalali کامل
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
        'isActive': isActive ? 1 : 0,
      };

  factory BreedingCycle.fromMap(Map<String, dynamic> map) => BreedingCycle(
        id: map['id'],
        name: map['name'],
        startDate: map['start_date'],
        endDate: map['end_date'],
        chickCount: map['chick_count'],
        isActive: map['isActive'] == 1,
      );
}
