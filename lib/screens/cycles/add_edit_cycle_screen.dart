
// lib/screens/add_edit_cycle_screen.dart

import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../helpers/database_helper.dart';
import '../../models/breeding_cycle.dart';
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
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
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
          SnackBar(content: Text('خطا در ذخیره‌سازی: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _validateShamsiDate(String? value) {
    if (value == null || value.isEmpty) return 'لطفاً تاریخ را وارد کنید.';
    if (!RegExp(r'^\d{4}/\d{2}/\d{2}$').hasMatch(value)) return 'فرمت تاریخ صحیح نیست.';
   
    try {
      final parts = value.split('/');
      Jalali(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      return null;
    } catch (e) {
      return 'تاریخ وارد شده معتبر نیست.';
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          hintText: 'مثال: مرداد ماه ۱۴۰۴', // ✅ اضافه شده
                          hintStyle: TextStyle(color: const Color.fromARGB(106, 53, 71, 104)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'لطفاً نام دوره را وارد کنید.' : null,
                      ),
                    ],
                  ),
                ),
              ),
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
                      const SizedBox(height: 12),
                      NumericTextFormField(
                        controller: _chickCountController,
                        decoration: InputDecoration(
                          labelText: 'تعداد جوجه',
                          hintText: 'مثال: 15,000', // ✅ اضافه شده
                          hintStyle: TextStyle(color: const Color.fromARGB(106, 53, 71, 104)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'لطفاً تعداد را وارد کنید.';
                          final number = int.tryParse(value.replaceAll(',', ''));
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                          hintText: 'مثال: 1404/06/01',
                          hintStyle: TextStyle(color: const Color.fromARGB(106, 53, 71, 104)), // ✅ اضافه شده
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                        ),
                        keyboardType: TextInputType.number,
                        validator: _validateShamsiDate,
                        inputFormatters: [_dateMaskFormatter],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveForm,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isEditing ? 'ذخیره تغییرات' : 'ذخیره دوره', style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
