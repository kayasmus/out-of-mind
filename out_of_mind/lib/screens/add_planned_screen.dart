import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/planned_purchase.dart';
import '../constants/mood_emojis.dart';
import '../services/notification_service.dart';

class AddPlannedScreen extends StatefulWidget {
  const AddPlannedScreen({super.key});

  @override
  State<AddPlannedScreen> createState() => _AddPlannedScreenState();
}

class _AddPlannedScreenState extends State<AddPlannedScreen> {
  String? selectedMood;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  DateTime? reminderDate;

  Future<void> _pickReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => reminderDate = picked);
  }

 Future<void> _save() async {
  if (selectedMood == null || nameController.text.isEmpty) return;

  final planned = PlannedPurchase(
    name: nameController.text,
    amount: amountController.text.isNotEmpty
        ? double.tryParse(amountController.text.replaceAll(',', ''))
        : null,
    mood: selectedMood!,
    notes: notesController.text.isNotEmpty ? notesController.text : null,
    reminderDate: reminderDate?.toString(),
    createdAt: DateTime.now().toString(),
  );

  final id = await DatabaseHelper.instance.insertPlanned(planned);

  if (reminderDate != null) {
    await NotificationService.scheduleReminder(id, planned.name, reminderDate!);
  }

  if (mounted) Navigator.pop(context);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Want')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              selectedMood != null ? moodEmojis[selectedMood]! : '❓',
              style: const TextStyle(fontSize: 64),
            ),
            DropdownButton<String>(
              value: selectedMood,
              hint: const Text('How do you feel about this?'),
              onChanged: (v) => setState(() => selectedMood = v),
              items: moodEmojis.keys
                  .map((mood) => DropdownMenuItem(
                        value: mood,
                        child: Text('${moodEmojis[mood]} $mood'),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'What do you want?'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'How much? (optional)'),
            ),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Why do you want it?'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _pickReminderDate,
              child: Text(reminderDate == null
                  ? 'Set a reminder date (optional)'
                  : 'Reminder: ${reminderDate!.toString().substring(0, 10)}'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }
}
