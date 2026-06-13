import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import '../constants/mood_emojis.dart';
import '../services/currency_service.dart';
import 'package:geocoding/geocoding.dart';

class AddPurchaseScreen extends StatefulWidget {
  const AddPurchaseScreen({super.key});

  @override
  State<AddPurchaseScreen> createState() => _AddPurchaseScreenState();
}

class _AddPurchaseScreenState extends State<AddPurchaseScreen> {
  String? selectedMood;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String _tag = 'Want';
  bool _saving = false;

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

  // Maps tag to an impulse score for backwards-compatible analytics.
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
    );

    try {
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [place.street, place.locality]
            .where((s) => s != null && s.isNotEmpty)
            .toList();
        return parts.isNotEmpty
            ? parts.join(', ')
            : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (_) {
      return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }
    return 'Unknown';
  }

  Future<void> _save() async {
    if (_saving) return;
    if (selectedMood == null || amountController.text.isEmpty ||
        nameController.text.trim().isEmpty) return;
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
      impulse: _tagToImpulse(_tag),
      name: nameController.text.trim(),
      tag: _tag,
    );

    await DatabaseHelper.instance.insertPurchase(purchase);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Purchase')),
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
                hint: const Text('How do you feel?'),
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
                labelText: 'What did you buy? *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount *',
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
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
