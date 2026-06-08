import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import 'add_purchase_screen.dart';
import 'locations_screen.dart';
import 'planned_screen.dart';
import '../services/currency_service.dart';
import 'settings_screen.dart';
import 'reflection_screen.dart';
import 'trends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Purchase> _purchases = [];

  Color _impulseColor(int value) {
  if (value <= 1) return Colors.green;
  if (value <= 2) return Colors.lightGreen;
  if (value <= 3) return Colors.orange;
  if (value <= 4) return Colors.deepOrange;
  return Colors.red;
}

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    final purchases = await DatabaseHelper.instance.getPurchases();
    setState(() {
      _purchases = purchases;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Home Screen"),
  actions: [
    IconButton(
  icon: const Icon(Icons.trending_up),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TrendsScreen()),
    );
  },
),
  IconButton(
    icon: const Icon(Icons.calendar_month),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReflectionScreen()),
      );
    },
  ),
  IconButton(
    icon: const Icon(Icons.settings),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    },
  ),
],
),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddPurchaseScreen()),
                  ).then((_) => _loadPurchases());
                },
                child: const Text("Add Purchase"),
              ),
            ),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PlannedScreen()),
                  );
                }, child: const Text("Planned"))),
                Expanded(child: ElevatedButton(onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LocationsScreen()),
                  );
                }, child: const Text("Locations"))),
              ],
            ),
            Expanded(
  child: _purchases.isEmpty
      ? const Center(child: Text('No purchases yet.'))
      : ListView.builder(
          itemCount: _purchases.length,
          itemBuilder: (context, index) {
            final p = _purchases[index];
            final emoji = {
              'Happy': '😊', 'Sad': '😢', 'Euphoric': '🤩',
              'Sleepy': '😴', 'Drunk': '🥴', 'Angry': '😠',
              'Lonely': '😔', 'Bored': '😑', 'Anxious': '😰',
            }[p.mood] ?? '❓';

            return Card(
  child: ListTile(
    leading: Text(emoji, style: const TextStyle(fontSize: 32)),
    title: Text(p.mood),
    subtitle: Text(p.date.length > 16 ? p.date.substring(0, 16) : p.date),
    trailing: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          CurrencyService.format(p.amount),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) => Icon(
            Icons.circle,
            size: 8,
            color: i < p.impulse
                ? _impulseColor(p.impulse)
                : Colors.grey[300],
          )),
        ),
      ],
    ),
  ),
);
          },
        ),
),
          ],
        ),
      ),
    );
  }
}
