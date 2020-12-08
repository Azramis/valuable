import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/operations.dart';

class _ValuableWatchedInfos<T> {
  final VoidCallback callback;
  final List<ValuableWatcherSelector> selectors = <ValuableWatcherSelector>[];
  T previousWatchedValue;

  _ValuableWatchedInfos({this.callback, this.previousWatchedValue});
}

/// A mixin to provide extension of classes that might want to watch some valuable
/// and take action on possible changes
mixin ValuableWatcherMixin {
  final Map<Valuable, _ValuableWatchedInfos> _watched =
      <Valuable, _ValuableWatchedInfos>{};

  /// Watch a valuable, that eventually change
  @protected
  @mustCallSuper
  T watch<T>(Valuable<T> valuable,
      {ValuableContext valuableContext, ValuableWatcherSelector<T> selector}) {
    T result;
    if (valuable != null) {
      result = valuable.getValue(valuableContext ?? this.valuableContext);

      if (!_watched.containsKey(valuable)) {
        VoidCallback callback = () => _callValuableChange<T>(valuable);

        _watched.putIfAbsent(
            valuable, () => _ValuableWatchedInfos<T>(callback: callback));
        valuable.addListener(callback);
        valuable.listenDispose(() {
          unwatch(valuable);
        });
      }

      if (_watched.containsKey(valuable)) {
        _watched[valuable].previousWatchedValue =
            result; // Save value for future comparaison
        if (selector != null) {
          _watched[valuable].selectors.add(selector);
        }
      }
    }

    return result;
  }

  /// Remove listener on the valuable, that may change scope, or that about to be disposed
  /// Internal purpose
  @protected
  void unwatch(Valuable valuable) {
    if (_watched.containsKey(valuable)) {
      _removeValuableListener(valuable);
      _watched.remove(valuable);
    }
  }

  void _callValuableChange<T>(Valuable<T> valuable) {
    if (_watched.containsKey(valuable)) {
      if (_watched[valuable] != null) {
        bool selectOk;

        List<ValuableWatcherSelector> selectors = _watched[valuable].selectors;

        if (selectors?.isNotEmpty ?? false) {
          // If there are available selectors, we must test them until [selectOk]
          // is true, or we reach the end of the list

          selectOk = false;
          T previousWatchedValue = _watched[valuable].previousWatchedValue;
          for (ValuableWatcherSelector selector in selectors) {
            selectOk = selectOk ||
                (selector?.call(valuable, previousWatchedValue) ?? true);

            if (selectOk) {
              break;
            }
          }
        } else {
          selectOk = true;
        }

        // valuable change will be dispatched only if all conditions are resolved
        if (selectOk) {
          onValuableChange();
        }
      }
    }
  }

  @protected
  void onValuableChange();

  @protected
  ValuableContext get valuableContext => null;

  @protected
  void cleanWatched() {
    _watched.forEach((Valuable key, _ValuableWatchedInfos value) {
      _removeValuableListener(key);
    });
    _watched.clear();
  }

  void _removeValuableListener(Valuable valuable) {
    if (valuable != null &&
        _watched.containsKey(valuable) &&
        valuable.isMounted) {
      valuable.removeListener(_watched[valuable].callback);
    }
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
