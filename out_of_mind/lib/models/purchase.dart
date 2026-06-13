class Purchase {
  final int? id;
  final String mood;
  final double amount;
  final String location;
  final String date;
  final int impulse;
  final String? name;
  final String? notes;
  final String tag; // 'Need', 'Want', 'Impulse'

  Purchase({
    this.id,
    required this.mood,
    required this.amount,
    required this.location,
    required this.date,
    this.impulse = 3,
    this.name,
    this.notes,
    this.tag = 'Want',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood': mood,
      'amount': amount,
      'location': location,
      'date': date,
      'impulse': impulse,
      'name': name,
      'notes': notes,
      'tag': tag,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      mood: map['mood'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      location: map['location'] ?? '',
      date: map['date'] ?? '',
      impulse: map['impulse'] ?? 3,
      name: map['name'],
      notes: map['notes'],
      tag: map['tag'] ?? 'Want',
    );
  }
}
