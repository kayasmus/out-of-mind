//item_name, amount, reminder_date, mood

class Location {
  final int? id;
  final String itemName;
  final double? amount;
  final String reminderDate;
  final String mood;


  Location({this.id, required this.mood, required this.amount, required this.itemName, required this.reminderDate});

  // Convert object to Map (for saving to DB)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood': mood,
      'itemName': itemName,
      'amount': amount,
      'reminderdate': reminderDate,
    };
  }

  // Create object from Map (for reading from DB)
  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'],
      mood: map['mood'],
      amount: map['amount'],
      itemName: map['itemName'],
      reminderDate: map['reminderDate'],
    );
  }
}
