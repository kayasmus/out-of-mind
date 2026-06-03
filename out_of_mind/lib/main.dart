import 'package:flutter/material.dart';
import 'package:out_of_mind/screens/currency_selection_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/currency_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db/database_helper.dart';
import 'models/purchase.dart';
import 'constants/mood_emojis.dart';

Future<void> _sendWeeklyInsightIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  final lastSent = prefs.getString('last_insight_date') ?? '';
  final today = DateTime.now().toString().substring(0, 10);

  if (lastSent == today) return;

  final purchases = await DatabaseHelper.instance.getPurchases();
  if (purchases.isEmpty) return;

  final Map<String, double> moodTotals = {};
  for (final p in purchases) {
    moodTotals[p.mood] = (moodTotals[p.mood] ?? 0) + (p.amount ?? 0);
  }

  final topMood = moodTotals.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;

  final emoji = moodEmojis[topMood] ?? '❓';
  await NotificationService.sendWeeklyInsight(topMood, emoji);
  await prefs.setString('last_insight_date', today);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Notification init failed: $e');
  }
  await CurrencyService.load();
  await _sendWeeklyInsightIfNeeded();

  final currencySet = await CurrencyService.isSet();

  runApp(MyApp(showCurrencySelection: !currencySet));
}

class MyApp extends StatelessWidget {
  final bool showCurrencySelection;
  const MyApp({super.key, required this.showCurrencySelection});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  title: 'Out of Mind',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
    useMaterial3: true,
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.purple,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  ),
  themeMode: ThemeMode.system,
  home: showCurrencySelection
      ? const CurrencySelectionScreen()
      : const HomeScreen(),
);
  }
}
