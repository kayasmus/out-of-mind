import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../screens/currency_selection_screen.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentSymbol = CurrencyService.symbol;
  int _reminderWeekday = 1;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _reminderSet = false;
  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _loadReminderSettings();
  }

  Future<void> _loadReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminderWeekday = prefs.getInt('reflection_weekday') ?? 1;
      _reminderTime = TimeOfDay(
        hour: prefs.getInt('reflection_hour') ?? 9,
        minute: prefs.getInt('reflection_minute') ?? 0,
      );
      _reminderSet = prefs.getBool('reflection_set') ?? false;
    });
  }

  Future<void> _saveReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reflection_weekday', _reminderWeekday);
    await prefs.setInt('reflection_hour', _reminderTime.hour);
    await prefs.setInt('reflection_minute', _reminderTime.minute);
    await prefs.setBool('reflection_set', true);
    await NotificationService.scheduleWeeklyReflection(_reminderWeekday, _reminderTime);
    setState(() => _reminderSet = true);
  }

  Future<void> _cancelReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reflection_set', false);
    await NotificationService.cancelWeeklyReflection();
    setState(() => _reminderSet = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment:
        CrossAxisAlignment.start, children:[
  const Text('Settings',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
  const SizedBox(height: 24),

  // Currency
  ListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Currency'),
    subtitle: Text('Current: $_currentSymbol'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select Currency',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final c = currencies[index];
                    final isSelected = c['symbol'] == _currentSymbol;
                    return ListTile(
                      leading: Text(c['flag']!,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(c['name']!),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle,
                              color: Colors.purple)
                          : Text(c['symbol']!,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                      onTap: () async {
                        await CurrencyService.save(c['symbol']!);
                        setState(() => _currentSymbol = c['symbol']!);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Changing currency applies to new purchases only.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
  const Divider(),

  // Weekly Reflection Reminder
  ListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Weekly Reflection Reminder'),
    subtitle: Text(_reminderSet
        ? '✅ ${_weekdays[_reminderWeekday - 1]} at ${_reminderTime.format(context)}'
        : 'Not set'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      showModalBottomSheet(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly Reflection Reminder',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Day: '),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _reminderWeekday,
                      items: List.generate(7, (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(_weekdays[i]),
                      )),
                      onChanged: (v) {
                        setModalState(() => _reminderWeekday = v!);
                        setState(() => _reminderWeekday = v!);
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Time: '),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _reminderTime,
                        );
                        if (picked != null) {
                          setModalState(() => _reminderTime = picked);
                          setState(() => _reminderTime = picked);
                        }
                      },
                      child: Text(_reminderTime.format(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _saveReminder();
                          Navigator.pop(context);
                        },
                        child: const Text('Set Reminder'),
                      ),
                    ),
                    if (_reminderSet) ...[
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () async {
                          await _cancelReminder();
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  ),
  const Divider(),
],
      ),
      ),
    );
  }
}
