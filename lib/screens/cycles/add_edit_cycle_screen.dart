import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../helpers/database_helper.dart';
import '../../models/breeding_cycle.dart';
import '../../models/daily_report.dart';
import '../../widgets/numeric_text_form_field.dart';

class AddEditCycleScreen extends StatefulWidget {
  final BreedingCycle? cycle;
  const AddEditCycleScreen({super.key, this.cycle});

  @override
  State<AddEditCycleScreen> createState() => _AddEditCycleScreenState();
}

class _AddEditCycleScreenState extends State<AddEditCycleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _chickCountController = TextEditingController();
  final _dateController = TextEditingController();
  final _dateMaskFormatter = MaskTextInputFormatter(
    mask: '####/##/##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  bool _isSaving = false;
  bool get _isEditing => widget.cycle != null;
  String? _dateError; // برای نمایش خطا در کادر تاریخ

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.cycle!.name;
      _chickCountController.text = widget.cycle!.chickCount.toString();
      _dateController.text = widget.cycle!.formattedStartDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _chickCountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    setState(() => _dateError = null); // پاک کردن خطای قبلی
    if (!_formKey.currentState!.validate()) {
      setState(() => _isSaving = false);
      return;
    }
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // تبدیل تاریخ شروع جدید به DateTime
      final newStartDateParts = _dateController.text.split('/');
      final newStartJalali = Jalali(
        int.parse(newStartDateParts[0]),
        int.parse(newStartDateParts[1]),
        int.parse(newStartDateParts[2]),
      );
      final newStartDate = newStartJalali.toDateTime();

      // اگر در حال ویرایش هستیم، بررسی گزارش‌های موجود
      if (_isEditing) {
        final reports = await DatabaseHelper.instance.getAllReportsForCycle(widget.cycle!.id!);
        if (reports.isNotEmpty) {
          // پیدا کردن اولین تاریخ گزارش
          final sortedReports = List<DailyReport>.from(reports)
            ..sort((a, b) {
              final aDate = DateTime.parse(a.reportDate);
              final bDate = DateTime.parse(b.reportDate);
              return aDate.compareTo(bDate);
            });
          final firstReportDate = DateTime.parse(sortedReports.first.reportDate);

          // مقایسه تاریخ شروع جدید با اولین گزارش
          if (newStartDate.isAfter(firstReportDate)) {
            if (mounted) {
              setState(() {
                _dateError =
                    'نمی‌توانید تاریخ شروع را به بعد از اولین گزارش \n \t(${sortedReports.first.formattedReportDate}) تغییر دهید.';
              });
            }
            setState(() => _isSaving = false);
            return;
          }
        }
      }

      // ادامه ذخیره‌سازی اگر مشکلی نبود
      final newCycle = BreedingCycle(
        id: widget.cycle?.id,
        name: _nameController.text,
        chickCount: int.parse(_chickCountController.text.replaceAll(',', '')),
        startDate: _dateController.text.replaceAll('/', '-'), // ذخیره با فرمت YYYY-MM-DD
        endDate: '',
        isActive: widget.cycle?.isActive ?? true,
      );

      if (_isEditing) {
        await DatabaseHelper.instance.updateCycle(newCycle);
      } else {
        await DatabaseHelper.instance.insertCycle(newCycle);
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ذخیره‌سازی: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateShamsiDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'لطفاً تاریخ را وارد کنید (مثال: 1404/01/01)';
    }
    if (!RegExp(r'^\d{4}/\d{2}/\d{2}$').hasMatch(value)) {
      return 'فرمت تاریخ باید به صورت YYYY/MM/DD\n باشد (مثال: 1404/01/01)';
    }

    try {
      final parts = value.split('/');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      final jalali = Jalali(year, month, day);
      // بررسی معقول بودن تاریخ
      if (year < 1300 || year > 1500) {
        return 'سال باید بین 1300 تا 1500 باشد \n(مثال: 1404/01/01)';
      }
      if (month < 1 || month > 12) {
        return 'ماه باید بین 01 تا 12 باشد \n(مثال: 1404/01/01)';
      }
      if (day < 1 || day > jalali.monthLength) {
        return 'روز باید بین 01 تا ${jalali.monthLength.toString().padLeft(2, '0')} \nباشد برای ماه $month';
      }
      return null;
    } catch (e) {
      return 'تاریخ وارد شده معتبر نیست (مثال: 1404/01/01)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromARGB(255, 17, 92, 67);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ویرایش دوره' : 'افزودن دوره جدید'),
        backgroundColor: primaryColor,
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, const Color.fromARGB(255, 11, 104, 94)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Color.fromARGB(255, 240, 248, 245),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'نام دوره',
                          hintText: 'مثال: فروردین ۱۴۰۴',
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(106, 53, 71, 104),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'لطفاً نام دوره را وارد کنید.'
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Color.fromARGB(255, 240, 248, 245),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      NumericTextFormField(
                        controller: _chickCountController,
                        decoration: InputDecoration(
                          labelText: 'تعداد جوجه',
                          hintText: 'مثال: 15,000',
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(106, 53, 71, 104),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'لطفاً تعداد را وارد کنید.';
                          final number = int.tryParse(
                            value.replaceAll(',', ''),
                          );
                          if (number == null || number <= 0) {
                            return 'لطفاً یک عدد معتبر و بزرگتر از صفر وارد کنید.';
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
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Color.fromARGB(255, 240, 248, 245),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'تاریخ شروع',
                          hintText: 'مثال: 1404/01/01',
                          helperText: 'تاریخ را به صورت سال/ماه/روز\n (مثل 1404/01/01) وارد کنید',
                          hintStyle: TextStyle(
                            color: const Color.fromARGB(106, 53, 71, 104),
                          ),
                          errorText: _dateError, // نمایش خطا در کادر
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red.withOpacity(0.7),
                              width: 2,
                            ),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red.withOpacity(0.7),
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        textDirection: TextDirection.ltr, // برای اطمینان از چیدمان چپ به راست
                        textAlign: TextAlign.left, // مکان‌نما در سمت چپ
                        validator: _validateShamsiDate,
                        inputFormatters: [_dateMaskFormatter],
                        style: const TextStyle(
                          fontFamily: 'Vazir',
                          fontSize: 16,
                        ), 
                        onTap: () {
                          // قرار دادن مکان‌نما در انتهای متن
                          _dateController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _dateController.text.length),
                          );
                        },
                        onChanged: (value) {
                          // پاک کردن خطا هنگام تغییر متن
                          if (_dateError != null) {
                            setState(() => _dateError = null);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveForm,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEditing ? 'ذخیره تغییرات' : 'ذخیره دوره',
                        style: const TextStyle(fontSize: 16),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}