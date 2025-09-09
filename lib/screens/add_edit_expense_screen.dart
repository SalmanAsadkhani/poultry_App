import 'package:flutter/material.dart';

class AddEditExpenseScreen extends StatefulWidget {
  const AddEditExpenseScreen({super.key});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  DateTime? _selectedDate;

  final List<String> _expenseCategories = ['دان', 'دارو', 'متفرقه'];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        // نمایش خطا اگر دسته‌بندی انتخاب نشده باشد
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً یک دسته‌بندی برای هزینه انتخاب کنید.')),
        );
        return;
      }
      // TODO: منطق ذخیره هزینه در دیتابیس
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت هزینه جدید'),
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
                  labelText: 'عنوان هزینه',
                  hintText: 'مثال: خرید ۳۰ کیسه پیش دان',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'عنوان هزینه نمی‌تواند خالی باشد.' : null,
              ),
              const SizedBox(height: 16),
              // فیلد کشویی برای انتخاب دسته‌بندی
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: const Text('انتخاب دسته‌بندی'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _expenseCategories
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
                  labelText: 'مبلغ (تومان)',
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
                    child: Text(_selectedDate == null
                        ? 'تاریخ هزینه انتخاب نشده'
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
                label: const Text('ذخیره هزینه'),
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
