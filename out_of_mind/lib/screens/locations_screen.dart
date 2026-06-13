import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../db/database_helper.dart';
import '../models/tracked_location.dart';
import '../services/location_geofence_service.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<TrackedLocation> _locations = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final locs = await DatabaseHelper.instance.getTrackedLocations();
    if (mounted) setState(() => _locations = locs);
  }

  Future<void> _saveCurrentLocation() async {
    setState(() => _loading = true);

    // 1. Get current position
    Position? position;
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _showError('Location permission denied. Enable it in Settings.');
        setState(() => _loading = false);
        return;
      }
      position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      _showError('Could not get location: $e');
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = false);

    if (!mounted) return;

    // 2. Ask user to name the location
    final nameController = TextEditingController();
    final radiusOptions = [100.0, 200.0, 500.0];
    double selectedRadius = 200;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Save this location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${position!.latitude.toStringAsFixed(5)}, '
                '${position.longitude.toStringAsFixed(5)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. "The Mall", "Target")',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Alert radius',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: radiusOptions.map((r) {
                  final label = r < 1000
                      ? '${r.toInt()} m'
                      : '${(r / 1000).toStringAsFixed(1)} km';
                  return ChoiceChip(
                    label: Text(label),
                    selected: selectedRadius == r,
                    onSelected: (_) => setDialogState(() => selectedRadius = r),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || nameController.text.trim().isEmpty) return;

    final loc = TrackedLocation(
      name: nameController.text.trim(),
      latitude: position.latitude,
      longitude: position.longitude,
      radiusMeters: selectedRadius,
      createdAt: DateTime.now().toString(),
    );

    await DatabaseHelper.instance.insertTrackedLocation(loc);
    await LocationGeofenceManager.instance.reload();
    _load();
  }

  Future<void> _delete(TrackedLocation loc) async {
    await DatabaseHelper.instance.deleteTrackedLocation(loc.id!);
    await LocationGeofenceManager.instance.reload();
    _load();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _locations.isEmpty
            ? _emptyState()
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: _locations.length,
                  itemBuilder: (ctx, i) {
                    final loc = _locations[i];
                    final radius = loc.radiusMeters < 1000
                        ? '${loc.radiusMeters.toInt()} m'
                        : '${(loc.radiusMeters / 1000).toStringAsFixed(1)} km';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.location_on,
                            color: Colors.deepPurple, size: 32),
                        title: Text(loc.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Alert within $radius  •  '
                          '${loc.latitude.toStringAsFixed(4)}, '
                          '${loc.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          tooltip: 'Remove',
                          onPressed: () => _delete(loc),
                        ),
                      ),
                    );
                  },
                ),
              ),
        // FAB — positioned in Stack so it sits above the list
        Positioned(
          right: 16,
          bottom: 16,
          child: _loading
              ? const FloatingActionButton(
                  onPressed: null,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FloatingActionButton.extended(
                  onPressed: _saveCurrentLocation,
                  icon: const Icon(Icons.add_location_alt),
                  label: const Text('Save here'),
                ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No tracked locations yet.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Go to a place where you tend to impulse buy and tap "Save here". '
              'You\'ll get a reminder next time you show up.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saveCurrentLocation,
              icon: const Icon(Icons.add_location_alt),
              label: const Text('Save current location'),
            ),
          ],
        ),
      ),
    );
  }
}
