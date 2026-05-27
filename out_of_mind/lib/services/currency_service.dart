import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CurrencyService {
  static const _key = 'currency_symbol';
  static String _symbol = '\$';

  static String get symbol => _symbol;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _symbol = prefs.getString(_key) ?? '\$';
  }

  static Future<void> save(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, symbol);
    _symbol = symbol;
  }

  static Future<bool> isSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key);
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
