import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import '../models/planned_purchase.dart';
import 'add_purchase_screen.dart';
import 'add_planned_screen.dart';
import 'settings_screen.dart';
import 'reflection_screen.dart';
import 'trends_screen.dart';
import 'edit_purchase_screen.dart';
import '../constants/mood_emojis.dart';
import '../services/currency_service.dart';
import '../services/notification_service.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Shell
// ═══════════════════════════════════════════════════════════════════════════════

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _plannedKey = GlobalKey<_PlannedTabState>();

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Out of Mind'),
        actions: [
          if (_tab == 0) ...[
            IconButton(
              icon: const Icon(Icons.trending_up),
              tooltip: 'Trends',
              onPressed: () => _push(const TrendsScreen()),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: 'Reflection',
              onPressed: () => _push(const ReflectionScreen()),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => _push(const SettingsScreen()),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _HomeTab(onLoad: () => setState(() {})),
          _PlannedTab(key: _plannedKey),
          const _WinsTab(),
        ],
      ),
      floatingActionButton: _tab == 1
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddPlannedScreen()),
              ).then((_) => _plannedKey.currentState?.load()),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Planned',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Wins',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Home tab — purchase list + total spend
// ═══════════════════════════════════════════════════════════════════════════════

class _HomeTab extends StatefulWidget {
  final VoidCallback? onLoad;
  const _HomeTab({this.onLoad});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<Purchase> _purchases = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final purchases = await DatabaseHelper.instance.getPurchases();
    if (mounted) setState(() => _purchases = purchases);
  }

  Future<void> _delete(int id) async {
    await DatabaseHelper.instance.deletePurchase(id);
    load();
  }

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

  @override
  Widget build(BuildContext context) {
    final total = _purchases.fold<double>(0, (sum, p) => sum + p.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Spend summary + add button ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total spent',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          CurrencyService.format(total),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPurchaseScreen()),
                ).then((_) => load()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // ── Purchase list ───────────────────────────────────────────────────
        Expanded(
          child: _purchases.isEmpty
              ? const Center(child: Text('No purchases yet.'))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
                    itemCount: _purchases.length,
                    itemBuilder: (context, index) {
                      final p = _purchases[index];
                      final emoji = moodEmojis[p.mood] ?? '❓';
                      final tagColor = _tagColor(p.tag);

                      return Dismissible(
                        key: Key(p.id.toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _delete(p.id!),
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => EditPurchaseScreen(purchase: p)),
                            ).then((_) => load()),
                            leading: Text(emoji,
                                style: const TextStyle(fontSize: 30)),
                            title: Text(
                              p.name ?? p.mood,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${p.mood}  •  ${p.date.length > 10 ? p.date.substring(0, 10) : p.date}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyService.format(p.amount),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: tagColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: tagColor.withOpacity(0.4)),
                                  ),
                                  child: Text(
                                    p.tag,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: tagColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Planned tab — wants list with mood, resisted, confirm, delete
// ═══════════════════════════════════════════════════════════════════════════════

class _PlannedTab extends StatefulWidget {
  const _PlannedTab({super.key});

  @override
  State<_PlannedTab> createState() => _PlannedTabState();
}

class _PlannedTabState extends State<_PlannedTab> {
  List<PlannedPurchase> _planned = [];
  double _spentThisWeek = 0;
  double _spentThisMonth = 0;

  @override
  void initState() {
    super.initState();
    load();
    _loadSpending();
  }

  Future<void> load() async {
    final planned = await DatabaseHelper.instance.getPlanned();
    if (mounted) setState(() => _planned = planned);
  }

  Future<void> _loadSpending() async {
    final purchases = await DatabaseHelper.instance.getPurchases();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);
    double week = 0, month = 0;
    for (final p in purchases) {
      final date = DateTime.tryParse(p.date);
      if (date == null) continue;
      if (date.isAfter(
          DateTime(weekStart.year, weekStart.month, weekStart.day))) {
        week += p.amount;
      }
      if (date.isAfter(monthStart)) month += p.amount;
    }
    if (mounted) setState(() { _spentThisWeek = week; _spentThisMonth = month; });
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
                    load();
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.value,
                          style: const TextStyle(fontSize: 36)),
                      Text(entry.key,
                          style: const TextStyle(fontSize: 11)),
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
    if (_planned.isEmpty) {
      return const Center(child: Text('No wants yet.'));
    }
    return RefreshIndicator(
      onRefresh: load,
      child: ListView.builder(
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
                  // ── Header row ─────────────────────────────────────────
                  Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 36)),
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
                  // ── Cooling-off label ──────────────────────────────────
                  Text(
                    _daysAgo(p.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: () {
                        final days = DateTime.now()
                            .difference(
                                DateTime.tryParse(p.createdAt) ??
                                    DateTime.now())
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
                        if (dt == null) {
                          return '🔔 Reminder: ${p.reminderDate!.substring(0, 10)}';
                        }
                        final date = p.reminderDate!.substring(0, 10);
                        final h = dt.hour.toString().padLeft(2, '0');
                        final m = dt.minute.toString().padLeft(2, '0');
                        return '🔔 Reminder: $date at $h:$m';
                      }(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // ── Spend context ──────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SpendCol('This week',
                            CurrencyService.format(_spentThisWeek)),
                        Container(
                            width: 1,
                            height: 30,
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant),
                        _SpendCol('This month',
                            CurrencyService.format(_spentThisMonth)),
                        if (p.amount != null) ...[
                          Container(
                              width: 1,
                              height: 30,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outlineVariant),
                          _SpendCol(
                            'This want',
                            CurrencyService.format(p.amount),
                            valueColor: p.amount! > _spentThisWeek
                                ? Colors.red
                                : Colors.green,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // ── Actions ────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showMoodPicker(p),
                          child: const Text('How do you feel now?'),
                        ),
                      ),
                      const SizedBox(width: 4),
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
                            await DatabaseHelper.instance.confirmPlanned(p);
                            await NotificationService.cancelReminder(p.id!);
                            load();
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
                          await NotificationService.cancelReminder(p.id!);
                          load();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('🏆 Win recorded! Great self-control.'),
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
                          await DatabaseHelper.instance.deletePlanned(p.id!);
                          await NotificationService.cancelReminder(p.id!);
                          load();
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

// Small helper for the spend context row
class _SpendCol extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SpendCol(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Wins tab — items the user successfully resisted
// ═══════════════════════════════════════════════════════════════════════════════

class _WinsTab extends StatefulWidget {
  const _WinsTab();

  @override
  State<_WinsTab> createState() => _WinsTabState();
}

class _WinsTabState extends State<_WinsTab> {
  List<PlannedPurchase> _wins = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final wins = await DatabaseHelper.instance.getWins();
    if (mounted) setState(() => _wins = wins);
  }

  @override
  Widget build(BuildContext context) {
    final totalSaved =
        _wins.fold<double>(0, (sum, w) => sum + (w.amount ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Summary header ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: Colors.amber.withOpacity(0.15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _wins.isEmpty
                            ? 'No wins yet'
                            : '${_wins.length} urge${_wins.length == 1 ? '' : 's'} resisted',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (totalSaved > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${CurrencyService.format(totalSaved)} saved',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                      if (_wins.isEmpty)
                        const Text(
                          'Resist a want to see it here!',
                          style: TextStyle(fontSize: 13),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // ── Wins list ───────────────────────────────────────────────────────
        Expanded(
          child: _wins.isEmpty
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _wins.length,
                    itemBuilder: (context, index) {
                      final w = _wins[index];
                      final emoji = moodEmojis[w.mood] ?? '❓';
                      final wonAt = w.wonAt != null
                          ? DateTime.tryParse(w.wonAt!)
                          : null;
                      final createdAt = DateTime.tryParse(w.createdAt);
                      final daysHeld =
                          (createdAt != null && wonAt != null)
                              ? wonAt.difference(createdAt).inDays
                              : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Text(emoji,
                              style: const TextStyle(fontSize: 32)),
                          title: Text(w.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (w.amount != null)
                                Text(CurrencyService.format(w.amount)),
                              if (daysHeld != null)
                                Text(
                                  daysHeld == 0
                                      ? 'Resisted same day 💪'
                                      : 'Held out for $daysHeld day${daysHeld == 1 ? '' : 's'} 💪',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.emoji_events,
                              color: Colors.amber),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
