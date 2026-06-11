import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import 'home_screen.dart';

const List<Map<String, String>> currencies = [
  {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'flag': '🇺🇸'},
  {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'flag': '🇪🇺'},
  {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'flag': '🇬🇧'},
  {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥', 'flag': '🇯🇵'},
  {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥', 'flag': '🇨🇳'},
  {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩', 'flag': '🇰🇷'},
  {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹', 'flag': '🇮🇳'},
  {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF', 'flag': '🇨🇭'},
  {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$', 'flag': '🇦🇺'},
  {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$', 'flag': '🇨🇦'},
  {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$', 'flag': '🇧🇷'},
  {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': 'MX\$', 'flag': '🇲🇽'},
  {'code': 'SEK', 'name': 'Swedish Krona', 'symbol': 'kr', 'flag': '🇸🇪'},
  {'code': 'NOK', 'name': 'Norwegian Krone', 'symbol': 'kr', 'flag': '🇳🇴'},
  {'code': 'DKK', 'name': 'Danish Krone', 'symbol': 'kr', 'flag': '🇩🇰'},
  {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$', 'flag': '🇸🇬'},
  {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': 'HK\$', 'flag': '🇭🇰'},
  {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': '₺', 'flag': '🇹🇷'},
  {'code': 'PLN', 'name': 'Polish Zloty', 'symbol': 'zł', 'flag': '🇵🇱'},
];

class CurrencySelectionScreen extends StatefulWidget {
  const CurrencySelectionScreen({super.key});

  @override
  State<CurrencySelectionScreen> createState() =>
      _CurrencySelectionScreenState();
}

class _CurrencySelectionScreenState extends State<CurrencySelectionScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedCode;

  final List<Map<String, dynamic>> _onboardingPages = [
    {
      'emoji': '🧠',
      'title': 'Welcome to Out of Mind',
      'body':
          'A budgeting app built for the ADHD brain.\nNo spreadsheets. No guilt. Just awareness.',
    },
    {
      'emoji': '😊',
      'title': 'Track how you feel when you spend',
      'body':
          'Every purchase comes with a mood.\nOver time, you\'ll see your triggers — the feelings that lead to spending.',
    },
    {
      'emoji': '🤩',
      'title': 'Park your big wants',
      'body':
          'That thing you\'re obsessing over?\nAdd it to Planned. Sit with it. See if you still want it in two weeks.',
    },
    {
      'emoji': '📈',
      'title': 'Reflect on your patterns',
      'body':
          'Weekly reflections and spending trends show you when and why you spend.\nKnowledge is the anchor.',
    },
  ];

  void _nextPage() {
    if (_currentPage < _onboardingPages.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _onboardingPages.length + 1; // +1 for currency page

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page dots
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.purple
                        : Colors.purple[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  // Onboarding cards
                  ..._onboardingPages.map((page) => Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(page['emoji'] as String,
                                style: const TextStyle(fontSize: 80)),
                            const SizedBox(height: 32),
                            Text(
                              page['title'] as String,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              page['body'] as String,
                              style: const TextStyle(
                                  fontSize: 16, height: 1.6),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )),

                  // Currency picker page
                  Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Text('💰',
                                style: TextStyle(fontSize: 60)),
                            SizedBox(height: 16),
                            Text(
                              'What currency do you spend in?',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: currencies.length,
                          itemBuilder: (context, index) {
                            final c = currencies[index];
                            final isSelected = c['code'] == _selectedCode;
                            return ListTile(
                              leading: Text(c['flag']!,
                                  style: const TextStyle(fontSize: 28)),
                              title: Text(c['name']!),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.purple)
                                  : Text(c['symbol']!,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                              onTap: () {
                                setState(() => _selectedCode = c['code']);
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _selectedCode == null
                                ? null
                                : () async {
                                    final c = currencies.firstWhere(
                                        (c) => c['code'] == _selectedCode);
                                    await CurrencyService.save(
                                        c['code']!, c['symbol']!);
                                    if (context.mounted) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const HomeScreen()),
                                      );
                                    }
                                  },
                            child: const Text("Let's go!"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Next button (only on onboarding pages)
            if (_currentPage < _onboardingPages.length)
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(_currentPage == _onboardingPages.length - 1
                        ? 'Get started'
                        : 'Next'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
