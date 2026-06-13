import 'package:flutter/material.dart';
import 'package:out_of_mind/screens/currency_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/planned_screen.dart';
import 'screens/reflection_screen.dart';
import 'screens/trends_screen.dart';
import 'services/notification_service.dart';
import 'services/currency_service.dart';
import 'services/location_geofence_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db/database_helper.dart';
import 'models/purchase.dart';
import 'constants/mood_emojis.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _openFromNotification(String? payload) {
  final nav = navigatorKey.currentState;
  if (nav == null || payload == null) return;
  switch (payload) {
    case NotificationService.payloadPlanned:
      nav.push(MaterialPageRoute(builder: (_) => const PlannedScreen()));
    case NotificationService.payloadReflection:
      nav.push(MaterialPageRoute(builder: (_) => const ReflectionScreen()));
    case NotificationService.payloadInsight:
      nav.push(MaterialPageRoute(builder: (_) => const TrendsScreen()));
  }
}

Future<void> _sendWeeklyInsightIfNeeded() async {
  final prefs = await SharedPreferences.getInstance();
  final lastSentStr = prefs.getString('last_insight_date');
  final lastSent = lastSentStr != null ? DateTime.tryParse(lastSentStr) : null;
  final now = DateTime.now();

  // Only send once per week.
  if (lastSent != null && now.difference(lastSent).inDays < 7) return;

  final purchases = await DatabaseHelper.instance.getPurchases();
  if (purchases.isEmpty) return;

  // Find mood with highest average impulse
  final Map<String, List<int>> moodImpulses = {};
  for (final p in purchases) {
    moodImpulses.putIfAbsent(p.mood, () => []).add(p.impulse);
  }

  final moodAvgImpulse = moodImpulses.map((mood, impulses) =>
      MapEntry(mood, impulses.reduce((a, b) => a + b) / impulses.length));

  final topImpulseMood = moodAvgImpulse.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;

  // Find mood with highest total spend
  final Map<String, double> moodTotals = {};
  for (final p in purchases) {
    moodTotals[p.mood] = (moodTotals[p.mood] ?? 0) + p.amount;
  }
  final topSpendMood = moodTotals.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;

  final emoji = moodEmojis[topImpulseMood] ?? '❓';
  final spendEmoji = moodEmojis[topSpendMood] ?? '❓';

  final message = topImpulseMood == topSpendMood
      ? 'You spend the most AND feel most impulsive when $topImpulseMood $emoji. Stay mindful!'
      : 'You feel most impulsive when $topImpulseMood $emoji, and spend most when $topSpendMood $spendEmoji.';

  await NotificationService.sendWeeklyInsight(topImpulseMood, message);
  await prefs.setString('last_insight_date', DateTime.now().toIso8601String());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.initialize(onTap: _openFromNotification);
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
  await CurrencyService.load();

  final currencySet = await CurrencyService.isSet();

  runApp(MyApp(showCurrencySelection: !currencySet));

  // If the app was cold-started by tapping a notification, route there once
  // the first frame is up.
  final launchPayload = await NotificationService.getLaunchPayload();
  if (launchPayload != null) {
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openFromNotification(launchPayload));
  }

  // Fire-and-forget: don't block startup on the insight computation.
  _sendWeeklyInsightIfNeeded().catchError(
      (Object e) => debugPrint('Weekly insight failed: $e'));

  // Start geofencing after the first frame so the navigator is ready.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    LocationGeofenceManager.instance.initialize().catchError(
        (Object e) => debugPrint('Geofence init failed: $e'));
  });
}

class MyApp extends StatelessWidget {
  final bool showCurrencySelection;
  const MyApp({super.key, required this.showCurrencySelection});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  navigatorKey: navigatorKey,
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
