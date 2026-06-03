import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import '../services/currency_service.dart';
import '../constants/mood_emojis.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  List<Purchase> _weekPurchases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance.getPurchases();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final week = all.where((p) {
      final date = DateTime.tryParse(p.date);
      return date != null && date.isAfter(startOfWeek);
    }).toList();

    setState(() {
      _weekPurchases = week;
      _loading = false;
    });
  }

  Map<String, double> _byDay() {
    final days = {
      'Mon': 0.0, 'Tue': 0.0, 'Wed': 0.0,
      'Thu': 0.0, 'Fri': 0.0, 'Sat': 0.0, 'Sun': 0.0,
    };
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final p in _weekPurchases) {
      final date = DateTime.tryParse(p.date);
      if (date != null) {
        final day = names[date.weekday - 1];
        days[day] = (days[day] ?? 0) + (p.amount ?? 0);
      }
    }
    return days;
  }

  Map<String, Map<String, dynamic>> _byMood() {
    final Map<String, Map<String, dynamic>> result = {};
    for (final p in _weekPurchases) {
      if (!result.containsKey(p.mood)) {
        result[p.mood] = {'days': <String>{}, 'total': 0.0};
      }
      final date = DateTime.tryParse(p.date);
      if (date != null) {
        (result[p.mood]!['days'] as Set).add(p.date.substring(0, 10));
      }
      result[p.mood]!['total'] =
          (result[p.mood]!['total'] as double) + (p.amount ?? 0);
    }
    return result;
  }

  Purchase? _highestPurchase() {
    if (_weekPurchases.isEmpty) return null;
    return _weekPurchases.reduce(
        (a, b) => (a.amount ?? 0) > (b.amount ?? 0) ? a : b);
  }

  String _topMood() {
    final moods = _byMood();
    if (moods.isEmpty) return '';
    return moods.entries
        .reduce((a, b) =>
            (a.value['total'] as double) > (b.value['total'] as double) ? a : b)
        .key;
  }

  MapEntry<String, double>? _lightestDay() {
    final days = _byDay();
    final activeDays = days.entries.where((e) => e.value > 0).toList();
    if (activeDays.isEmpty) return null;
    return activeDays.reduce((a, b) => a.value < b.value ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final total = _weekPurchases.fold<double>(
        0, (sum, p) => sum + (p.amount ?? 0));
    final days = _byDay();
    final moods = _byMood();
    final highest = _highestPurchase();
    final topMood = _topMood();
    final lightest = _lightestDay();

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Reflection')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _weekPurchases.isEmpty
              ? const Center(child: Text('No purchases this week yet.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Card(
                        color: Colors.purple[50],
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Week of ${weekStart.toString().substring(0, 10)}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyService.format(total),
                                style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold),
                              ),
                              const Text('total this week'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Daily breakdown
                      const Text('Daily Breakdown',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...days.entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(e.key,
                                    style: TextStyle(
                                        color: e.value > 0
                                            ? Colors.black
                                            : Colors.grey[400])),
                                Text(
                                  e.value > 0
                                      ? CurrencyService.format(e.value)
                                      : '—',
                                  style: TextStyle(
                                      fontWeight: e.value > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: e.value > 0
                                          ? Colors.black
                                          : Colors.grey[400]),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),

                      // Mood breakdown
                      const Text('By Mood',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...moods.entries.map((e) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Text(moodEmojis[e.key] ?? '❓',
                                  style: const TextStyle(fontSize: 28)),
                              title: Text(e.key),
                              subtitle: Text(
                                  '${(e.value['days'] as Set).length} day${(e.value['days'] as Set).length == 1 ? '' : 's'}'),
                              trailing: Text(
                                CurrencyService.format(
                                    e.value['total'] as double),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          )),
                      const SizedBox(height: 16),

                      // Highest purchase
                      if (highest != null) ...[
                        const Text('Biggest Purchase',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Card(
                          color: Colors.orange[50],
                          child: ListTile(
                            leading: Text(moodEmojis[highest.mood] ?? '❓',
                                style: const TextStyle(fontSize: 28)),
                            title: Text(CurrencyService.format(highest.amount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            subtitle: Text(
                                '${highest.mood} · ${highest.date.substring(0, 10)}'),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Reflective messages
                      if (topMood.isNotEmpty)
                        Card(
                          color: Colors.purple[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '${moodEmojis[topMood]} You spent the most this week when feeling $topMood.',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      if (lightest != null)
                        Card(
                          color: Colors.green[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '✅ Your lightest spending day was ${lightest.key} with ${CurrencyService.format(lightest.value)}.',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
