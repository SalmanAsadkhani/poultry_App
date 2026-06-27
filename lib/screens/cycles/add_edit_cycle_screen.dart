import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../../helpers/database_helper.dart';
import '../../models/breeding_cycle.dart';
import '../../models/daily_report.dart';
import '../../widgets/numeric_text_form_field.dart';
import '../../widgets/thousands_separator_formatter.dart';

class AddEditCycleScreen extends StatefulWidget {
  final BreedingCycle? cycle;
  const AddEditCycleScreen({super.key, this.cycle});

  @override
  State<AddEditCycleScreen> createState() => _AddEditCycleScreenState();
}

class _AddEditCycleScreenState extends State<AddEditCycleScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _nameController       = TextEditingController();
  final _chickCountController = TextEditingController();
  final _dateController       = TextEditingController();
  final _hallCountController  = TextEditingController();
  final _dateMaskFormatter    = MaskTextInputFormatter(
    mask: '####/##/##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  // formatter مشترک برای همه فیلدهای عددی سالن
  final _thousandsFormatter = ThousandsSeparatorFormatter();

  bool    _isSaving       = false;
  bool    _isLoadingHalls = false;
  String? _dateError;
  String? _hallCountError;

  int  _hallCount = 1;
  List<TextEditingController> _hallControllers = [];
  List<int?> _existingHallIds = [];

  bool get _isEditing => widget.cycle != null;

  // فقط برای نمایش (نه ویرایش)
  String _fmt(int v) => NumberFormat('#,###', 'en_US').format(v);

  // تبدیل متن با کاما به عدد
  int _parseFormatted(String text) =>
      int.tryParse(text.replaceAll(',', '')) ?? 0;

  @override
  void initState() {
    super.initState();
    _hallControllers = [TextEditingController()];
    _hallCountController.text = '1';

    if (_isEditing) {
      final c = widget.cycle!;
      _nameController.text       = c.name;
      // مقدار اولیه با کاما
      _chickCountController.text = _fmt(c.chickCount);
      _dateController.text       = c.formattedStartDate;

      final currentHallCount    = c.hallCount > 0 ? c.hallCount : 1;
      _hallCount                = currentHallCount;
      _hallCountController.text = currentHallCount.toString();

      while (_hallControllers.length < _hallCount) {
        _hallControllers.add(TextEditingController());
      }

      if (c.isMultiHall) {
        _loadExistingHalls();
      }
    }
  }

  Future<void> _loadExistingHalls() async {
    if (!mounted) return;
    setState(() => _isLoadingHalls = true);

    try {
      final halls = await DatabaseHelper.instance
          .getHallsForCycle(widget.cycle!.id!);

      if (!mounted) return;

      while (_hallControllers.length < halls.length) {
        _hallControllers.add(TextEditingController());
      }

      _existingHallIds = List.filled(halls.length, null);
      for (int i = 0; i < halls.length; i++) {
        _existingHallIds[i] = halls[i].id;
        // مقدار اولیه با کاما — cursor در انتها قرار می‌گیرد
        _hallControllers[i].text = _fmt(halls[i].chickCount);
        // cursor را به انتها ببر
        _hallControllers[i].selection = TextSelection.collapsed(
          offset: _hallControllers[i].text.length,
        );
      }

      setState(() => _isLoadingHalls = false);
    } catch (e) {
      if (mounted) setState(() => _isLoadingHalls = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _chickCountController.dispose();
    _dateController.dispose();
    _hallCountController.dispose();
    for (var c in _hallControllers) c.dispose();
    super.dispose();
  }

  void _applyHallCount() {
    final raw   = _hallCountController.text.trim();
    final count = int.tryParse(raw);

    if (count == null || count < 1) {
      setState(() => _hallCountError = 'عدد معتبر وارد کنید (حداقل ۱)');
      return;
    }
    if (count > 999) {
      setState(
          () => _hallCountError = 'تعداد سالن نمی‌تواند بیشتر از ۹۹۹ باشد');
      return;
    }

    if (_isEditing && widget.cycle!.isMultiHall) {
      final current = widget.cycle!.hallCount;
      if (count < current) {
        setState(() =>
            _hallCountError =
                'نمی‌توانید تعداد سالن را کمتر از $current کنید');
        return;
      }
    }

    setState(() {
      _hallCountError = null;
      _hallCount      = count;

      while (_hallControllers.length < count) {
        _hallControllers.add(TextEditingController());
        _existingHallIds.add(null);
      }
      while (_hallControllers.length > count) {
        _hallControllers.last.dispose();
        _hallControllers.removeLast();
        if (_existingHallIds.isNotEmpty) _existingHallIds.removeLast();
      }
    });
  }

  void _distributeEvenly() {
    final total = _parseFormatted(_chickCountController.text);
    if (total <= 0 || _hallCount <= 1) return;

    final base      = total ~/ _hallCount;
    final remainder = total % _hallCount;

    setState(() {
      for (int i = 0; i < _hallCount; i++) {
        final val = base + (i < remainder ? 1 : 0);
        _hallControllers[i].text = _fmt(val);
        _hallControllers[i].selection = TextSelection.collapsed(
          offset: _hallControllers[i].text.length,
        );
      }
    });
  }

  int get _hallSum {
    int sum = 0;
    for (var c in _hallControllers) {
      sum += _parseFormatted(c.text);
    }
    return sum;
  }

  int get _totalChicks => _parseFormatted(_chickCountController.text);

  Future<void> _saveForm() async {
    setState(() {
      _dateError      = null;
      _hallCountError = null;
    });

    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    final hallCountRaw = int.tryParse(_hallCountController.text.trim());
    if (hallCountRaw == null || hallCountRaw < 1 || hallCountRaw > 999) {
      setState(
          () => _hallCountError = 'تعداد سالن باید بین ۱ تا ۹۹۹ باشد');
      return;
    }

    if (_hallCount > 1 && _hallSum != _totalChicks) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'جمع سالن‌ها (${_fmt(_hallSum)}) باید برابر کل جوجه‌ها (${_fmt(_totalChicks)}) باشد'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final parts       = _dateController.text.split('/');
      final startJalali = Jalali(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final newStartDate = startJalali.toDateTime();
      final startDateStr = _dateController.text.replaceAll('/', '-');

      if (_isEditing) {
        final reports = await DatabaseHelper.instance
            .getAllReportsForCycle(widget.cycle!.id!);
        if (reports.isNotEmpty) {
          final sorted = List<DailyReport>.from(reports)
            ..sort((a, b) => DateTime.parse(a.reportDate)
                .compareTo(DateTime.parse(b.reportDate)));
          final firstReportDate =
              DateTime.parse(sorted.first.reportDate);
          if (newStartDate.isAfter(firstReportDate)) {
            if (mounted) {
              setState(() {
                _dateError =
                    'نمی‌توانید تاریخ شروع را به بعد از اولین گزارش \n'
                    '\t(${sorted.first.formattedReportDate}) تغییر دهید.';
              });
            }
            return;
          }
        }

        final wasMultiHall = widget.cycle!.isMultiHall;
        final wasHallCount = widget.cycle!.hallCount;

        final updated = widget.cycle!.copyWith(
          name:       _nameController.text.trim(),
          chickCount: _totalChicks,
          startDate:  startDateStr,
          hallCount:  _hallCount,
        );
        await DatabaseHelper.instance.updateCycle(updated);

        if (_hallCount > 1) {
          if (!wasMultiHall) {
            for (int i = 0; i < _hallCount; i++) {
              final hall = BreedingCycle(
                name:          'سالن ${i + 1}',
                startDate:     startDateStr,
                chickCount:    _parseFormatted(_hallControllers[i].text),
                hallNumber:    i + 1,
                hallCount:     1,
                parentCycleId: widget.cycle!.id,
              );
              await DatabaseHelper.instance.insertCycle(hall);
            }
          } else {
            // آپدیت سالن‌های موجود
            for (int i = 0; i < wasHallCount && i < _hallCount; i++) {
              final hallId = i < _existingHallIds.length
                  ? _existingHallIds[i]
                  : null;
              if (hallId != null) {
                final existingHall =
                    await DatabaseHelper.instance.getCycleById(hallId);
                if (existingHall != null) {
                  await DatabaseHelper.instance.updateCycle(
                    existingHall.copyWith(
                      chickCount: _parseFormatted(_hallControllers[i].text),
                      startDate: startDateStr,
                    ),
                  );
                }
              }
            }
            // اضافه کردن سالن‌های جدید
            for (int i = wasHallCount; i < _hallCount; i++) {
              final hall = BreedingCycle(
                name:          'سالن ${i + 1}',
                startDate:     startDateStr,
                chickCount:    _parseFormatted(_hallControllers[i].text),
                hallNumber:    i + 1,
                hallCount:     1,
                parentCycleId: widget.cycle!.id,
              );
              await DatabaseHelper.instance.insertCycle(hall);
            }
          }
        }
      } else {
        final parent = BreedingCycle(
          name:       _nameController.text.trim(),
          chickCount: _totalChicks,
          startDate:  startDateStr,
          hallCount:  _hallCount,
        );

        if (_hallCount == 1) {
          await DatabaseHelper.instance.insertCycle(parent);
        } else {
          final halls = List.generate(
            _hallCount,
            (i) => BreedingCycle(
              name:          'سالن ${i + 1}',
              startDate:     startDateStr,
              chickCount:    _parseFormatted(_hallControllers[i].text),
              hallNumber:    i + 1,
              hallCount:     1,
              parentCycleId: null,
            ),
          );
          await DatabaseHelper.instance.insertCycleWithHalls(parent, halls);
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطا در ذخیره‌سازی: $e'),
          backgroundColor: Colors.red,
        ));
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
      final parts  = value.split('/');
      final year   = int.parse(parts[0]);
      final month  = int.parse(parts[1]);
      final day    = int.parse(parts[2]);
      final jalali = Jalali(year, month, day);
      if (year < 1300 || year > 1500) {
        return 'سال باید بین 1300 تا 1500 باشد \n(مثال: 1404/01/01)';
      }
      if (month < 1 || month > 12) {
        return 'ماه باید بین 01 تا 12 باشد \n(مثال: 1404/01/01)';
      }
      if (day < 1 || day > jalali.monthLength) {
        return 'روز باید بین 01 تا '
            '${jalali.monthLength.toString().padLeft(2, '0')} '
            '\nباشد برای ماه $month';
      }
      return null;
    } catch (e) {
      return 'تاریخ وارد شده معتبر نیست (مثال: 1404/01/01)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor  = const Color.fromARGB(255, 17, 92, 67);
    final wasMultiHall  = _isEditing && widget.cycle!.isMultiHall;
    final existingCount = wasMultiHall ? widget.cycle!.hallCount : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ویرایش دوره' : 'افزودن دوره جدید'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                const Color.fromARGB(255, 11, 104, 94),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoadingHalls
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildCard(
                      primaryColor: primaryColor,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'نام دوره',
                          hintText: 'مثال: فروردین ۱۴۰۴',
                          hintStyle: const TextStyle(
                              color: Color.fromARGB(106, 53, 71, 104)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: primaryColor.withOpacity(0.3)),
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'لطفاً نام دوره را وارد کنید.'
                                : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCard(
                      primaryColor: primaryColor,
                      child: NumericTextFormField(
                        controller: _chickCountController,
                        decoration: InputDecoration(
                          labelText: 'تعداد جوجه',
                          hintText: 'مثال: 30,000',
                          hintStyle: const TextStyle(
                              color: Color.fromARGB(106, 53, 71, 104)),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: primaryColor.withOpacity(0.3)),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.isEmpty)
                            return 'لطفاً تعداد را وارد کنید.';
                          final n = _parseFormatted(v);
                          if (n <= 0)
                            return 'لطفاً یک عدد معتبر وارد کنید.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCard(
                      primaryColor: primaryColor,
                      child: TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'تاریخ شروع',
                          hintText: 'مثال: 1404/01/01',
                          helperText:
                              'تاریخ را به صورت سال/ماه/روز\n (مثل 1404/01/01) وارد کنید\n (اسلش‌ها به صورت خودکار وارد می‌شوند)',
                          hintStyle: const TextStyle(
                              color: Color.fromARGB(106, 53, 71, 104)),
                          errorText: _dateError,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: primaryColor.withOpacity(0.3)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.red.withOpacity(0.7),
                                width: 2),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.red.withOpacity(0.7),
                                width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.left,
                        inputFormatters: [_dateMaskFormatter],
                        style: const TextStyle(
                            fontFamily: 'Vazir', fontSize: 16),
                        validator: _validateShamsiDate,
                        onTap: () {
                          _dateController.selection =
                              TextSelection.fromPosition(
                            TextPosition(
                                offset: _dateController.text.length),
                          );
                        },
                        onChanged: (v) {
                          if (_dateError != null)
                            setState(() => _dateError = null);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildCard(
                      primaryColor: primaryColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      size: 16,
                                      color: Colors.blue.shade700),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      wasMultiHall
                                          ? 'می‌توانید تعداد جوجه هر سالن را ویرایش کنید یا سالن جدید اضافه کنید'
                                          : 'در صورت نیاز تعداد سالن را تغییر دهید',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _hallCountController,
                                  decoration: InputDecoration(
                                    labelText: 'تعداد سالن',
                                    hintText: 'مثال: 1',
                                    helperText: 'بین ۱ تا 10',
                                    errorText: _hallCountError,
                                    suffixText: 'سالن',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: primaryColor
                                              .withOpacity(0.3)),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color:
                                              Colors.red.withOpacity(0.7),
                                          width: 2),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onChanged: (_) {
                                    if (_hallCountError != null)
                                      setState(
                                          () => _hallCountError = null);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: ElevatedButton(
                                  onPressed: _applyHallCount,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                  child: const Text('اعمال'),
                                ),
                              ),
                            ],
                          ),

                          if (_hallCount > 1) ...[
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'تعداد جوجه هر سالن:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor),
                                ),
                                TextButton.icon(
                                  onPressed: _distributeEvenly,
                                  icon: const Icon(Icons.auto_fix_high,
                                      size: 18),
                                  label: const Text('تقسیم مساوی'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            ...List.generate(_hallCount, (i) {
                              final isExisting =
                                  _isEditing && i < existingCount;
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 10),
                                child: TextFormField(
                                  controller: _hallControllers[i],
                                  // ── cursor را در ابتدای tap به انتها ببر ──
                                  onTap: () {
                                    final ctrl = _hallControllers[i];
                                    ctrl.selection =
                                        TextSelection.collapsed(
                                      offset: ctrl.text.length,
                                    );
                                  },
                                  decoration: InputDecoration(
                                    labelText: isExisting
                                        ? 'سالن ${i + 1} (موجود)'
                                        : 'سالن ${i + 1} (جدید)',
                                    border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: isExisting
                                            ? Colors.orange.shade400
                                            : primaryColor
                                                .withOpacity(0.3),
                                        width: isExisting ? 1.5 : 1.0,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: isExisting
                                            ? Colors.orange.shade600
                                            : primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    suffixText: 'قطعه',
                                    prefixIcon: isExisting
                                        ? Icon(Icons.edit,
                                            size: 16,
                                            color:
                                                Colors.orange.shade500)
                                        : Icon(
                                            Icons.add_circle_outline,
                                            size: 16,
                                            color: primaryColor
                                                .withOpacity(0.6)),
                                    helperText: isExisting
                                        ? 'ویرایش تعداد جوجه سالن موجود'
                                        : 'سالن جدید',
                                    helperStyle: TextStyle(
                                      fontSize: 11,
                                      color: isExisting
                                          ? Colors.orange.shade600
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  // ── formatter کاما با cursor درست ──
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _thousandsFormatter,
                                  ],
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'تعداد جوجه سالن ${i + 1} الزامی';
                                    if (_parseFormatted(v) <= 0)
                                      return 'عدد معتبر وارد کنید';
                                    return null;
                                  },
                                ),
                              );
                            }),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _hallSum == _totalChicks
                                    ? Colors.green.shade50
                                    : Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _hallSum == _totalChicks
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _hallSum == _totalChicks
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color: _hallSum == _totalChicks
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'مجموع: ${_fmt(_hallSum)} از ${_fmt(_totalChicks)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _hallSum == _totalChicks
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isEditing
                                  ? 'ذخیره تغییرات'
                                  : 'ذخیره دوره',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCard(
      {required Color primaryColor, required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      color: const Color.fromARGB(255, 240, 248, 245),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const SizedBox(height: 4), child],
        ),
      ),
    );
  }
}