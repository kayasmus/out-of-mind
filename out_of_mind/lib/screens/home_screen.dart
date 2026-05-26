import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import 'add_purchase_screen.dart';
import 'locations_screen.dart';
import 'planned_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Purchase> _purchases = [];

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
      appBar: AppBar(title: const Text("Home Screen")),
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
                trailing: Text(
                  '¥${p.amount?.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
