// import 'package:shamsi_date/shamsi_date.dart';

// class BreedingCycle {
//   final int? id;
//   final String name;
//   final String startDate; // فرمت: YYYY-MM-DD (شمسی)
//   /// تاریخ پایان دوره در دیتابیس nullable است و معمولاً به صورت ISO میلادی ذخیره می‌شود.
//   final String? endDate;
//   final int chickCount;
//   final bool isActive;

//   BreedingCycle({
//     this.id,
//     required this.name,
//     required this.startDate,
//     this.endDate,
//     required this.chickCount,
//     required this.isActive,
//   });

//   /// تاریخ شروع میلادی (برای محاسبات)
//   DateTime? get startDateTime {
//     try {
//       final parts = startDate.split('-'); // YYYY-MM-DD
//       if (parts.length != 3) return null;
//       final y = int.parse(parts[0]);
//       final m = int.parse(parts[1]);
//       final d = int.parse(parts[2]);
//       return Jalali(y, m, d).toDateTime();
//     } catch (e) {
//       return null;
//     }
//   }

//   /// تاریخ پایان میلادی (برای محاسبات)
//   DateTime? get endDateTime {
//     try {
//       final value = endDate;
//       if (value == null || value.isEmpty) return null;
//       return DateTime.tryParse(value);
//     } catch (e) {
//       return null;
//     }
//   }

//   /// تاریخ شروع شمسی با فرمت yyyy/MM/dd برای نمایش
//   String get formattedStartDate {
//     try {
//       final parts = startDate.split('-');
//       if (parts.length != 3) return startDate;
//       final y = parts[0];
//       final m = parts[1].padLeft(2, '0');
//       final d = parts[2].padLeft(2, '0');
//       return '$y/$m/$d';
//     } catch (e) {
//       return startDate;
//     }
//   }

//   /// تاریخ پایان شمسی با فرمت yyyy/MM/dd برای نمایش

// String get formattedEndDate {
//   try {
//     final value = endDate;
//     if (value == null || value.isEmpty) return '';

//     final parts = value.split('-'); // فرمت YYYY-MM-DD
//     if (parts.length != 3) return value;

//     final y = int.parse(parts[0]);
//     final m = int.parse(parts[1]);
//     final d = int.parse(parts[2]);

//     // تبدیل میلادی به شمسی
//     final gregorianDate = Gregorian(y, m, d);
//     final jalaliDate = gregorianDate.toJalali();

//     final formattedYear = jalaliDate.year.toString().padLeft(4, '0');
//     final formattedMonth = jalaliDate.month.toString().padLeft(2, '0');
//     final formattedDay = jalaliDate.day.toString().padLeft(2, '0');

//     return '$formattedYear/$formattedMonth/$formattedDay';
//   } catch (e) {
//     return endDate ?? '';
//   }
// }

//   /// تاریخ شروع شمسی با فرمت Jalali کامل
//   String get jalaliStartDate {
//     try {
//       final parts = startDate.split('-'); // YYYY-MM-DD
//       if (parts.length != 3) return startDate;
//       final y = int.parse(parts[0]);
//       final m = int.parse(parts[1]);
//       final d = int.parse(parts[2]);
//       final jalaliDate = Jalali(y, m, d);
//       return '${jalaliDate.formatter.yyyy}/${jalaliDate.formatter.mm}/${jalaliDate.formatter.dd}';
//     } catch (e) {
//       return startDate;
//     }
//   }

//   Map<String, dynamic> toMap() => {
//         'id': id,
//         'name': name,
//         'start_date': startDate,
//         'end_date': endDate,
//         'chick_count': chickCount,
//         'isActive': isActive ? 1 : 0,
//       };

//   factory BreedingCycle.fromMap(Map<String, dynamic> map) => BreedingCycle(
//         id: map['id'],
//         name: map['name'],
//         startDate: map['start_date'],
//         endDate: map['end_date'] as String?,
//         chickCount: map['chick_count'],
//         isActive: map['isActive'] == 1,
//       );
// }

import 'package:shamsi_date/shamsi_date.dart';

class BreedingCycle {
  final int? id;
  final String name;
  final String startDate;
  final String? endDate;
  final int chickCount;
  final bool isActive;
  final int? parentCycleId;  // null = دوره اصلی، non-null = سالن
  final int hallNumber;      // 0 = تک‌سالن، 1/2/3... = شماره سالن
  final int hallCount;       // 1 = تک‌سالن، >1 = تعداد سالن‌ها

  BreedingCycle({
    this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    required this.chickCount,
    this.isActive = true,
    this.parentCycleId,
    this.hallNumber = 0,
    this.hallCount = 1,
  });

  bool get isHall => parentCycleId != null;
  bool get isMultiHall => hallCount > 1;

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
      final value = endDate;
      if (value == null || value.isEmpty) return null;
      return DateTime.tryParse(value);
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
    final value = endDate;
    if (value == null || value.isEmpty) return '';

    final parts = value.split('-'); // فرمت YYYY-MM-DD
    if (parts.length != 3) return value;

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
    return endDate ?? '';
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


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'chick_count': chickCount,
      'isActive': isActive ? 1 : 0,
      'parent_cycle_id': parentCycleId,
      'hall_number': hallNumber,
      'hall_count': hallCount,
    };
  }

  factory BreedingCycle.fromMap(Map<String, dynamic> map) {
    return BreedingCycle(
      id: map['id'] as int?,
      name: map['name'] as String,
      startDate: map['start_date'] as String,
      endDate: map['end_date'] as String?,
      chickCount: map['chick_count'] as int,
      isActive: (map['isActive'] as int) == 1,
      parentCycleId: map['parent_cycle_id'] as int?,
      hallNumber: (map['hall_number'] as int?) ?? 0,
      hallCount: (map['hall_count'] as int?) ?? 1,
    );
  }

  BreedingCycle copyWith({
    int? id,
    String? name,
    String? startDate,
    String? endDate,
    int? chickCount,
    bool? isActive,
    int? parentCycleId,
    int? hallNumber,
    int? hallCount,
  }) {
    return BreedingCycle(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      chickCount: chickCount ?? this.chickCount,
      isActive: isActive ?? this.isActive,
      parentCycleId: parentCycleId ?? this.parentCycleId,
      hallNumber: hallNumber ?? this.hallNumber,
      hallCount: hallCount ?? this.hallCount,
    );
  }
}