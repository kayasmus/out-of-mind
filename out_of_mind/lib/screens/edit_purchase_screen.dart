import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import '../services/currency_service.dart';
import '../constants/mood_emojis.dart';

class EditPurchaseScreen extends StatefulWidget {
  final Purchase purchase;
  const EditPurchaseScreen({super.key, required this.purchase});

  @override
  State<EditPurchaseScreen> createState() => _EditPurchaseScreenState();
}

class _EditPurchaseScreenState extends State<EditPurchaseScreen> {
  late String? selectedMood;
  late TextEditingController nameController;
  late TextEditingController amountController;
  late String _tag;

  static const _tags = ['Need', 'Want', 'Impulse'];

  Color _tagColor(String tag) {
    switch (tag) {
      case 'Need':
        return Colors.blue;
      case 'Impulse':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  int _tagToImpulse(String tag) {
    switch (tag) {
      case 'Need':
        return 1;
      case 'Impulse':
        return 5;
      default:
        return 3;
    }
  }

  @override
  void initState() {
    super.initState();
    selectedMood = widget.purchase.mood;
    nameController =
        TextEditingController(text: widget.purchase.name ?? '');
    amountController =
        TextEditingController(text: widget.purchase.amount.toString());
    _tag = widget.purchase.tag;
  }

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (selectedMood == null || amountController.text.isEmpty) return;

    final updated = Purchase(
      id: widget.purchase.id,
      mood: selectedMood!,
      amount: CurrencyService.parse(amountController.text) ?? 0,
      location: widget.purchase.location,
      date: widget.purchase.date,
      impulse: _tagToImpulse(_tag),
      name: nameController.text.trim().isEmpty ? null : nameController.text.trim(),
      notes: widget.purchase.notes,
      tag: _tag,
    );

    await DatabaseHelper.instance.updatePurchase(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Purchase')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                selectedMood != null ? moodEmojis[selectedMood]! : '❓',
                style: const TextStyle(fontSize: 64),
              ),
            ),
            Center(
              child: DropdownButton<String>(
                value: selectedMood,
                hint: const Text('Select mood'),
                onChanged: (v) => setState(() => selectedMood = v),
                items: moodEmojis.keys
                    .map((mood) => DropdownMenuItem(
                          value: mood,
                          child: Text('${moodEmojis[mood]} $mood'),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'What did you buy?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Purchase type', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: _tags.map((tag) {
                final color = _tagColor(tag);
                final selected = _tag == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(tag),
                    selected: selected,
                    selectedColor: color.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: selected ? color : null,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: selected ? color : Colors.grey.withOpacity(0.3),
                    ),
                    onSelected: (_) => setState(() => _tag = tag),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
