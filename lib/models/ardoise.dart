class Ardoise {
  final String id;
  final String clientName;
  final String clientPhone;
  final double totalAmount;
  final double remainingAmount;
  final DateTime dueDate;
  final String status; // 'DUE' | 'PAID'

  Ardoise({
    required this.id,
    required this.clientName,
    this.clientPhone = '',
    required this.totalAmount,
    required this.remainingAmount,
    required this.dueDate,
    required this.status,
  });

  Ardoise copyWith({
    String? id,
    String? clientName,
    String? clientPhone,
    double? totalAmount,
    double? remainingAmount,
    DateTime? dueDate,
    String? status,
  }) {
    return Ardoise(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'totalAmount': totalAmount,
        'remainingAmount': remainingAmount,
        'dueDate': dueDate.toIso8601String(),
        'status': status,
      };

  factory Ardoise.fromJson(Map<String, dynamic> json) => Ardoise(
        id: json['id'] as String,
        clientName: json['clientName'] as String,
        clientPhone: json['clientPhone'] as String? ?? '',
        totalAmount: (json['totalAmount'] as num).toDouble(),
        remainingAmount: (json['remainingAmount'] as num).toDouble(),
        dueDate: DateTime.parse(json['dueDate'] as String),
        status: json['status'] as String,
      );
}
