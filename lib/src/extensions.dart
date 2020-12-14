import 'package:valuable/src/base.dart';
import 'package:valuable/src/operations.dart';

/// Extension to define operators for Valuable<bool>
extension BoolOperators on Valuable<bool> {
  /// Logical AND between Valuable/boolean value
  Valuable<bool> operator &(Valuable<bool> other) {
    return ValuableBoolGroup.and(<Valuable<bool>>[this, other]);
  }

  /// Logical OR between Valuable/boolean value
  Valuable<bool> operator |(Valuable<bool> other) {
    return ValuableBoolGroup.or(<Valuable<bool>>[this, other]);
  }

  /// Create a new Valuable<bool> that depends on the current, but with the negated value
  Valuable<bool> negation() {
    return Valuable<bool>.byValuer((watch, {valuableContext}) => !watch(this));
  }

  /// Get a new Valuable whom the value depends on the current Valuable value
  ///
  /// If current value is true then [value] is returned, else if [elseValue] is
  /// specified then it returned
  Valuable<Output> then<Output>(Valuable<Output> value,
      {Valuable<Output> elseValue}) {
    return ValuableIf<Output>(
        this,
        (ValuableWatcher<Output> watch, {ValuableContext valuableContext}) =>
            watch(value),
        elseCase: (elseValue != null)
            ? (ValuableWatcher<Output> watch,
                    {ValuableContext valuableContext}) =>
                watch(elseValue)
            : null);
  }

  /// Same as [then] function, but with direct value as parameters
  Valuable<Output> thenValue<Output>(Output value, {Output elseValue}) {
    return ValuableIf<Output>.value(this, value, elseValue: elseValue);
  }
}

/// Extension to define operators for Valuable<bool>
extension NumOperators<T extends num> on Valuable<T> {
  /// Addition operator.
  Valuable<num> operator +(Valuable<num> other) =>
      ValuableNumOperation.sum(this, other);

  /// Subtraction operator.
  Valuable<num> operator -(Valuable<num> other) =>
      ValuableNumOperation.substract(this, other);

  /// Multiplication operator.
  Valuable<num> operator *(Valuable<num> other) =>
      ValuableNumOperation.multiply(this, other);

  ///
  /// Euclidean modulo operator.
  ///
  /// Returns the remainder of the Euclidean division. The Euclidean division of
  /// two integers `a` and `b` yields two integers `q` and `r` such that
  /// `a == b * q + r` and `0 <= r < b.abs()`.
  ///
  /// The Euclidean division is only defined for integers, but can be easily
  /// extended to work with doubles. In that case `r` may have a non-integer
  /// value, but it still verifies `0 <= r < |b|`.
  ///
  /// The sign of the returned value `r` is always positive.
  ///
  /// See [remainder] for the remainder of the truncating division.
  ///
  Valuable<num> operator %(Valuable<num> other) =>
      ValuableNumOperation.modulo(this, other);

  /// Division operator.
  Valuable<double> operator /(Valuable<num> other) =>
      ValuableNumOperation.divide(this, other);

  ///
  /// Truncating division operator.
  ///
  /// If either operand is a [double] then the result of the truncating division
  /// `a ~/ b` is equivalent to `(a / b).truncate().toInt()`.
  ///
  /// If both operands are [int]s then `a ~/ b` performs the truncating
  /// integer division.
  ///
  Valuable<int> operator ~/(Valuable<num> other) =>
      ValuableNumOperation.truncDivide(this, other);

  /// Negate operator.
  Valuable<num> operator -() => ValuableNumOperation.negate(this);
}

extension StringOperator on Valuable<String> {
  /// Concate operator
  Valuable<String> operator +(Valuable<String> other) =>
      ValuableStringOperation.concate(this, other);
}
