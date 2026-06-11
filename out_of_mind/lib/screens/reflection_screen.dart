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
  List<Purchase> _allPurchases = [];
  bool _loading = true;
  bool _monthView = false;
  int _weekOffset = 0;
  int _monthOffset = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance.getPurchases();
    setState(() {
      _allPurchases = all;
      _loading = false;
    });
  }

  DateTime get _weekStart {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    return start.subtract(Duration(days: _weekOffset * 7));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 7));

  DateTime get _monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month - _monthOffset, 1);
  }

  DateTime get _monthEnd {
    return DateTime(_monthStart.year, _monthStart.month + 1, 1);
  }

  List<Purchase> get _filtered {
    if (_monthView) {
      return _allPurchases.where((p) {
        final d = DateTime.tryParse(p.date);
        return d != null && d.isAfter(_monthStart) && d.isBefore(_monthEnd);
      }).toList();
    } else {
      return _allPurchases.where((p) {
        final d = DateTime.tryParse(p.date);
        return d != null && d.isAfter(_weekStart) && d.isBefore(_weekEnd);
      }).toList();
    }
  }

  Map<String, double> _byDay(List<Purchase> purchases) {
    final days = {
      'Mon': 0.0, 'Tue': 0.0, 'Wed': 0.0,
      'Thu': 0.0, 'Fri': 0.0, 'Sat': 0.0, 'Sun': 0.0,
    };
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (final p in purchases) {
      final date = DateTime.tryParse(p.date);
      if (date != null) {
        final day = names[date.weekday - 1];
        days[day] = (days[day] ?? 0) + p.amount;
      }
    }
    return days;
  }

  Map<String, double> _byWeek(List<Purchase> purchases) {
    final Map<String, double> weeks = {};
    for (final p in purchases) {
      final date = DateTime.tryParse(p.date);
      if (date != null) {
        final weekNum = ((date.day - 1) / 7).floor() + 1;
        final key = 'Week $weekNum';
        weeks[key] = (weeks[key] ?? 0) + p.amount;
      }
    }
    return weeks;
  }

  Map<String, Map<String, dynamic>> _byMood(List<Purchase> purchases) {
    final Map<String, Map<String, dynamic>> result = {};
    for (final p in purchases) {
      if (!result.containsKey(p.mood)) {
        result[p.mood] = {'days': <String>{}, 'total': 0.0};
      }
      final date = DateTime.tryParse(p.date);
      if (date != null) {
        (result[p.mood]!['days'] as Set).add(p.date.substring(0, 10));
      }
      result[p.mood]!['total'] =
          (result[p.mood]!['total'] as double) + p.amount;
    }
    return result;
  }

  Purchase? _highestPurchase(List<Purchase> purchases) {
    if (purchases.isEmpty) return null;
    return purchases.reduce((a, b) => a.amount > b.amount ? a : b);
  }

  String _topMood(Map<String, Map<String, dynamic>> moods) {
    if (moods.isEmpty) return '';
    return moods.entries
        .reduce((a, b) =>
            (a.value['total'] as double) > (b.value['total'] as double) ? a : b)
        .key;
  }

  MapEntry<String, double>? _lightestDay(Map<String, double> days) {
    final active = days.entries.where((e) => e.value > 0).toList();
    if (active.isEmpty) return null;
    return active.reduce((a, b) => a.value < b.value ? a : b);
  }

  String get _headerLabel {
    if (_monthView) {
      return '${_monthStart.year}-${_monthStart.month.toString().padLeft(2, '0')}';
    } else {
      return 'Week of ${_weekStart.toString().substring(0, 10)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final purchases = _filtered;
    final total = purchases.fold<double>(0, (s, p) => s + p.amount);
    final moods = _byMood(purchases);
    final highest = _highestPurchase(purchases);
    final topMood = _topMood(moods);
    final breakdown = _monthView ? _byWeek(purchases) : _byDay(purchases);
    final lightest = _lightestDay(
      _monthView
          ? breakdown
          : _byDay(purchases),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Reflection')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Toggle
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Week')),
                      ButtonSegment(value: true, label: Text('Month')),
                    ],
                    selected: {_monthView},
                    onSelectionChanged: (val) {
                      setState(() {
                        _monthView = val.first;
                        _weekOffset = 0;
                        _monthOffset = 0;
                      });
                    },
                  ),
                ),

                // Navigation arrows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() {
                        _monthView ? _monthOffset++ : _weekOffset++;
                      }),
                    ),
                    Text(_headerLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: (_monthView ? _monthOffset : _weekOffset) > 0
                          ? () => setState(() {
                                _monthView ? _monthOffset-- : _weekOffset--;
                              })
                          : null,
                    ),
                  ],
                ),

                // Content
                Expanded(
                  child: purchases.isEmpty
                      ? const Center(child: Text('No purchases for this period.'))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header card
                              Card(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_headerLabel,
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                      const SizedBox(height: 4),
                                      Text(CurrencyService.format(total),
                                          style: const TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold)),
                                      Text(_monthView
                                          ? 'total this month'
                                          : 'total this week'),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Breakdown
                              Text(_monthView
                                  ? 'Weekly Breakdown'
                                  : 'Daily Breakdown',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...breakdown.entries.map((e) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(e.key,
                                            style: TextStyle(
                                                color: e.value > 0
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
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
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                  : Colors.grey[400]),
                                        ),
                                      ],
                                    ),
                                  )),
                              const SizedBox(height: 16),

                              // Mood breakdown
                              const Text('By Mood',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ...moods.entries.map((e) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Text(
                                          moodEmojis[e.key] ?? '❓',
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

                              // Biggest purchase
                              if (highest != null) ...[
                                const Text('Biggest Purchase',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Card(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  child: ListTile(
                                    leading: Text(
                                        moodEmojis[highest.mood] ?? '❓',
                                        style:
                                            const TextStyle(fontSize: 28)),
                                    title: Text(
                                        CurrencyService.format(highest.amount),
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
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      '${moodEmojis[topMood]} You spent the most ${_monthView ? 'this month' : 'this week'} when feeling $topMood.',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 8),
                              if (lightest != null)
                                Card(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiaryContainer,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      '✅ Your lightest spending ${_monthView ? 'week' : 'day'} was ${lightest.key} with ${CurrencyService.format(lightest.value)}.',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}
