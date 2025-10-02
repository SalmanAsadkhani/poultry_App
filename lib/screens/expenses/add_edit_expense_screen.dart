// lib/screens/add_edit_expense_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../helpers/database_helper.dart';
import '../../models/expense.dart';
import '../../widgets/numeric_text_form_field.dart';

enum MeasureBy { quantity, weight }

class AddEditExpenseScreen extends StatefulWidget {
  final int cycleId;
  final String category;
  final Expense? expense;

  const AddEditExpenseScreen({
    super.key,
    required this.cycleId,
    required this.category,
    this.expense,
  });

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _bagCountController;
  late TextEditingController _weightController;
  late TextEditingController _descriptionController;

  String _selectedDate = '';
  double _calculatedTotalPrice = 0.0;
  final _formatter = NumberFormat.decimalPattern('en_us');

  MeasureBy _measureBy = MeasureBy.quantity;

  bool get _isEditing => widget.expense != null;
  bool get _isFeed => widget.category == 'دان';

  @override
void initState() {
  super.initState();
  final expense = widget.expense;

  _titleController = TextEditingController(text: expense?.title ?? '');
  _quantityController = TextEditingController(
    text: expense?.quantity?.toString() ?? '',
  );
  _unitPriceController = TextEditingController(
    text: expense?.unitPrice?.toString() ?? '',
  );
  _bagCountController = TextEditingController(
    text: expense?.bagCount?.toString() ?? '',
  );
  _weightController = TextEditingController(
    text: expense?.weight?.toString() ?? '',
  );
  _descriptionController = TextEditingController(
    text: expense?.description ?? '',
  );
  _selectedDate =
      expense?.date ??
      Jalali.now().toDateTime().toIso8601String().substring(0, 10);

  // ✅ اینجا مقدار measureBy رو مشخص کن
  if (widget.category == "متفرقه") {
    if (expense?.weight != null && expense!.weight! > 0) {
      _measureBy = MeasureBy.weight;
    } else {
      _measureBy = MeasureBy.quantity;
    }
  }

  _quantityController.addListener(_calculateTotalPrice);
  _unitPriceController.addListener(_calculateTotalPrice);
  _weightController.addListener(_calculateTotalPrice);

  _calculateTotalPrice();
}


  @override
  void dispose() {
    _quantityController.removeListener(_calculateTotalPrice);
    _unitPriceController.removeListener(_calculateTotalPrice);
    _weightController.removeListener(_calculateTotalPrice);

    _titleController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _bagCountController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _calculateTotalPrice() {
  final unitPrice =
      double.tryParse(_unitPriceController.text.replaceAll(',', '')) ?? 0.0;
  num primaryMetric = 0;

  if (_isFeed) {
    // دسته دان
    primaryMetric =
        double.tryParse(_weightController.text.replaceAll(',', '')) ?? 0.0;
  } else if (widget.category == 'متفرقه') {
    // دسته متفرقه
    if (_measureBy == MeasureBy.weight) {
      primaryMetric =
          double.tryParse(_weightController.text.replaceAll(',', '')) ?? 0.0;
    } else {
      primaryMetric =
          int.tryParse(_quantityController.text.replaceAll(',', '')) ?? 0;
    }
  } else {
    // ✅ دسته‌های دیگه مثل داروخانه
    primaryMetric =
        int.tryParse(_quantityController.text.replaceAll(',', '')) ?? 0;
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

  final unitPrice = double.tryParse(_unitPriceController.text.replaceAll(',', ''));
  
   final expense = Expense(
      id: widget.expense?.id,
      cycleId: widget.cycleId,
      category: widget.category,
      title: _titleController.text,
      date: _selectedDate,
      quantity: int.tryParse(_quantityController.text.replaceAll(',', '')),
      
      weight: double.tryParse(_weightController.text.replaceAll(',', '')),
       unitPrice: unitPrice,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      bagCount: int.tryParse(_bagCountController.text.replaceAll(',', '')),
    );

    try {
      if (_isEditing) {
        await DatabaseHelper.instance.updateExpense(expense);
      } else {
        await DatabaseHelper.instance.insertExpense(expense);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ویرایش هزینه' : 'افزودن هزینه'),
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
                    _isFeed
                        ? DropdownButtonFormField<String>(
                            value:
                                [
                                  'استارتر',
                                  'پیش دان',
                                  'میان دان',
                                  'میان دان دو',
                                  'پس دان',
                                  'پس دان دو',
                                ].contains(_titleController.text)
                                ? _titleController.text
                                : null,
                            hint: const Text('نوع دان را انتخاب کنید'),
                            items:
                                [
                                      'استارتر',
                                      'پیش دان',
                                      'میان دان',
                                      'میان دان دو',
                                      'پس دان',
                                      'پس دان دو',
                                    ]
                                    .map(
                                      (type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (newValue) => setState(
                              () => _titleController.text = newValue!,
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'نوع دان الزامی است'
                                : null,
                            decoration: InputDecoration(
                              labelText: 'نوع دان',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: primaryColor.withOpacity(0.3),
                                ),
                              ),
                            ),
                          )
                        : TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'عنوان / نام',
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
                                v!.isEmpty ? 'این فیلد الزامی است' : null,
                                
                          ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isFeed) ...[
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
                        'جزئیات دان',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      NumericTextFormField(
                        controller: _bagCountController,
                        allowDecimal: false,
                        decoration: InputDecoration(
                          labelText: 'تعداد کیسه',
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
                            ? 'تعداد کیسه الزامی است.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      NumericTextFormField(
                        allowDecimal: true,
                        controller: _weightController,
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'وزن الزامی است.';
                          final cleanValue = v.replaceAll(',', '');
                          final number = double.tryParse(cleanValue);
                          if (number == null || number <= 0)
                            return 'مقدار معتبر و بزرگتر از صفر وارد کنید';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],


            if (!_isFeed && widget.category != "متفرقه") ...[
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: Color.fromARGB(255, 240, 248, 245),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('جزئیات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                              const SizedBox(height: 12),
                              NumericTextFormField(
                                controller: _quantityController,
                                allowDecimal: false,
                                decoration: InputDecoration(
                                  labelText: 'تعداد',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'تعداد الزامی است.';
                                  final cleanValue = v.replaceAll(',', '');
                                  final number = int.tryParse(cleanValue);
                                  if (number == null || number <= 0) return 'مقدار باید یک عدد صحیح و بزرگتر از صفر باشد';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),        
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
                      decoration: InputDecoration(
                        labelText: _isFeed
                            ? 'قیمت واحد (هر کیلوگرم)'
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
                        labelText: 'قیمت کل (تومان)',
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
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveForm,
              child: Text(
                _isEditing ? 'ذخیره تغییرات' : 'ثبت هزینه',
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