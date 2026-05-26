import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import '../constants/mood_emojis.dart';


class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  String? selectedMood;
  final TextEditingController amountController = TextEditingController();

  Future<void> _savePurchase() async {
  if (selectedMood == null || amountController.text.isEmpty) {
    return;
  }

  final purchase = Purchase(
    mood: selectedMood!,
    amount: double.parse(amountController.text),
    location: 'Unknown',
    date: DateTime.now().toString(),
  );

  await DatabaseHelper.instance.insertPurchase(purchase);
  if (mounted) Navigator.pop(context);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Purchase")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              selectedMood != null ? moodEmojis[selectedMood]! : '❓',
              style:  const TextStyle(fontSize: 64),
            ),
            DropdownButton<String>(
          value: selectedMood,
          hint: const Text('Select mood'),
          onChanged: (String? newValue) {
            setState(() {
        selectedMood = newValue;
            });
          },
          items: moodEmojis.keys
          .map(
            (mood) => DropdownMenuItem(
              value: mood,
            child: Text('${moodEmojis[mood]} $mood'),
            )
          ).toList(),
        ),
        TextFormField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration:  const InputDecoration(labelText: 'Amount'),
        ),
        ElevatedButton(onPressed: _savePurchase, child: Text("Save"))
          ],
        ),
      )
    );
  }
}
