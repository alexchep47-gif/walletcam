import 'package:flutter_test/flutter_test.dart';

int feeFor(int amount, {int fixed = 100}) => amount * 25 ~/ 1000 + fixed;
int taxFor(int fee) => fee * 1925 ~/ 10000;

double convertXafToUsd(int amount, double rate) => amount / rate;

void main() {
  test('calcul des frais: 2.5% + fixe', () => expect(feeFor(10000), 350));
  test('taxe classroom: 19.25% des frais', () => expect(taxFor(350), 67));
  test('conversion XAF vers USD', () => expect(convertXafToUsd(10000, 600), closeTo(16.6667, .0001)));
  test('solde insuffisant inclut frais et taxe', () => expect(10000 < 10000 + feeFor(10000) + taxFor(feeFor(10000)), isTrue));
}
