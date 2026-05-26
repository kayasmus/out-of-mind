import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/planned_purchase.dart';
import 'add_planned_screen.dart';

const Map<String, String> moodEmojis = {
  'Happy': '😊', 'Sad': '😢', 'Euphoric': '🤩',
  'Sleepy': '😴', 'Drunk': '🥴', 'Angry': '😠',
  'Lonely': '😔', 'Bored': '😑', 'Anxious': '😰',
};

class PlannedScreen extends StatefulWidget {
  const PlannedScreen({super.key});

  @override
  State<PlannedScreen> createState() => _PlannedScreenState();
}

class _PlannedScreenState extends State<PlannedScreen> {
  List<PlannedPurchase> _planned = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final planned = await DatabaseHelper.instance.getPlanned();
    setState(() => _planned = planned);
  }

  String _daysAgo(String createdAt) {
    final created = DateTime.tryParse(createdAt);
    if (created == null) return '';
    final days = DateTime.now().difference(created).inDays;
    if (days == 0) return 'Added today';
    if (days == 1) return 'Added 1 day ago';
    return 'Added $days days ago';
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
              padding: const EdgeInsets.all(16),
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
                                    Text('\$${p.amount!.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_daysAgo(p.createdAt),
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                        if (p.notes != null && p.notes!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(p.notes!),
                        ],
                        if (p.reminderDate != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '🔔 Reminder: ${p.reminderDate!.substring(0, 10)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
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
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () async {
                                await DatabaseHelper.instance
                                    .deletePlanned(p.id!);
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
