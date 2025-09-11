// lib/models/feed_consumption.dart

class FeedConsumption {
  final int? id;
  final int reportId;
  final String feedType;
  final double quantity; // مقدار مصرفی به کیلوگرم (محاسبه شده)
  final int bagCount; // ✅ فیلد جدید: تعداد کیسه

  FeedConsumption({
    this.id,
    required this.reportId,
    required this.feedType,
    required this.quantity,
    required this.bagCount, // ✅ اضافه شده به سازنده
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'report_id': reportId,
        'feed_type': feedType,
        'quantity': quantity,
        'bag_count': bagCount, // ✅ اضافه شده به مپ
      };

  factory FeedConsumption.fromMap(Map<String, dynamic> map) => FeedConsumption(
        id: map['id'],
        reportId: map['report_id'],
        feedType: map['feed_type'],
        quantity: map['quantity'].toDouble(),
        bagCount: map['bag_count'], // ✅ خواندن از مپ
      );
}