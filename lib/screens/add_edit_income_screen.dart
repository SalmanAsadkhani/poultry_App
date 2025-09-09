import 'package:flutter/material.dart';

class AddEditIncomeScreen extends StatefulWidget {
  const AddEditIncomeScreen({super.key});

  @override
  State<AddEditIncomeScreen> createState() => _AddEditIncomeScreenState();
}

class _AddEditIncomeScreenState extends State<AddEditIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedCategory;
  DateTime? _selectedDate;

  final List<String> _incomeCategories = ['فروش مرغ', 'فروش کود', 'متفرقه'];
  
  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
       if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً یک دسته‌بندی برای درآمد انتخاب کنید.')),
        );
        return;
      }
      // TODO: منطق ذخیره درآمد در دیتابیس
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت درآمد جدید'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان درآمد',
                  hintText: 'مثال: فروش به کشتارگاه X',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'عنوان درآمد نمی‌تواند خالی باشد.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: const Text('انتخاب دسته‌بندی'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _incomeCategories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'مبلغ کل (تومان)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty || double.tryParse(value) == null
                        ? 'لطفاً مبلغ را به صورت عددی وارد کنید.'
                        : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'تعداد',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(
                        labelText: 'وزن کل (کیلوگرم)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(_selectedDate == null
                        ? 'تاریخ درآمد انتخاب نشده'
                        : 'تاریخ: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('انتخاب تاریخ'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveForm,
                icon: const Icon(Icons.save),
                label: const Text('ذخیره درآمد'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
