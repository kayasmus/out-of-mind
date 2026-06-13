class TrackedLocation {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String createdAt;

  const TrackedLocation({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'created_at': createdAt,
      };

  factory TrackedLocation.fromMap(Map<String, dynamic> map) => TrackedLocation(
        id: map['id'],
        name: map['name'] ?? '',
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        radiusMeters: (map['radius_meters'] as num?)?.toDouble() ?? 200,
        createdAt: map['created_at'] ?? DateTime.now().toString(),
      );
}
