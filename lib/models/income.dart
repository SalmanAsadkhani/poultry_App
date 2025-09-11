// lib/models/income.dart

class Income {
  final int? id;
  final int cycleId;
  final String category; // e.g., 'فروش مرغ', 'فروش کود', 'متفرقه'
  final String title;
  final String date; // YYYY-MM-DD
  final int? quantity; // تعداد (مثلاً تعداد مرغ)
  final double? weight;   // وزن (مثلاً وزن کل)
  final double? unitPrice; // قیمت واحد (می‌تواند خالی باشد)
  final String? description;

  Income({
    this.id,
    required this.cycleId,
    required this.category,
    required this.title,
    required this.date,
    this.quantity,
    this.weight,
    this.unitPrice,
    this.description,
  });

  // قیمت کل به صورت خودکار محاسبه می‌شود
  double get totalPrice {
    final price = unitPrice ?? 0.0;
    // اگر وزن ثبت شده بود، بر اساس وزن محاسبه کن، در غیر این صورت بر اساس تعداد
    if (weight != null && weight! > 0) {
      return weight! * price;
    }
    return (quantity ?? 0) * price;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cycle_id': cycleId,
      'category': category,
      'title': title,
      'date': date,
      'quantity': quantity,
      'weight': weight,
      'unit_price': unitPrice,
      'description': description,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      cycleId: map['cycle_id'],
      category: map['category'],
      title: map['title'],
      date: map['date'],
      quantity: (map['quantity'] as num?)?.toInt(),
      weight: map['weight']?.toDouble(), 
      unitPrice: map['unit_price']?.toDouble(),
      description: map['description'],
    );
  }
}