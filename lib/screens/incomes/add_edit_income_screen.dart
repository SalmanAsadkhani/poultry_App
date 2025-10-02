// lib/screens/add_edit_income_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../helpers/database_helper.dart';
import '../../models/income.dart';
import '../../widgets/numeric_text_form_field.dart';

// یک enum برای مدیریت حالت انتخاب بین تعداد و وزن در دسته متفرقه
enum MeasureBy { quantity, weight }

class AddEditIncomeScreen extends StatefulWidget {
  final int cycleId;
  final String category;
  final Income? income;
  final int remainingChicks;

  const AddEditIncomeScreen({
    super.key,
    required this.cycleId,
    required this.category,
    this.income,
    required this.remainingChicks,
  });

  @override
  State<AddEditIncomeScreen> createState() => _AddEditIncomeScreenState();
}

class _AddEditIncomeScreenState extends State<AddEditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _quantityController;
  late TextEditingController _weightController;
  late TextEditingController _unitPriceController;
  late TextEditingController _descriptionController;
  String _selectedDate = '';
  double _calculatedTotalPrice = 0.0;
  final _formatter = NumberFormat.decimalPattern('en_us');

  // متغیر State برای نگهداری انتخاب کاربر در دسته متفرقه
  MeasureBy _measureBy = MeasureBy.quantity;
  bool get _isEditing => widget.income != null;

  int get _availableChicksForSale {
    if (_isEditing && widget.category == 'فروش مرغ') {
      // در حالت ویرایش: موجودی فعلی + تعداد مرغ‌های همین فاکتور
      return widget.remainingChicks + (widget.income?.quantity ?? 0);
    }
    // در حالت ثبت جدید: همان موجودی فعلی
    return widget.remainingChicks;
  }

  String _formatNumber(num? number) {
    if (number == null || number == 0) return '';
    if (number.truncateToDouble() == number) return number.toInt().toString();
    return number.toStringAsFixed(3); // نمایش تا ۳ رقم اعشار برای وزن
  }

  @override
  void initState() {
    super.initState();
    final income = widget.income;
    _titleController = TextEditingController(text: income?.title ?? '');
    _quantityController = TextEditingController(
      text: _formatNumber(income?.quantity),
    );
    _weightController = TextEditingController(
      text: _formatNumber(income?.weight),
    );
    _unitPriceController = TextEditingController(
      text: _formatNumber(income?.unitPrice),
    );
    _descriptionController = TextEditingController(
      text: income?.description ?? '',
    );
    _selectedDate =
        income?.date ??
        Jalali.now().toDateTime().toIso8601String().substring(0, 10);
    if (_isEditing && (income?.weight ?? 0) > 0) {
      _measureBy = MeasureBy.weight;
    }
    _quantityController.addListener(_calculateTotalPrice);
    _weightController.addListener(_calculateTotalPrice);
    _unitPriceController.addListener(_calculateTotalPrice);
    _calculateTotalPrice();
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotalPrice);
    _weightController.removeListener(_calculateTotalPrice);
    _unitPriceController.removeListener(_calculateTotalPrice);
    _titleController.dispose();
    _quantityController.dispose();
    _weightController.dispose();
    _unitPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ✅ ۱. اصلاح کامل منطق محاسبه قیمت کل
  void _calculateTotalPrice() {
    final unitPrice =
        double.tryParse(_unitPriceController.text.replaceAll(',', '')) ?? 0.0;
    num primaryMetric = 0;

    if (widget.category == 'فروش مرغ' || widget.category == 'فروش کود') {
      primaryMetric =
          double.tryParse(_weightController.text.replaceAll(',', '')) ?? 0.0;
    } else {
      // متفرقه
     if (widget.category == 'متفرقه') {
        if (_measureBy == MeasureBy.weight) {
          primaryMetric = double.tryParse(_weightController.text.replaceAll(',', '')) ?? 0.0;
        } else {
          primaryMetric = int.tryParse(_quantityController.text.replaceAll(',', '')) ?? 0;
        }
      }

    }

    if (mounted) {
      setState(() => _calculatedTotalPrice = primaryMetric * unitPrice);
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.category == 'متفرقه') {
      final quantity =
          int.tryParse(_quantityController.text.replaceAll(',', '')) ?? 0;
      final weight =
          double.tryParse(_weightController.text.replaceAll(',', '')) ?? 0.0;
      if (quantity <= 0 && weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'برای دسته متفرقه، باید حداقل مقدار "تعداد" یا "وزن" را وارد کنید.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    final income = Income(
      id: widget.income?.id,
      cycleId: widget.cycleId,
      category: widget.category,
      title: _titleController.text,
      date: _selectedDate,
     quantity: int.tryParse(_quantityController.text.replaceAll(',', '')),
      
      weight: double.tryParse(_weightController.text.replaceAll(',', '')),
      unitPrice: double.tryParse(_unitPriceController.text.replaceAll(',', '')),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );
    try {
      if (_isEditing) {
        await DatabaseHelper.instance.updateIncome(income);
      } else {
        await DatabaseHelper.instance.insertIncome(income);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('خطا در ذخیره‌سازی: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromARGB(255, 5, 141, 96);
    final String titleLabel = (widget.category == 'متفرقه')
        ? 'نام جنس'
        : 'عنوان';
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ویرایش درآمد' : 'افزودن درآمد'),
        backgroundColor: primaryColor,
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Colors.teal.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
                    Text(
                      'عنوان',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: titleLabel,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? '$titleLabel الزامی است' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.category == 'فروش مرغ') ...[
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
                      Text(
                        'جزئیات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      NumericTextFormField(
                        controller: _quantityController,
                        allowDecimal: false,
                        decoration: InputDecoration(
                          labelText: 'تعداد',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'تعداد الزامی است';
                          final quantity =
                              int.tryParse(v.replaceAll(',', '')) ?? 0;
                          if (quantity <= 0)
                            return 'تعداد باید بیشتر از صفر باشد';
                          if (quantity > _availableChicksForSale) {
                            return 'تعداد وارد شده از باقی مانده مرغ بیشتر است!\n(موجود: $_availableChicksForSale)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      NumericTextFormField(
                        controller: _weightController,
                        allowDecimal: true,
                        decoration: InputDecoration(
                          labelText: 'وزن کل (کیلوگرم)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v == null ||
                                v.isEmpty ||
                                (double.tryParse(v.replaceAll(',', '')) ?? 0) <=
                                    0)
                            ? 'وزن الزامی است'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (widget.category == 'فروش کود') ...[
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
                      Text(
                        'جزئیات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      NumericTextFormField(
                        controller: _weightController,
                        allowDecimal: true,
                        decoration: InputDecoration(
                          labelText: 'وزن (کیلوگرم)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                        ),
                        validator: (v) =>
                            (v == null ||
                                v.isEmpty ||
                                (double.tryParse(v.replaceAll(',', '')) ?? 0) <=
                                    0)
                            ? 'وزن الزامی است'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (widget.category == 'متفرقه') ...[
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
                      Text(
                        'ثبت بر اساس',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<MeasureBy>(
                              title: const Text('تعداد'),
                              value: MeasureBy.quantity,
                              groupValue: _measureBy,
                             onChanged: (value) {
                                setState(() {
                                  _measureBy = value!;
                                  if (_measureBy == MeasureBy.quantity) {
                                    _weightController.clear(); // وزن پاک شه
                                  } else {
                                    _quantityController.clear(); // تعداد پاک شه
                                  }
                                });
                              },
                              activeColor: primaryColor,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<MeasureBy>(
                              title: const Text('وزن'),
                              value: MeasureBy.weight,
                              groupValue: _measureBy,
                            onChanged: (value) {
                              setState(() {
                                _measureBy = value!;
                                if (_measureBy == MeasureBy.quantity) {
                                  _weightController.clear(); // وزن پاک شه
                                } else {
                                  _quantityController.clear(); // تعداد پاک شه
                                }
                              });
                            },
                              activeColor: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (_measureBy == MeasureBy.quantity)
                        NumericTextFormField(
                          controller: _quantityController,
                          allowDecimal: false,
                          decoration: InputDecoration(
                            labelText: 'تعداد',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: primaryColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                      if (_measureBy == MeasureBy.weight)
                        NumericTextFormField(
                          controller: _weightController,
                          allowDecimal: true,
                          decoration: InputDecoration(
                            labelText: 'وزن (کیلوگرم)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: primaryColor.withOpacity(0.3),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                    Text(
                      'قیمت',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    NumericTextFormField(
                      controller: _unitPriceController,
                      allowDecimal: true, // قیمت واحد می‌تواند اعشاری باشد
                      decoration: InputDecoration(
                        labelText:
                            (widget.category == 'فروش کود' ||
                                widget.category == 'فروش مرغ')
                            ? 'قیمت واحد (هر کیلو)'
                            : 'قیمت واحد (تومان)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'مبلغ کل (تومان)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Text(
                        _formatter.format(_calculatedTotalPrice),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
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
                    Text(
                      'توضیحات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'توضیحات (اختیاری)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: primaryColor.withOpacity(0.3),
                          ),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value != null && value.trim().isEmpty)
                          return null; // optional
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveForm,
              child: Text(
                _isEditing ? 'ذخیره تغییرات' : 'ثبت درآمد',
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
    );
  }
}
