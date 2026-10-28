import 'package:flutter_test/flutter_test.dart';
import 'package:walletcam/models/ardoise.dart';

void main() {
  test('Ardoise model serializes correctly', () {
    final a = Ardoise(
      id: 'test-id',
      clientName: 'Jean Mbarga',
      clientPhone: '677000000',
      totalAmount: 25000,
      remainingAmount: 25000,
      dueDate: DateTime(2026, 11, 15),
      status: 'DUE',
    );

    final json = a.toJson();
    final restored = Ardoise.fromJson(json);

    expect(restored.clientName, 'Jean Mbarga');
    expect(restored.remainingAmount, 25000);
    expect(restored.status, 'DUE');
  });

  test('Ardoise copyWith works', () {
    final a = Ardoise(
      id: '1',
      clientName: 'Test',
      totalAmount: 10000,
      remainingAmount: 10000,
      dueDate: DateTime.now(),
      status: 'DUE',
    );

    final paid = a.copyWith(status: 'PAID', remainingAmount: 0);
    expect(paid.status, 'PAID');
    expect(paid.remainingAmount, 0);
    expect(paid.clientName, 'Test');
  });
}
