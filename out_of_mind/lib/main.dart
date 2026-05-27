import 'package:flutter/material.dart';
import 'package:out_of_mind/screens/currency_selection_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/currency_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await NotificationService.initialize();
  } catch (e) {
    print('Notification init failed: $e');
  }
  await CurrencyService.load();

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
      home: showCurrencySelection
      ? const CurrencySelectionScreen()
      : const HomeScreen(),
    );
  }
}
