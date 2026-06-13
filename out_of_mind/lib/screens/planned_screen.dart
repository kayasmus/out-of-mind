import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/planned_purchase.dart';
import 'add_planned_screen.dart';
import '../constants/mood_emojis.dart';
import '../services/notification_service.dart';
import '../services/currency_service.dart';

class PlannedScreen extends StatefulWidget {
  const PlannedScreen({super.key});

  @override
  State<PlannedScreen> createState() => _PlannedScreenState();
}

class _PlannedScreenState extends State<PlannedScreen> {
  List<PlannedPurchase> _planned = [];
  double _spentThisWeek = 0;
  double _spentThisMonth = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _loadSpendingContext();
  }

  Future<void> _load() async {
    final planned = await DatabaseHelper.instance.getPlanned();
    setState(() => _planned = planned);
  }

  Future<void> _loadSpendingContext() async {
    final purchases = await DatabaseHelper.instance.getPurchases();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    double week = 0;
    double month = 0;

    for (final p in purchases) {
      final date = DateTime.tryParse(p.date);
      if (date == null) continue;
      if (date.isAfter(DateTime(weekStart.year, weekStart.month, weekStart.day))) {
        week += p.amount;
      }
      if (date.isAfter(monthStart)) {
        month += p.amount;
      }
    }

    setState(() {
      _spentThisWeek = week;
      _spentThisMonth = month;
    });
  }

  String _daysAgo(String createdAt) {
    final created = DateTime.tryParse(createdAt);
    if (created == null) return '';
    final days = DateTime.now().difference(created).inDays;
    if (days == 0) return 'Added today — fresh impulse!';
    if (days == 1) return 'Added 1 day ago';
    if (days <= 3) return 'Added $days days ago — still fresh';
    if (days <= 7) return 'Added $days days ago — still thinking?';
    if (days <= 14) return 'Added $days days ago — is this still relevant?';
    return 'Added $days days ago — do you still want this?';
  }

  void _showMoodPicker(PlannedPurchase p) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How do you feel about this now?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: moodEmojis.entries.map((entry) {
                return GestureDetector(
                  onTap: () async {
                    await DatabaseHelper.instance
                        .updatePlannedMood(p.id!, entry.key);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _load();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.value,
                          style: const TextStyle(fontSize: 36)),
                      Text(entry.key, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planned')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AddPlannedScreen()))
                .then((_) => _load()),
        child: const Icon(Icons.add),
      ),
      body: _planned.isEmpty
          ? const Center(child: Text('No wants yet.'))
          : ListView.builder(
              // Extra bottom padding so the FAB never covers the last card's
              // action buttons.
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: _planned.length,
              itemBuilder: (context, index) {
                final p = _planned[index];
                final emoji = moodEmojis[p.mood] ?? '❓';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(emoji,
                                style: const TextStyle(fontSize: 36)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  if (p.amount != null)
                                    Text(CurrencyService.format(p.amount),
                                        style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _daysAgo(p.createdAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: () {
                              final days = DateTime.now()
                                  .difference(DateTime.tryParse(p.createdAt) ?? DateTime.now())
                                  .inDays;
                              if (days == 0) return Colors.red[400];
                              if (days <= 3) return Colors.orange;
                              if (days <= 7) return Colors.amber;
                              return Colors.green;
                            }(),
                          ),
                        ),
                        if (p.notes != null && p.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(p.notes!),
                        ],
                        if (p.reminderDate != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            () {
                              final dt = DateTime.tryParse(p.reminderDate!);
                              if (dt == null) return '🔔 Reminder: ${p.reminderDate!.substring(0, 10)}';
                              final date = p.reminderDate!.substring(0, 10);
                              final hour = dt.hour.toString().padLeft(2, '0');
                              final minute = dt.minute.toString().padLeft(2, '0');
                              return '🔔 Reminder: $date at $hour:$minute';
                            }(),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('This week',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  Text(CurrencyService.format(_spentThisWeek),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ],
                              ),
                              Container(
                                  width: 1,
                                  height: 30,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant),
                              Column(
                                children: [
                                  const Text('This month',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  Text(CurrencyService.format(_spentThisMonth),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ],
                              ),
                              if (p.amount != null) ...[
                                Container(
                                    width: 1,
                                    height: 30,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outlineVariant),
                                Column(
                                  children: [
                                    const Text('This want',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey)),
                                    Text(
                                      CurrencyService.format(p.amount),
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: p.amount! > _spentThisWeek
                                              ? Colors.red
                                              : Colors.green),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showMoodPicker(p),
                                child: const Text('How do you feel now?'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Confirm: bought it
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.green),
                              tooltip: 'I bought it',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirm Purchase'),
                                    content: Text(
                                        'Move "${p.name}" to your purchases?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Not yet'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Yes, I bought it'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await DatabaseHelper.instance
                                      .confirmPlanned(p);
                                  await NotificationService.cancelReminder(
                                      p.id!);
                                  _load();
                                }
                              },
                            ),
                            // Resisted: it's a win!
                            IconButton(
                              icon: const Icon(Icons.emoji_events,
                                  color: Colors.amber),
                              tooltip: 'I resisted! 🏆',
                              onPressed: () async {
                                await DatabaseHelper.instance.markAsWon(p.id!);
                                await NotificationService.cancelReminder(
                                    p.id!);
                                _load();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('🏆 Win recorded! Great self-control.'),
                                    backgroundColor: Colors.amber,
                                  ),
                                );
                              },
                            ),
                            // Delete: just remove
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: 'Remove',
                              onPressed: () async {
                                await DatabaseHelper.instance
                                    .deletePlanned(p.id!);
                                await NotificationService.cancelReminder(
                                    p.id!);
                                _load();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
