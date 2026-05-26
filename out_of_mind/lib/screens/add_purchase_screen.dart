import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<String> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return 'Location off';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return 'Permission denied';
    }
    if (permission == LocationPermission.deniedForever) return 'Permission denied';

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
    return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  }

  Future<void> _savePurchase() async {
    if (selectedMood == null || amountController.text.isEmpty) return;

    final location = await _getLocation();

    final purchase = Purchase(
      mood: selectedMood!,
      amount: double.parse(amountController.text),
      location: location,
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
              onChanged: (String? newValue) {
                setState(() {
                  selectedMood = newValue;
                });
              },
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
            ElevatedButton(onPressed: _savePurchase, child: const Text("Save")),
          ],
        ),
      ),
    );
  }
}
