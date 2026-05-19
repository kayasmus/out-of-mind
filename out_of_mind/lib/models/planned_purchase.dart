

class PlannedPurchase {
  final int? id;
  final String mood;
  final double? amount;
  final String location;
  final String date;


  PlannedPurchase({this.id, required this.mood, required this.amount, required this.location, required this.date});

  // Convert object to Map (for saving to DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood': mood,
      'amount': amount,
      'location': location,
      'date': date,
    };
  }

  // Create object from Map (for reading from DB)
  factory PlannedPurchase.fromMap(Map<String, dynamic> map) {
    return PlannedPurchase(
      id: map['id'],
      mood: map['mood'],
      amount: map['amount'],
      location: map['location'],
      date: map['date'],
    );
  }
}
