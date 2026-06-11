import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import '../services/currency_service.dart';
import '../constants/mood_emojis.dart';

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key});

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  List<Purchase> _purchases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await DatabaseHelper.instance.getPurchases();
    setState(() {
      _purchases = all;
      _loading = false;
    });
  }

  // Group purchases by week, last 12 weeks
  List<Map<String, dynamic>> _weeklyData() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> weeks = [];

    for (int i = 11; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final end = start.add(const Duration(days: 7));

      final weekPurchases = _purchases.where((p) {
        final d = DateTime.tryParse(p.date);
        return d != null && d.isAfter(start) && d.isBefore(end);
      }).toList();

      final total = weekPurchases.fold<double>(
          0, (sum, p) => sum + p.amount);

      // Find peak mood (most frequent)
      String? topMood;
      if (weekPurchases.isNotEmpty) {
        final moodCount = <String, int>{};
        for (final p in weekPurchases) {
          moodCount[p.mood] = (moodCount[p.mood] ?? 0) + 1;
        }
        topMood = moodCount.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      weeks.add({
        'label': '${start.month}/${start.day}',
        'total': total,
        'mood': topMood,
        'purchases': weekPurchases,
      });
    }
    return weeks;
  }

  Map<String, double> _moodTotals() {
    final Map<String, double> totals = {};
    for (final p in _purchases) {
      totals[p.mood] = (totals[p.mood] ?? 0) + p.amount;
    }
    return totals;
  }

  double _averageImpulse() {
    if (_purchases.isEmpty) return 0;
    return _purchases.fold<double>(0, (sum, p) => sum + p.impulse) /
        _purchases.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final weeks = _weeklyData();
    final maxTotal = weeks.map((w) => w['total'] as double).reduce((a, b) => a > b ? a : b);
    final minTotal = weeks.where((w) => (w['total'] as double) > 0).isEmpty
        ? 0.0
        : weeks.where((w) => (w['total'] as double) > 0)
            .map((w) => w['total'] as double)
            .reduce((a, b) => a < b ? a : b);

    final peakIndex = weeks.indexWhere((w) => w['total'] == maxTotal);
    final lowIndex = weeks.indexWhere((w) => w['total'] == minTotal && (w['total'] as double) > 0);

    final spots = weeks.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value['total'] as double);
    }).toList();

    final moodTotals = _moodTotals();
    final sortedMoods = moodTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final avgImpulse = _averageImpulse();

    return Scaffold(
      appBar: AppBar(title: const Text('Spending Trends')),
      body: _purchases.isEmpty
          ? const Center(child: Text('No purchases yet.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chart
                  const Text('Weekly Spending',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) => Text(
                                CurrencyService.format(value),
                                style: const TextStyle(fontSize: 9),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                final i = value.toInt();
                                if (i < 0 || i >= weeks.length) return const SizedBox();
                                if (i % 2 != 0) return const SizedBox();
                                return Text(
                                  weeks[i]['label'] as String,
                                  style: const TextStyle(fontSize: 9),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.purple,
                            barWidth: 3,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) {
                                Color dotColor = Colors.purple;
                                if (index == peakIndex) dotColor = Colors.red;
                                if (index == lowIndex) dotColor = Colors.green;
                                return FlDotCirclePainter(
                                  radius: index == peakIndex || index == lowIndex ? 6 : 4,
                                  color: dotColor,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final i = spot.x.toInt();
                                final mood = weeks[i]['mood'] as String?;
                                final emoji = mood != null ? moodEmojis[mood] ?? '' : '';
                                return LineTooltipItem(
                                  '$emoji ${CurrencyService.format(spot.y)}\n${weeks[i]['label']}',
                                  const TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Peak and low labels
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (peakIndex >= 0 && weeks[peakIndex]['mood'] != null)
                        Row(children: [
                          Text(moodEmojis[weeks[peakIndex]['mood']] ?? '❓',
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 4),
                          Text('Peak: ${CurrencyService.format(maxTotal)}',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                        ]),
                      if (lowIndex >= 0 && weeks[lowIndex]['mood'] != null)
                        Row(children: [
                          Text(moodEmojis[weeks[lowIndex]['mood']] ?? '❓',
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 4),
                          Text('Low: ${CurrencyService.format(minTotal)}',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ]),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Average impulse
                  const Text('Average Impulse Score',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            avgImpulse.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: avgImpulse <= 2
                                  ? Colors.green
                                  : avgImpulse <= 3
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text('out of 5\naverage impulse\nacross all purchases'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mood totals
                  const Text('Spending by Mood',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...sortedMoods.map((e) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Text(moodEmojis[e.key] ?? '❓',
                              style: const TextStyle(fontSize: 28)),
                          title: Text(e.key),
                          trailing: Text(
                            CurrencyService.format(e.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      )),
                ],
              ),
            ),
    );
  }
}
