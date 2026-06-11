import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import '../services/currency_service.dart';
import '../constants/mood_emojis.dart';
import '../constants/impulse_color.dart';

class EditPurchaseScreen extends StatefulWidget {
  final Purchase purchase;
  const EditPurchaseScreen({super.key, required this.purchase});

  @override
  State<EditPurchaseScreen> createState() => _EditPurchaseScreenState();
}

class _EditPurchaseScreenState extends State<EditPurchaseScreen> {
  late String? selectedMood;
  late TextEditingController amountController;
  late double _impulse;

  @override
  void initState() {
    super.initState();
    selectedMood = widget.purchase.mood;
    amountController = TextEditingController(
        text: widget.purchase.amount.toString());
    _impulse = widget.purchase.impulse.toDouble();
  }

  Future<void> _save() async {
    if (selectedMood == null || amountController.text.isEmpty) return;

    final updated = Purchase(
      id: widget.purchase.id,
      mood: selectedMood!,
      amount: CurrencyService.parse(amountController.text) ?? 0,
      location: widget.purchase.location,
      date: widget.purchase.date,
      impulse: _impulse.round(),
    );

    await DatabaseHelper.instance.updatePurchase(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Purchase')),
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
              hint: const Text('Select mood'),
              onChanged: (v) => setState(() => selectedMood = v),
              items: moodEmojis.keys
                  .map((mood) => DropdownMenuItem(
                        value: mood,
                        child: Text('${moodEmojis[mood]} $mood'),
                      ))
                  .toList(),
            ),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 16),
            Text('Impulse level: ${_impulse.round()}',
                style: TextStyle(color: impulseColor(_impulse))),
            Slider(
              value: _impulse,
              min: 1,
              max: 5,
              divisions: 4,
              activeColor: impulseColor(_impulse),
              onChanged: (value) => setState(() => _impulse = value),
            ),
            const SizedBox(height: 16),
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
