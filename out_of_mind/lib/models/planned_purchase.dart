class PlannedPurchase {
  int? id;
  String name;
  double? amount;
  String mood;
  String? notes;
  String? reminderDate;
  String createdAt;
  String status; // 'active', 'bought', 'won'
  String? wonAt;

  PlannedPurchase({
    this.id,
    required this.name,
    this.amount,
    required this.mood,
    this.notes,
    this.reminderDate,
    required this.createdAt,
    this.status = 'active',
    this.wonAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'mood': mood,
      'notes': notes,
      'reminder_date': reminderDate,
      'created_at': createdAt,
      'status': status,
      'won_at': wonAt,
    };
  }

  factory PlannedPurchase.fromMap(Map<String, dynamic> map) {
    return PlannedPurchase(
      id: map['id'],
      name: map['name'] ?? '',
      amount: map['amount'],
      mood: map['mood'] ?? '',
      notes: map['notes'],
      reminderDate: map['reminder_date'],
      createdAt: map['created_at'] ?? DateTime.now().toString(),
      status: map['status'] ?? 'active',
      wonAt: map['won_at'],
    );
  }
}
