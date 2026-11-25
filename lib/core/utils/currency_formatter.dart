import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    
    String cleanText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanText.isEmpty) return newValue.copyWith(text: '');

    String formattedText = '';
    int count = 0;
    for (int i = cleanText.length - 1; i >= 0; i--) {
      formattedText = cleanText[i] + formattedText;
      count++;
      if (count == 3 && i > 0) {
        formattedText = '.' + formattedText;
        count = 0;
      }
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class CurrencyUtils {
  static String formatMoney(dynamic amount) {
    if (amount == null) return '0';
    final num = double.tryParse(amount.toString()) ?? 0;
    return num.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}