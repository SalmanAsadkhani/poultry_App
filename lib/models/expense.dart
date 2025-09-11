// lib/models/expense.dart

class Expense {
  final int? id;
  final int cycleId;
  final String category;
  final String title;
  final String date;
  final int quantity; // ✅ نوع داده int است
  final double? unitPrice;
  final String? description;
  final int? bagCount;
  final double? weight; // ✅ نوع داده double است (نه int)

  Expense({
    this.id,
    required this.cycleId,
    required this.category,
    required this.title,
    required this.date,
    required this.quantity,
    this.unitPrice,
    this.description,
    this.bagCount,
    this.weight,
  });

  double get totalPrice {
    final price = unitPrice ?? 0.0;
    if (category == 'دان' && weight != null) {
      return (weight ?? 0) * price;
    }
    return quantity * price;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycle_id': cycleId,
      'category': category,
      'title': title,
      'date': date,
      'quantity': quantity,
      'unit_price': unitPrice,
      'description': description ?? '', // ✅ null رو به '' تبدیل کن برای UI-safe
      'bag_count': bagCount,
      'weight': weight,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      cycleId: map['cycle_id'],
      category: map['category'],
      title: map['title'],
      date: map['date'],
      // ✅ تبدیل امن‌تر برای اطمینان از نوع int
      quantity: (map['quantity'] as num? ?? 1).toInt(),
      unitPrice: map['unit_price']?.toDouble(),
      description: map['description'] as String?, // ✅ اضافه شد: مستقیم cast به String? (null-safe)
      bagCount: (map['bag_count'] as num?)?.toInt(),
      weight: map['weight']?.toDouble(), 
    );
  }
}