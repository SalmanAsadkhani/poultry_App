import 'package:flutter/material.dart';
import '../../helpers/database_helper.dart';
import '../../models/daily_report.dart';
import '../../models/feed_consumption.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../widgets/numeric_text_form_field.dart';
import '../../services/feed_consumption_analytics.dart';
import '../../models/feed.dart';

class FeedFormEntry {
  String feedType;
  final TextEditingController bagCountController;
  double calculatedWeight;

  FeedFormEntry({
    required this.feedType,
    required this.bagCountController,
    this.calculatedWeight = 0.0,
  });
}

class AddDailyReportScreen extends StatefulWidget {
  final int cycleId;
  final DailyReport? report;
  final DateTime? initialDate;

  const AddDailyReportScreen({
    super.key,
    required this.cycleId,
    this.report,
    this.initialDate,
  });

  @override
  State<AddDailyReportScreen> createState() => _AddDailyReportScreenState();
}

class _AddDailyReportScreenState extends State<AddDailyReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mortalityController = TextEditingController();
  final _medicineController = TextEditingController();
  final _notesController = TextEditingController();

  List<FeedFormEntry> _feedEntries = [];
  List<String> _feedTypes = [];
  bool _isSaving = false;
  bool get _isEditing => widget.report != null;

  List<Feed>? _allFeeds;
  late FeedConsumptionAnalytics _analytics;
  int? _remainingFlock;
  DateTime? _selectedReportDate;

  @override
  void initState() {
    super.initState();
    _analytics = FeedConsumptionAnalytics(feeds: [], dailyReports: []);
    _selectedReportDate = widget.initialDate ?? Jalali.now().toDateTime();
    _loadData();
  }

  Future<void> _loadData() async {
    final allFeedsData = await DatabaseHelper.instance.getFeedsByCycleId(widget.cycleId);
    final reportsData = await DatabaseHelper.instance.getAllReportsForCycle(widget.cycleId);

    if (!mounted) return;

    _allFeeds = allFeedsData;
    _analytics = FeedConsumptionAnalytics(feeds: _allFeeds!, dailyReports: reportsData);
    _feedTypes = _allFeeds!.map((f) => f.name.trim()).toSet().toList();

    if (_isEditing) {
      final report = widget.report!;
      _mortalityController.text = _formatNumber(report.mortality);
      _medicineController.text = report.medicine ?? '';
      _notesController.text = report.notes ?? '';
      _feedEntries = report.feedConsumed.map((consumedFeed) {
        return FeedFormEntry(
          feedType: consumedFeed.feedType,
          bagCountController: TextEditingController(text: _formatNumber(consumedFeed.bagCount)),
          calculatedWeight: consumedFeed.quantity,
        );
      }).toList();
      _selectedReportDate = DateTime.parse(report.reportDate);
    } else {
      _mortalityController.text = '0';
      _addFeedEntry();
    }

    await _loadRemainingFlock();
    setState(() {});
  }

  Future<void> _loadRemainingFlock() async {
    final remaining = await DatabaseHelper.instance.getRemainingFlock(widget.cycleId);
    if (mounted) setState(() => _remainingFlock = remaining);
  }

  String _formatNumber(num? number) {
    if (number == null) return '';
    if (number.truncateToDouble() == number) {
      return number.toInt().toString();
    } else {
      return number.toStringAsFixed(2);
    }
  }

  void _addFeedEntry({String initialBagCount = '0'}) {
    if (_feedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ابتدا باید از بخش هزینه‌ها، دان به انبار اضافه کنید.'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      _feedEntries.add(
        FeedFormEntry(
          feedType: _feedTypes[0],
          bagCountController: TextEditingController(text: initialBagCount),
        ),
      );
    });
    _updateCalculatedWeight(_feedEntries.length - 1);
  }

  void _removeFeedEntry(int index) {
    if (_feedEntries.length > 1) {
      setState(() {
        _feedEntries[index].bagCountController.dispose();
        _feedEntries.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداقل یک ردیف برای دان مصرفی لازم است.'), backgroundColor: Colors.orange),
      );
    }
  }

  void _updateCalculatedWeight(int index) {
    final entry = _feedEntries[index];
    final text = entry.bagCountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final bagCount = int.tryParse(text) ?? 0;

    final feedsOfType = _allFeeds!.where((f) => f.name.trim() == entry.feedType.trim()).toList();
    double avgWeightPerBag = 0;
    int totalBags = 0;
    double totalWeight = 0;

    for (var feed in feedsOfType) {
      final remaining = feed.remainingBags ?? 0;
      final weight = feed.quantity ?? 0;
      final bags = feed.bagCount ?? 0;
      if (remaining > 0 && bags > 0) {
        totalWeight += (weight / bags) * remaining;
        totalBags += remaining;
      }
    }

    if (totalBags > 0) avgWeightPerBag = totalWeight / totalBags;
    setState(() => entry.calculatedWeight = double.parse((bagCount * avgWeightPerBag).toStringAsFixed(2)));
  }

  Future<bool> _checkInventory() async {
    final consumptions = _feedEntries
        .map((entry) {
          final bagCount = int.tryParse(entry.bagCountController.text.replaceAll(',', '')) ?? 0;
          return FeedConsumption(
            reportId: 0,
            feedType: entry.feedType,
            bagCount: bagCount,
            quantity: entry.calculatedWeight,
          );
        })
        .where((feed) => feed.bagCount > 0)
        .toList();

    for (final consumption in consumptions) {
      int availableForCheck;
      if (_isEditing) {
        final currentInventory = _allFeeds!
            .where((f) => f.name.trim() == consumption.feedType.trim())
            .fold<int>(0, (sum, f) => sum + (f.remainingBags ?? 0));
        int oldBags = 0;
        try {
          final oldConsumption = widget.report!.feedConsumed.firstWhere(
            (c) => c.feedType.trim() == consumption.feedType.trim(),
          );
          oldBags = oldConsumption.bagCount;
        } catch (e) {}
        availableForCheck = currentInventory + oldBags;
      } else {
        availableForCheck = _allFeeds!
            .where((f) => f.name.trim() == consumption.feedType.trim())
            .fold<int>(0, (sum, f) => sum + (f.remainingBags ?? 0));
      }

      if (availableForCheck < consumption.bagCount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('موجودی کافی برای "${consumption.feedType}" وجود ندارد. موجودی: $availableForCheck کیسه'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!await _checkInventory()) return;

    final feedsToSave = _feedEntries
        .map((entry) {
          final bagCount = int.tryParse(entry.bagCountController.text.replaceAll(',', '')) ?? 0;
          return FeedConsumption(
            reportId: 0,
            feedType: entry.feedType,
            bagCount: bagCount,
            quantity: entry.calculatedWeight,
          );
        })
        .where((feed) => feed.bagCount > 0)
        .toList();

    if (feedsToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً حداقل یک کیسه دان مصرفی ثبت کنید.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newMortality = int.tryParse(_mortalityController.text.replaceAll(',', '')) ?? 0;

    final cycle = await DatabaseHelper.instance.getCycleById(widget.cycleId);
    final initialChicks = cycle?.chickCount ?? 0;
    final previousMortality = await DatabaseHelper.instance.getTotalMortality(widget.cycleId);
    final previousSales = await DatabaseHelper.instance.getTotalSold(widget.cycleId);

    final currentFlock = initialChicks - previousMortality - previousSales;
    final adjustedFlock = _isEditing ? currentFlock + (widget.report?.mortality ?? 0) : currentFlock;

    if (newMortality > adjustedFlock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا: تعداد تلفات ($newMortality) نمی‌تواند بیشتر از موجودی گله ($adjustedFlock) باشد.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        final updatedReport = DailyReport(
          id: widget.report!.id,
          cycleId: widget.cycleId,
          reportDate: widget.report!.reportDate,
          mortality: newMortality,
          medicine: _medicineController.text,
          notes: _notesController.text,
        );
        await DatabaseHelper.instance.updateDailyReport(updatedReport, feedsToSave);
      } else {
        final newReport = DailyReport(
          cycleId: widget.cycleId,
          reportDate: _selectedReportDate!.toIso8601String().substring(0, 10),
          mortality: newMortality,
          medicine: _medicineController.text,
          notes: _notesController.text,
        );
        await DatabaseHelper.instance.insertDailyReport(newReport, feedsToSave);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ذخیره گزارش: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allFeeds == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'ویرایش گزارش' : 'ثبت گزارش روزانه'),
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final jalaliDate = Jalali.fromDateTime(_selectedReportDate!);
    final formattedDate = '${jalaliDate.year}/${jalaliDate.month.toString().padLeft(2, '0')}/${jalaliDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ویرایش گزارش' : 'ثبت گزارش روزانه'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_isEditing && widget.initialDate != null)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'ثبت گزارش برای: $formattedDate',
                    style: TextStyle(fontSize: 16, color: Colors.teal.shade800),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تلفات امروز',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                    ),
                    const SizedBox(height: 12),
                    NumericTextFormField(
                      controller: _mortalityController,
                      decoration: InputDecoration(
                        labelText: 'تعداد تلفات',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal.shade300)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'این فیلد الزامی است.';
                        final number = int.tryParse(value.replaceAll(',', ''));
                        if (number == null || number < 0) return 'عدد صحیح وارد کنید';
                        final adjustedFlock = _isEditing ? _remainingFlock! + (widget.report?.mortality ?? 0) : _remainingFlock!;
                        if (number > adjustedFlock) {
                          return 'تعداد تلفات نمی‌تواند بیشتر از موجودی باشد.\nموجودی: $adjustedFlock';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'دان مصرفی',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                        ),
                        IconButton(
                          onPressed: () => _addFeedEntry(),
                          icon: const Icon(Icons.add_circle, color: Colors.teal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_feedEntries.length, (index) {
                      final entry = _feedEntries[index];
                      final availableBags = _allFeeds!
                          .where((f) => f.name.trim() == entry.feedType.trim())
                          .fold<int>(0, (sum, f) => sum + (f.remainingBags ?? 0));
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: entry.feedType,
                                    items: _feedTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => entry.feedType = value);
                                        _updateCalculatedWeight(index);
                                      }
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'نوع دان',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal.shade300)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: NumericTextFormField(
                                    controller: entry.bagCountController,
                                    decoration: InputDecoration(
                                      labelText: 'تعداد کیسه',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal.shade300)),
                                    ),
                                    onChanged: (_) => _updateCalculatedWeight(index),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'تعداد کیسه را وارد کنید';
                                      final number = int.tryParse(value.replaceAll(',', ''));
                                      if (number == null || number < 0) return 'عدد صحیح وارد کنید';
                                      return null;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => _removeFeedEntry(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'وزن کل: ${entry.calculatedWeight} کیلو',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                Text(
                                  'موجودی: $availableBags کیسه',
                                  style: const TextStyle(fontSize: 12, color: Colors.deepOrange),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دارو و واکسن',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _medicineController,
                      decoration: InputDecoration(
                        labelText: 'دارو و واکسن (اختیاری)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal.shade300)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملاحظات',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختیاری)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.teal.shade300)),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                  : Text(
                      _isEditing ? 'ذخیره تغییرات' : 'ثبت گزارش',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mortalityController.dispose();
    _medicineController.dispose();
    _notesController.dispose();
    for (var entry in _feedEntries) {
      entry.bagCountController.dispose();
    }
    super.dispose();
  }
}