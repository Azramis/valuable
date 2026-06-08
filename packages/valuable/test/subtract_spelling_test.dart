import 'package:flutter_test/flutter_test.dart';
import 'package:valuable/valuable.dart';

void main() {
  group('subtraction API spelling', () {
    test('ValuableNumOperation provides subtract and substract alias', () {
      final Valuable<num> left = Valuable.value(8);
      final Valuable<num> right = Valuable.value(3);

      expect(ValuableNumOperation.subtract(left, right).getValue(), 5);
      expect(ValuableNumOperation.substract(left, right).getValue(), 5);
    });

    test('ValuableScope provides subtract', () {
      final ValuableScope scope = ValuableScope();
      final Valuable<num> left = scope.value(12);
      final Valuable<num> right = scope.value(4);

      expect(scope.subtract(left, right).getValue(), 8);

      scope.dispose();
    });

    test('Stateful num operations provide subtract and substract alias', () {
      final StatefulValuable<num> value = StatefulValuable<num>(10);

      value.subtract(3);
      expect(value.getValue(), 7);

      value.substract(2);
      expect(value.getValue(), 5);
    });
  });
}
