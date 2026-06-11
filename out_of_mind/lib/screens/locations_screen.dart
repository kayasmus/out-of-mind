import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import '../services/currency_service.dart';
import '../constants/mood_emojis.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  Map<String, List<Purchase>> _byLocation = {};

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final purchases = await DatabaseHelper.instance.getPurchases();
    final Map<String, List<Purchase>> grouped = {};
    for (final p in purchases) {
      grouped.putIfAbsent(p.location, () => []).add(p);
    }
    setState(() {
      _byLocation = grouped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locations')),
      body: _byLocation.isEmpty
          ? const Center(child: Text('No purchases yet.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _byLocation.entries.map((entry) {
                final location = entry.key;
                final purchases = entry.value;
                final total = purchases.fold<double>(
                    0, (sum, p) => sum + p.amount);

                return Card(
                  child: ExpansionTile(
                    title: Text(location),
                    subtitle: Text(
                      '${purchases.length} purchase${purchases.length == 1 ? '' : 's'} · ${CurrencyService.format(total)} total',
                    ),
                    children: purchases.map((p) {
                      final emoji = moodEmojis[p.mood] ?? '❓';
                      return ListTile(
                        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
                        title: Text(p.mood),
                        subtitle: Text(p.date.length > 16
                            ? p.date.substring(0, 16)
                            : p.date),
                        trailing: Text(CurrencyService.format(p.amount)),
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
