class Purchase {
  final int? id;
  final String mood;
  final double? amount;
  final String location;
  final String date;
  final int impulse;

  Purchase({
    this.id,
    required this.mood,
    required this.amount,
    required this.location,
    required this.date,
    this.impulse = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood': mood,
      'amount': amount,
      'location': location,
      'date': date,
      'impulse': impulse,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      mood: map['mood'],
      amount: map['amount'],
      location: map['location'],
      date: map['date'],
      impulse: map['impulse'] ?? 3,
    );
  }
}
