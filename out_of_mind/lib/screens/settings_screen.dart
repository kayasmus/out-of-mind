import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../screens/currency_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentSymbol = CurrencyService.symbol;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Currency',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Current: $_currentSymbol',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final c = currencies[index];
                final isSelected = c['symbol'] == _currentSymbol;
                return ListTile(
                  leading: Text(c['flag']!,
                      style: const TextStyle(fontSize: 28)),
                  title: Text(c['name']!),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.purple)
                      : Text(c['symbol']!,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                  onTap: () async {
                    await CurrencyService.save(c['symbol']!);
                    setState(() {
                      _currentSymbol = c['symbol']!;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Changing currency applies to new purchases only.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
