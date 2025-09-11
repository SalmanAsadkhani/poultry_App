// lib/widgets/numeric_text_form_field.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/input_formatters.dart';

class NumericTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final InputDecoration decoration;
  final FormFieldValidator<String>? validator;
  final TextAlign textAlign;
  final TextStyle? style;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autofocus;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool allowDecimal; // ✅ پارامتر جدید برای اجازه دادن به اعشار

  const NumericTextFormField({
    super.key,
    required this.controller,
    this.decoration = const InputDecoration(),
    this.validator,
    this.textAlign = TextAlign.right,
    this.style,
    this.enabled = true,
    this.onChanged,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textInputAction,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.autofocus = false,
    this.keyboardType,
    this.inputFormatters,
    this.allowDecimal = false, // ✅ پیش‌فرض: فقط اعداد صحیح
  });

  @override
  State<NumericTextFormField> createState() => _NumericTextFormFieldState();
}

class _NumericTextFormFieldState extends State<NumericTextFormField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _focusNode.hasFocus) {
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      textAlign: widget.textAlign,
      // ✅ کیبورد بر اساس اعشاری بودن یا نبودن تغییر می‌کند
      keyboardType: widget.keyboardType ?? (widget.allowDecimal 
        ? const TextInputType.numberWithOptions(decimal: true) 
        : TextInputType.number),
      decoration: widget.decoration,
      validator: widget.validator,
      style: widget.style,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofocus: widget.autofocus,
      
      inputFormatters: [
        // ✅ فیلتر ورودی بر اساس اعشاری بودن یا نبودن تغییر می‌کند
        FilteringTextInputFormatter.allow(RegExp(widget.allowDecimal ? r'[\d.]' : r'[\d]')),
        ThousandsSeparatorInputFormatter(),
        ...?widget.inputFormatters,
      ],
    );
  }
}