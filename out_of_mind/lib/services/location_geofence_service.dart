import 'package:flutter/material.dart';
import 'package:geofence_service/geofence_service.dart';
import '../db/database_helper.dart';
import '../models/tracked_location.dart';
import 'notification_service.dart';

/// Wraps [GeofenceService] to load saved locations from the DB and fire a
/// local notification whenever the user enters one.
class LocationGeofenceManager {
  LocationGeofenceManager._();
  static final LocationGeofenceManager instance = LocationGeofenceManager._();

  final _service = GeofenceService.instance.setup(
    interval: 5000,
    accuracy: 100,
    loiteringDelayMs: 60000,
    statusChangeDelayMs: 10000,
    useActivityRecognition: false,
    allowMockLocations: false,
    printDevLog: false,
    geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
  );

  bool _running = false;

  /// Call once from main() after [runApp]. Requests background location
  /// permission, loads saved locations, and starts monitoring.
  Future<void> initialize() async {
    final locations = await DatabaseHelper.instance.getTrackedLocations();
    if (locations.isEmpty) return;

    _service.addGeofenceStatusChangeListener(_onStatusChanged);
    _service.addStreamErrorListener(_onError);

    final geofences = _toGeofences(locations);
    try {
      await _service.start(geofences);
      _running = true;
    } catch (e) {
      debugPrint('GeofenceManager: start failed — $e');
    }
  }

  /// Call after the user adds or removes a tracked location so the active
  /// geofence list stays in sync with the database.
  Future<void> reload() async {
    final locations = await DatabaseHelper.instance.getTrackedLocations();
    final geofences = _toGeofences(locations);
    try {
      if (_running) {
        await _service.clearGeofenceList();
        for (final g in geofences) {
          await _service.addGeofence(g);
        }
      } else if (geofences.isNotEmpty) {
        _service.addGeofenceStatusChangeListener(_onStatusChanged);
        _service.addStreamErrorListener(_onError);
        await _service.start(geofences);
        _running = true;
      }
    } catch (e) {
      debugPrint('GeofenceManager: reload failed — $e');
    }
  }

  List<Geofence> _toGeofences(List<TrackedLocation> locations) {
    return locations
        .where((l) => l.id != null)
        .map((l) => Geofence(
              id: 'loc_${l.id}',
              latitude: l.latitude,
              longitude: l.longitude,
              radius: [
                GeofenceRadius(
                  id: 'radius_${l.id}',
                  length: l.radiusMeters,
                ),
              ],
            ))
        .toList();
  }

  Future<void> _onStatusChanged(
    Geofence geofence,
    GeofenceRadius geofenceRadius,
    GeofenceStatus geofenceStatus,
    Location location,
  ) async {
    if (geofenceStatus != GeofenceStatus.ENTER) return;

    // Look up the location name from the DB using the geofence id suffix.
    final idStr = geofence.id.replaceFirst('loc_', '');
    final id = int.tryParse(idStr);
    if (id == null) return;

    final locations = await DatabaseHelper.instance.getTrackedLocations();
    final match = locations.where((l) => l.id == id).firstOrNull;
    final name = match?.name ?? 'a saved location';

    await NotificationService.showLocationAlert(name);
  }

  void _onError(Object error) {
    debugPrint('GeofenceManager error: $error');
  }
}
