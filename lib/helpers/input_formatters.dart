// lib/helpers/input_formatters.dart

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('en_us');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // تمام کاراکترهای غیرمجاز را حذف کن (فقط اعداد و یک نقطه اعشار مجاز است)
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    
    // اگر بیش از یک نقطه اعشار وجود داشت، از تغییر جلوگیری کن و مقدار قبلی را برگردان
    if (cleanText.split('.').length > 2) {
      return oldValue;
    }
    
    if (cleanText.isEmpty) {
      return const TextEditingValue();
    }
    
    // اگر فقط یک نقطه در ابتدا وارد شد، آن را به "0." تبدیل کن
    if (cleanText == '.') {
      return newValue.copyWith(text: '0.', selection: const TextSelection.collapsed(offset: 2));
    }
    
    num? number = num.tryParse(cleanText);
    if (number == null) {
      return oldValue; // اگر تبدیل ناموفق بود، مقدار قبلی را برگردان
    }

    final String newText = _formatter.format(number);

    // اگر کاربر در حال تایپ بخش اعشاری است، کرسر را به درستی مدیریت کن
    if (cleanText.endsWith('.')) {
      return TextEditingValue(
        text: newText + '.',
        selection: TextSelection.collapsed(offset: newText.length + 1),
      );
    }

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}