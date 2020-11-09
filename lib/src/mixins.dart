import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/operations.dart';

/// A mixin to provide extension of classes that might want to watch some valuable
/// and take action on possible changes
mixin ValuableWatcherMixin {
  final Map<Valuable, VoidCallback> _watched = <Valuable, VoidCallback>{};

  /// Watch a valuable, that eventually change
  @protected
  T watch<T>(Valuable<T> valuable, [ValuableContext context]) {
    if (valuable != null && !_watched.containsKey(valuable)) {
      VoidCallback callback = onValuableChange;

      _watched.putIfAbsent(valuable, () => callback);
      valuable.addListener(callback);
      valuable.listenDispose(() {
        unwatch(valuable);
      });
    }

    return valuable?.getValue(context ?? valuableContext);
  }

  /// Remove listener on the valuable, that may change scope, or that about to be disposed
  /// Internal purpose
  @protected
  void unwatch(Valuable valuable) {
    if (_watched.containsKey(valuable)) {
      //valuable.removeListener(_watched[valuable]); Not necessary until dispose has been done
      _watched.remove(valuable);
    }
  }

  @protected
  void onValuableChange();

  @protected
  ValuableContext get valuableContext => null;

  @protected
  void cleanWatched() {
    _watched.forEach((Valuable key, VoidCallback value) {
      key?.removeListener(value);
    });
    _watched.clear();
  }
}

mixin ValuableBoolOperators on Valuable<bool> {
  ValuableBool operator &(Valuable<bool> other) {
    return ValuableBoolGroup.and(<Valuable<bool>>[this, other]);
  }

  ValuableBool operator |(Valuable<bool> other) {
    return ValuableBoolGroup.or(<Valuable<bool>>[this, other]);
  }
}

mixin ValuableNumOperators on Valuable<num> {
  /// Addition operator.
  ValuableNum operator +(Valuable<num> other) =>
      ValuableNumOperation.sum(this, other);

  /// Subtraction operator.
  ValuableNum operator -(Valuable<num> other) =>
      ValuableNumOperation.substract(this, other);

  /// Multiplication operator.
  ValuableNum operator *(Valuable<num> other) =>
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
  ValuableNum operator %(Valuable<num> other) =>
      ValuableNumOperation.modulo(this, other);

  /// Division operator.
  ValuableNum operator /(Valuable<num> other) =>
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
  ValuableNum operator ~/(Valuable<num> other) =>
      ValuableNumOperation.truncDivide(this, other);

  /// Negate operator.
  ValuableNum operator -() => ValuableNumOperation.negate(this);
}

mixin ValuableStringOperator on Valuable<String> {
  /// Addition operator.
  ValuableString operator +(Valuable<String> other) =>
      ValuableStringOperation.concate(this, other);

  @override
  String toString() {
    return this.getValue();
  }
}
