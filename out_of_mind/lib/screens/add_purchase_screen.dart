import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import '../constants/mood_emojis.dart';
import '../services/currency_service.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/impulse_color.dart';

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  String? selectedMood;
  final TextEditingController amountController = TextEditingController();
  double _impulse = 3;
  bool _saving = false;

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
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.medium,
  ),
);

  try {
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      final parts = [place.street, place.locality]
          .where((s) => s != null && s.isNotEmpty)
          .toList();
      return parts.isNotEmpty ? parts.join(', ') :
          '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }
  } catch (_) {
    return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  }

  return 'Unknown';
}

  Future<void> _savePurchase() async {
    if (_saving) return;
    if (selectedMood == null || amountController.text.isEmpty) return;
    // The location fetch below can take seconds; without this guard a second
    // tap on Save inserts a duplicate purchase.
    setState(() => _saving = true);

    final location = await _getLocation().timeout(
    const Duration(seconds: 5),
    onTimeout: () => 'Location unavailable',
    );

    final purchase = Purchase(
      mood: selectedMood!,
      amount: CurrencyService.parse(amountController.text) ?? 0,
      location: location,
      date: DateTime.now().toString(),
      impulse: _impulse.round(),
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
Text('Impulse level: ${_impulse.round()}',
    style: TextStyle(color: impulseColor(_impulse))),
Slider(
  value: _impulse,
  min: 1,
  max: 5,
  divisions: 4,
  activeColor: impulseColor(_impulse),
  onChanged: (value) {
    setState(() {
      _impulse = value;
    });
  },
),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _savePurchase,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
