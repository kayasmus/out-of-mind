import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import 'home_screen.dart';

const List<Map<String, String>> currencies = [
  {'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
  {'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
  {'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
  {'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
  {'name': 'Chinese Yuan', 'symbol': '¥', 'flag': '🇨🇳'},
  {'name': 'South Korean Won', 'symbol': '₩', 'flag': '🇰🇷'},
  {'name': 'Indian Rupee', 'symbol': '₹', 'flag': '🇮🇳'},
  {'name': 'Swiss Franc', 'symbol': 'CHF', 'flag': '🇨🇭'},
  {'name': 'Australian Dollar', 'symbol': 'A\$', 'flag': '🇦🇺'},
  {'name': 'Canadian Dollar', 'symbol': 'C\$', 'flag': '🇨🇦'},
  {'name': 'Brazilian Real', 'symbol': 'R\$', 'flag': '🇧🇷'},
  {'name': 'Mexican Peso', 'symbol': 'MX\$', 'flag': '🇲🇽'},
  {'name': 'Swedish Krona', 'symbol': 'kr', 'flag': '🇸🇪'},
  {'name': 'Norwegian Krone', 'symbol': 'kr', 'flag': '🇳🇴'},
  {'name': 'Danish Krone', 'symbol': 'kr', 'flag': '🇩🇰'},
  {'name': 'Singapore Dollar', 'symbol': 'S\$', 'flag': '🇸🇬'},
  {'name': 'Hong Kong Dollar', 'symbol': 'HK\$', 'flag': '🇭🇰'},
  {'name': 'Turkish Lira', 'symbol': '₺', 'flag': '🇹🇷'},
  {'name': 'Polish Zloty', 'symbol': 'zł', 'flag': '🇵🇱'},
];

class CurrencySelectionScreen extends StatelessWidget {
  const CurrencySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Welcome to\nOut of Mind',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'What currency do you spend in?',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final c = currencies[index];
                    return ListTile(
                      leading: Text(c['flag']!,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(c['name']!),
                      trailing: Text(c['symbol']!,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      onTap: () async {
                        await CurrencyService.save(c['symbol']!);
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const HomeScreen()),
                          );
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
