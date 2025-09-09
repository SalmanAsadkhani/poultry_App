import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/breeding_cycle.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class AddEditCycleScreen extends StatefulWidget {
  final BreedingCycle? cycle; // اضافه کردن پارامتر named برای ویرایش

  const AddEditCycleScreen({super.key, this.cycle});

  @override
  State<AddEditCycleScreen> createState() => _AddEditCycleScreenState();
}

class _AddEditCycleScreenState extends State<AddEditCycleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _chickCountController = TextEditingController();
  final _dateController = TextEditingController();

  bool _isSaving = false;


  final _dateMaskFormatter = MaskTextInputFormatter(
      mask: '####/##/##', filter: {"#": RegExp(r'[0-9]')});

  @override
  void initState() {
    super.initState();

    // اگر cycle پاس داده شده، مقادیر را پر کن
    if (widget.cycle != null) {
      _nameController.text = widget.cycle!.name;
      _chickCountController.text = widget.cycle!.chickCount.toString();
      _dateController.text = widget.cycle!.startDate; // فرض بر YYYY/MM/DD
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

    final dateParts = _dateController.text.split('/');
    if (dateParts.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('فرمت تاریخ صحیح نیست. مثال: 1404/06/01'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);

    if (year == null || month == null || day == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تاریخ معتبر نیست.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final newCycle = BreedingCycle(
        id: widget.cycle?.id,
        name: _nameController.text,
        chickCount: int.parse(_chickCountController.text),
        startDate: _dateController.text,
        endDate: widget.cycle?.endDate ?? '',
        isActive: widget.cycle?.isActive ?? true,
      );

      if (widget.cycle == null) {
        await DatabaseHelper.instance.insertCycle(newCycle);
      } else {
        await DatabaseHelper.instance.updateCycle(newCycle);
      }

      if (mounted) Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cycle != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش دوره' : 'افزودن دوره جدید'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'نام دوره',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'لطفاً نام دوره را وارد کنید.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _chickCountController,
                decoration: const InputDecoration(
                  labelText: 'تعداد جوجه',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty || int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'لطفاً تعداد جوجه را به صورت یک عدد معتبر وارد کنید.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'تاریخ شروع (مثال: 1404/06/01)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [_dateMaskFormatter],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'لطفاً تاریخ را وارد کنید.';
                  }
                  if (!RegExp(r'^\d{4}/\d{2}/\d{2}$').hasMatch(value)) {
                    return 'فرمت تاریخ صحیح نیست.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveForm,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(isEditing ? 'ویرایش دوره' : 'ذخیره دوره'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
