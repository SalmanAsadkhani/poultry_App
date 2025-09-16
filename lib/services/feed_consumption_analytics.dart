// فایل: services/feed_consumption_analytics.dart

import 'dart:math';
import '../models/feed.dart';
import '../models/daily_report.dart';

// کلاس نتیجه آنالیز بدون تغییر باقی می‌ماند
// فایل: services/feed_consumption_analytics.dart

class FeedAnalyticsResult {
  final List<Map<String, dynamic>> summary;
  final double grandTotalKg;
  final List<Map<String, dynamic>> inventoryLeft;
  final List<Feed> detailedInventoryState; // <<-- این خط مهم اضافه شود

  FeedAnalyticsResult({
    required this.summary,
    required this.grandTotalKg,
    required this.inventoryLeft,
    required this.detailedInventoryState, // <<-- این خط مهم اضافه شود
  });
}

/// این کلاس به طور کامل برای پیاده‌سازی منطق FIFO بازنویسی شده است
class FeedConsumptionAnalytics {
  final List<Feed> feeds; // این لیست باید از قبل بر اساس تاریخ خرید مرتب شده باشد
  final List<DailyReport> dailyReports;

  FeedConsumptionAnalytics({
    required this.feeds,
    required this.dailyReports,
  });

  /// [جدید] وزن دقیق مصرف را بر اساس منطق FIFO شبیه‌سازی و محاسبه می‌کند
  double calculateConsumptionWeight({
    required String feedType,
    required int bagsToConsume,
  }) {
    if (bagsToConsume <= 0) return 0.0;

    double totalWeightConsumed = 0.0;

    // یک کپی از موجودی فعلی برای شبیه‌سازی می‌سازیم
    final inventoryState = feeds.map((f) => Feed.fromMap(f.toMap())).toList();

    for (final batch in inventoryState) {
      if (batch.name.trim() == feedType.trim() && (batch.remainingBags ?? 0) > 0) {
        final avgWeightPerBag = (batch.quantity ?? 0.0) / (batch.bagCount ?? 1);
        final bagsToTake = min(bagsToConsume, batch.remainingBags ?? 0);

        totalWeightConsumed += bagsToTake * avgWeightPerBag;
        bagsToConsume -= bagsToTake;

        if (bagsToConsume == 0) break;
      }
    }
    return totalWeightConsumed;
  }

  /// [بازنویسی شده] آنالیز کامل را بر اساس منطق FIFO انجام می‌دهد
  FeedAnalyticsResult getAnalytics() {
    // یک کپی عمیق از موجودی‌ها برای دستکاری ایجاد می‌کنیم
    final List<Feed> inventoryState = feeds.map((f) => Feed.fromMap(f.toMap())).toList();

    final List<DailyReport> sortedDailyReports = List.from(dailyReports)
      ..sort((a, b) => DateTime.parse(a.reportDate).compareTo(DateTime.parse(b.reportDate)));

    double grandTotalWeightConsumed = 0.0;
    final Map<String, Map<String, dynamic>> summaryMap = {};

    for (final report in sortedDailyReports) {
      for (final consumption in report.feedConsumed) {
        int bagsToConsume = consumption.bagCount;
        String feedTypeToConsume = consumption.feedType.trim();

        // حلقه در بچ‌های موجودی برای پیدا کردن قدیمی‌ترین مورد
        for (final batch in inventoryState) {
          if (bagsToConsume == 0) break;

          if (batch.name.trim() == feedTypeToConsume && (batch.remainingBags ?? 0) > 0) {
            final avgWeightPerBagForBatch = (batch.quantity ?? 0.0) / (batch.bagCount ?? 1);
            final bagsTaken = min(bagsToConsume, batch.remainingBags ?? 0);
            final weightConsumed = bagsTaken * avgWeightPerBagForBatch;

            grandTotalWeightConsumed += weightConsumed;
            batch.remainingBags = (batch.remainingBags ?? 0) - bagsTaken;
            bagsToConsume -= bagsTaken;
            
            summaryMap.putIfAbsent(feedTypeToConsume, () => {'name': feedTypeToConsume, 'total_weight_used': 0.0, 'bags_used': 0});
            summaryMap[feedTypeToConsume]!['total_weight_used'] = (summaryMap[feedTypeToConsume]!['total_weight_used'] as double) + weightConsumed;
            summaryMap[feedTypeToConsume]!['bags_used'] = (summaryMap[feedTypeToConsume]!['bags_used'] as int) + bagsTaken;
          }
        }
      }
    }

    final List<Map<String, dynamic>> feedSummary = summaryMap.values.toList();
    for (final summaryItem in feedSummary) {
      summaryItem['total_weight_used'] = (summaryItem['total_weight_used'] as double).round();
    }

    // تجمیع موجودی نهایی برای نمایش
    final Map<String, int> finalInventoryMap = {};
    for (final batch in inventoryState) {
        final current = finalInventoryMap[batch.name.trim()] ?? 0;
        finalInventoryMap[batch.name.trim()] = current + (batch.remainingBags ?? 0);
    }
    final List<Map<String, dynamic>> finalInventory = finalInventoryMap.entries
        .map((e) => {'name': e.key, 'remaining': e.value})
        .toList();

      return FeedAnalyticsResult(
      summary: feedSummary,
      grandTotalKg: grandTotalWeightConsumed.roundToDouble(),
      inventoryLeft: finalInventory,
      detailedInventoryState: inventoryState, // <<-- این خط مهم اضافه شود
    );
  }

  // متد hasEnoughInventory و بقیه متدهای قبلی برای سادگی حذف شده‌اند
  // و منطق آنها در UI یا متدهای جدید گنجانده شده است.
  bool hasEnoughInventory(String feedType, int requestedBags) {
    int totalRemaining = 0;
    for (final feed in feeds) {
      if (feed.name.trim() == feedType.trim()) {
        totalRemaining += (feed.remainingBags ?? 0);
      }
    }
    return totalRemaining >= requestedBags;
  }
}