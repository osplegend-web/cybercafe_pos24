class Expense {
  final int? id;
  final String category;
  final double amount;
  final DateTime date;
  final String? note;

  Expense({
    this.id,
    required this.category,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category': category,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as int?,
        category: map['category'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
        note: map['note'] as String?,
      );
}
