import 'package:flutter_test/flutter_test.dart';
import 'package:valuable/valuable.dart';

void main() {
  group('subtraction API spelling', () {
    test('ValuableNumOperation provides subtract and substract alias', () {
      final scope = ValuableScope();
      addTearDown(scope.dispose);
      final Valuable<num> left = scope.value(8);
      final Valuable<num> right = scope.value(3);
      final subtractionOpe = left - right;
      // ignore: deprecated_member_use
      final subtractionLegacy = ValuableNumOperation.substract(left, right);
      final subtraction = ValuableNumOperation.subtract(left, right);
      addTearDown(subtractionOpe.dispose);
      addTearDown(subtractionLegacy.dispose);
      addTearDown(subtraction.dispose);

      expect(subtractionOpe.getValue(), 5);
      expect(subtraction.getValue(), 5);
      expect(subtractionLegacy.getValue(), 5);
    });

    test('ValuableScope provides subtract', () {
      final scope = ValuableScope();
      addTearDown(scope.dispose);

      final Valuable<num> left = scope.value(12);
      final Valuable<num> right = scope.value(4);

      expect(scope.subtract(left, right).getValue(), 8);
    });

    test('Stateful num operations provide subtract and substract alias', () {
      final StatefulValuable<num> value = StatefulValuable<num>(10);
      addTearDown(value.dispose);
      value.subtract(3);
      expect(value.getValue(), 7);

      // ignore: deprecated_member_use
      value.substract(2);
      expect(value.getValue(), 5);
    });
  });
}
