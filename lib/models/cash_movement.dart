class CashMovement {
  final String id;
  final double amount;
  final bool isIncome; // true = encaissement, false = décaissement
  final String label;
  final DateTime createdAt;

  CashMovement({
    required this.id,
    required this.amount,
    required this.isIncome,
    required this.label,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'isIncome': isIncome,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CashMovement.fromJson(Map<String, dynamic> json) => CashMovement(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        isIncome: json['isIncome'] as bool,
        label: json['label'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
