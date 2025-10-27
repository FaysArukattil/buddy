class Transaction {
  final int? id; // null for new inserts, DB will autoincrement
  final double amount;
  final DateTime date;
  final String category;
  final String type; // 'income' or 'expense'
  final String? note;
  final int icon; // Material icon codePoint

  const Transaction({
    this.id,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    required this.icon,
    this.note,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'type': type,
      'note': note,
      'icon': icon,
    };
  }

  factory Transaction.fromMap(Map<String, Object?> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
      type: map['type'] as String,
      note: map['note'] as String?,
      icon: map['icon'] as int,
    );
  }

  Transaction copyWith({
    int? id,
    double? amount,
    DateTime? date,
    String? category,
    String? type,
    String? note,
    int? icon,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      note: note ?? this.note,
      icon: icon ?? this.icon,
    );
  }
}
