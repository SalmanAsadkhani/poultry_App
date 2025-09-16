class Feed {
  final int? id;
  final int? expenseId;
  final String name;
  final double? quantity;
  final int? bagCount;
  int? remainingBags; // اضافه شده

  Feed({
    this.id,
    required this.name,
     this.expenseId, // <<-- این خط اضافه شود
    this.quantity,
    this.bagCount,
    this.remainingBags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'expense_id': expenseId, // <<-- این خط اضافه شود
      'bag_count': bagCount,
      'remaining_bags': remainingBags,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory Feed.fromMap(Map<String, dynamic> map) {
    return Feed(
      id: map['id'],
      name: map['name'],
        expenseId: map['expense_id'], // <<-- این
      quantity: map['quantity']?.toDouble(),
      bagCount: map['bag_count'],
      remainingBags: map['remaining_bags'],
    );
  }
}