// lib/screens/add_daily_report_screen.dart

import 'package:flutter/material.dart';
import '../../helpers/app_config.dart';
import '../../helpers/database_helper.dart';
import '../../models/daily_report.dart';
import '../../models/feed_consumption.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../widgets/numeric_text_form_field.dart';

class FeedFormEntry {
  String feedType;
  final TextEditingController bagCountController;
  int calculatedWeight;
  FeedFormEntry({
    required this.feedType,
    required this.bagCountController,
    this.calculatedWeight = 0,
  });
}

class AddDailyReportScreen extends StatefulWidget {
  final int cycleId;
  final DailyReport? report;

  const AddDailyReportScreen({super.key, required this.cycleId, this.report});

  @override
  State<AddDailyReportScreen> createState() => _AddDailyReportScreenState();
}

class _AddDailyReportScreenState extends State<AddDailyReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mortalityController = TextEditingController();
  final _medicineController = TextEditingController();
  final _notesController = TextEditingController();

  final List<FeedFormEntry> _feedEntries = [];
  final List<String> _feedTypes = feedTypeWeights.keys.toList();

  bool _isSaving = false;
  bool get _isEditing => widget.report != null;

  String _formatNumber(num? number) {
    if (number == null) return '';
    if (number.truncateToDouble() == number) {
      return number.toInt().toString();
    } else {
      return number.toString();
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final report = widget.report!;
      _mortalityController.text = _formatNumber(report.mortality);
      _medicineController.text = report.medicine ?? '';
      _notesController.text = report.notes ?? '';

      if (report.feedConsumed.isNotEmpty) {
        for (var feed in report.feedConsumed) {
          _addFeedEntry(initialBagCount: _formatNumber(feed.bagCount));
        }
      } else {
        _addFeedEntry();
      }
    } else {
      _mortalityController.text = '0';
      _addFeedEntry();
    }
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

  void _addFeedEntry({String initialBagCount = '0'}) {
    setState(() {
      _feedEntries.add(
        FeedFormEntry(
          feedType: _feedTypes[0],
          bagCountController: TextEditingController(text: initialBagCount),
        ),
      );
    });
    if (_feedEntries.isNotEmpty) {
      _updateCalculatedWeight(_feedEntries.length - 1);
    }
  }

  void _removeFeedEntry(int index) {
    if (_feedEntries.length > 1) {
      setState(() {
        _feedEntries[index].bagCountController.dispose();
        _feedEntries.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('حداقل یک ردیف برای دان مصرفی لازم است.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _updateCalculatedWeight(int index) {
    final entry = _feedEntries[index];
    final bagCount =
        int.tryParse(entry.bagCountController.text.replaceAll(',', '')) ?? 0;
    final weightPerBag = feedTypeWeights[entry.feedType] ?? 0.0;
    setState(() {
      entry.calculatedWeight = (bagCount * weightPerBag).round();
    });
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    final feedsToSave = _feedEntries
        .map((entry) {
          final bagCount =
              int.tryParse(entry.bagCountController.text.replaceAll(',', '')) ??
              0;
          final weightPerBag = feedTypeWeights[entry.feedType] ?? 0.0;
          final quantity = (bagCount * weightPerBag);
          return FeedConsumption(
            reportId: 0,
            feedType: entry.feedType,
            bagCount: bagCount,
            quantity: quantity,
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

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        final updatedReport = DailyReport(
          id: widget.report!.id,
          cycleId: widget.cycleId,
          reportDate: widget.report!.reportDate,
          mortality: int.parse(_mortalityController.text.replaceAll(',', '')),
          medicine: _medicineController.text,
          notes: _notesController.text,
        );
        await DatabaseHelper.instance.updateDailyReport(
          updatedReport,
          feedsToSave,
        );
      } else {
        final newReport = DailyReport(
          cycleId: widget.cycleId,
          reportDate: Jalali.now().toDateTime().toIso8601String().substring(
            0,
            10,
          ),
          mortality: int.parse(_mortalityController.text.replaceAll(',', '')),
          medicine: _medicineController.text,
          notes: _notesController.text,
        );
        await DatabaseHelper.instance.insertDailyReport(newReport, feedsToSave);
      }

      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ویرایش گزارش' : 'ثبت گزارش روزانه'),
        backgroundColor: const Color.fromARGB(255, 5, 114, 99),
        foregroundColor: const Color.fromARGB(255, 245, 248, 248),
        elevation: 5,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تلفات امروز',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    NumericTextFormField(
                      controller: _mortalityController,
                      decoration: InputDecoration(
                        labelText: 'تعداد تلفات',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal.shade300),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'این فیلد الزامی است.';
                        final number = int.tryParse(value.replaceAll(',', ''));
                        if (number == null || number < 0)
                          return 'عدد صحیح وارد کنید';
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دان مصرفی',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildFeedFormFields(),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'افزودن نوع دیگر دان',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: _addFeedEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'دارو و واکسن',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _medicineController,
                      decoration: InputDecoration(
                        labelText: 'دارو و واکسن (اختیاری)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملاحظات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'ملاحظات (اختیاری)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.teal.shade300),
                        ),
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
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Text(
                      _isEditing ? 'ذخیره تغییرات' : 'ثبت گزارش',
                      style: const TextStyle(fontSize: 16),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeedFormFields() {
    return List.generate(_feedEntries.length, (index) {
      final entry = _feedEntries[index];
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                value: entry.feedType,
                items: _feedTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => entry.feedType = value);
                    _updateCalculatedWeight(index);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'نوع دان',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal.shade300),
                  ),
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
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.teal.shade300),
                  ),
                ),
                onChanged: (_) => _updateCalculatedWeight(index),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'تعداد کیسه را وارد کنید';
                  final number = int.tryParse(value.replaceAll(',', ''));
                  if (number == null || number < 0) return 'عدد صحیح وارد کنید';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () => _removeFeedEntry(index),
            ),
          ],
        ),
      );
    });
  }
}
