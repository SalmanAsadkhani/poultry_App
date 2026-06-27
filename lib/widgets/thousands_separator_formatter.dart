import 'package:flutter/services.dart';

class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // فقط ارقام رو نگه می‌داریم
    final digitsOnly = newValue.text.replaceAll(',', '');

    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // بررسی اینکه فقط عدد باشه
    if (!RegExp(r'^\d+$').hasMatch(digitsOnly)) {
      return oldValue;
    }

    // فرمت با کاما
    final formatted = _addCommas(digitsOnly);

    // محاسبه موقعیت cursor
    // cursor باید بعد از جایی که کاربر تایپ کرد قرار بگیره
    final oldDigits = oldValue.text.replaceAll(',', '');
    final newDigits = newValue.text.replaceAll(',', '');

    // تعداد ارقام قبل از cursor در متن جدید
    final cursorPos = newValue.selection.end;
    final textBeforeCursor = newValue.text.substring(0, cursorPos.clamp(0, newValue.text.length));
    final digitsBeforeCursor = textBeforeCursor.replaceAll(',', '');

    // پیدا کردن موقعیت cursor در متن فرمت‌شده
    int newCursorPos = 0;
    int digitCount   = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (formatted[i] != ',') {
        digitCount++;
      }
      if (digitCount == digitsBeforeCursor.length) {
        newCursorPos = i + 1;
        break;
      }
    }

    // اگر cursor در انتها بود
    if (digitsBeforeCursor.length >= digitsOnly.length) {
      newCursorPos = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: newCursorPos.clamp(0, formatted.length),
      ),
    );
  }

  String _addCommas(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;
    for (int i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}