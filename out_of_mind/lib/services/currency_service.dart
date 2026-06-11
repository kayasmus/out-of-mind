import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CurrencyService {
  static const _symbolKey = 'currency_symbol';
  static const _codeKey = 'currency_code';

  static String _symbol = '\$';
  static String _code = 'USD';

  static String get symbol => _symbol;
  static String get code => _code;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _symbol = prefs.getString(_symbolKey) ?? '\$';
    _code = prefs.getString(_codeKey) ?? 'USD';
  }

  static Future<void> save(String code, String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codeKey, code);
    await prefs.setString(_symbolKey, symbol);
    _code = code;
    _symbol = symbol;
  }

  static Future<bool> isSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_symbolKey);
  }

  static String format(double? amount) {
    if (amount == null) return '';
    final nf = NumberFormat('#,##0.00');
    return '$_symbol${nf.format(amount)}';
  }

  static double? parse(String text) {
    try {
      final nf = NumberFormat.decimalPattern();
      return nf.parse(text.trim()).toDouble();
    } catch (_) {
      return double.tryParse(text.replaceAll(',', '').trim());
    }
  }
}
