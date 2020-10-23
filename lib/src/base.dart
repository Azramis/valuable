import 'package:flutter/material.dart';

/// Shortcut to get a valuable with the value true
Valuable<bool> boolTrue = ValuableBool(true);

/// Shortcut to get a valuable with the value false
Valuable<bool> boolFalse = ValuableBool(false);

/// Shortcut to get a valuable with the value of an empty string
Valuable<String> stringEmpty = ValuableString("");

/// Shortcut to get a valuable with the int value 0
Valuable<int> intZero = ValuableInt(0);

/// Shortcut to get a valuable with the double value 0.0
Valuable<double> doubleZero = ValuableDouble(0.0);

abstract class Valuable<T> extends ChangeNotifier {
  final ValueNotifier<bool> _isMounted;

  final Map<Valuable, VoidCallback> _removeListeners =
      <Valuable, VoidCallback>{};

  Valuable() : _isMounted = ValueNotifier(true);

  factory Valuable.value(T value) {
    return _Valuable<T>(value);
  }

  T getValue(BuildContext context);

  @protected
  V readValuable<V>(Valuable<V> valuable, BuildContext context) {
    VoidCallback listen = () {
      this.notifyListeners();
    };

    if (_removeListeners.containsKey(valuable) == false ||
        _removeListeners[valuable] == null) {
      VoidCallback remover = () {
        if (valuable?._isMounted?.value ?? false) {
          valuable.removeListener(listen);
        }
        _removeListeners.remove(valuable);
      };
      valuable?.listenDispose(remover);
      valuable?.addListener(listen);
      _removeListeners.update(valuable, (VoidCallback old) => remover,
          ifAbsent: () => remover);
    }

    return valuable?.getValue(context);
  }

  void listenDispose(VoidCallback onDispose) {
    _isMounted.addListener(onDispose);
  }

  @override
  void dispose() {
    _isMounted.value = false;
    _isMounted.dispose();
    List<VoidCallback> removers = _removeListeners.values.toList();
    removers.forEach((VoidCallback remover) => remover?.call());

    super.dispose();
  }

  Valuable _getCompare(dynamic other, _CompareOperator ope) {
    Valuable compare;

    if (other is T) {
      compare = Valuable.value(other);
    } else if (other is Valuable) {
      compare = other;
    } else {
      throw Error();
    }

    return ValuableCompare._(this, ope, compare);
  }

  ValuableBool operator >(Valuable<T> other) {
    return _getCompare(other, _CompareOperator.greater_than);
  }

  ValuableBool operator >=(Valuable<T> other) {
    return _getCompare(other, _CompareOperator.greater_or_equals);
  }

  ValuableBool operator <(Valuable<T> other) {
    return _getCompare(other, _CompareOperator.smaller_than);
  }

  ValuableBool operator <=(Valuable<T> other) {
    return _getCompare(other, _CompareOperator.smaller_or_equals);
  }

  ValuableBool equals(dynamic other) {
    return _getCompare(other, _CompareOperator.equals);
  }

  ValuableBool notEquals(dynamic other) {
    return _getCompare(other, _CompareOperator.different);
  }
}

class _Valuable<T> extends Valuable<T> {
  final T value;

  _Valuable(this.value) : super();

  T getValue(BuildContext context) => value;
}

class ValuableBool extends _Valuable<bool> with ValuableBoolOperators {
  ValuableBool(bool value) : super(value);
}

enum _BoolGroupType { and, or }

class ValuableBoolGroup extends ValuableBool {
  final _BoolGroupType type;
  final List<Valuable<bool>> constraints;

  ValuableBoolGroup._(this.type, this.constraints) : super(false);
  ValuableBoolGroup.and(List<Valuable<bool>> constraints)
      : this._(_BoolGroupType.and, constraints);
  ValuableBoolGroup.or(List<Valuable<bool>> constraints)
      : this._(_BoolGroupType.or, constraints);

  @override
  bool getValue(BuildContext context) {
    bool retour = type == _BoolGroupType.and;

    for (Valuable<bool> constraint in constraints) {
      if (type == _BoolGroupType.and) {
        retour = retour && readValuable(constraint, context);
        if (retour == false) {
          break;
        }
      } else {
        retour = retour || readValuable(constraint, context);
        if (retour == true) {
          break;
        }
      }
    }

    return retour;
  }
}

class ValuableString extends _Valuable<String> {
  ValuableString(String value) : super(value);
}

class _ValuableNum<T extends num> extends _Valuable<T> {
  _ValuableNum(T value) : super(value);
}

class ValuableInt extends _ValuableNum<int> {
  ValuableInt(int value) : super(value);
}

class ValuableDouble extends _ValuableNum<double> {
  ValuableDouble(double value) : super(value);
}

class StatefulValuable<T> extends Valuable<T> {
  T _state;

  StatefulValuable(T initialState)
      : _state = initialState,
        super();

  void setValue(T value) {
    if (_state != value) {
      _state = value;
      notifyListeners();
    }
  }

  T getValue(BuildContext context) => _state;
}

class StatefulValuableBool extends StatefulValuable<bool>
    with ValuableBoolOperators {
  StatefulValuableBool(bool initialValue) : super(initialValue);
}

typedef ValuableGetFutureResult<T, Res> = T Function(BuildContext, Res);
typedef ValuableGetFutureError<T> = T Function(
    BuildContext, Object, StackTrace);
typedef ValuableGetFutureLoading<T> = T Function(BuildContext);

class FutureValuable<T, Res> extends Valuable<T> {
  final Future<Res> _future;
  final ValuableGetFutureResult<T, Res> dataValue;
  final ValuableGetFutureLoading<T> noDataValue;
  final ValuableGetFutureError<T> errorValue;

  bool _isComplete;
  bool _isError;
  Res _resultValue;
  Object _error;
  StackTrace _stackTrace;

  FutureValuable(Future<Res> future,
      {@required this.dataValue,
      @required this.noDataValue,
      @required this.errorValue})
      : assert(future != null, "future should not be null"),
        _future = future,
        super() {
    _future.then((Res value) {
      _isComplete = true;
      _resultValue = value;
      notifyListeners();
    }, onError: (Object error, StackTrace stackTrace) {
      _error = error;
      _stackTrace = stackTrace;
      _isComplete = _isError = true;
      notifyListeners();
    });
  }

  /// Can be use only when [T] == [Res]
  FutureValuable.values(Future<Res> future, {T noDataValue, T errorValue})
      : this(future,
            dataValue: (BuildContext context, Res result) => result as T,
            noDataValue: (BuildContext context) => noDataValue,
            errorValue:
                (BuildContext context, Object error, StackTrace stackTrace) =>
                    errorValue);

  @override
  T getValue(BuildContext context) {
    T retour;
    if (_isComplete) {
      if (_isError) {
        retour = errorValue?.call(context, _error, _stackTrace);
      } else {
        retour = dataValue?.call(context, _resultValue);
      }
    } else {
      retour = noDataValue?.call(context);
    }

    return retour;
  }
}

typedef ValuableGetStreamData<T, Res> = T Function(BuildContext, Res);
typedef ValuableGetStreamError<T> = T Function(
    BuildContext, Object, StackTrace);
typedef ValuableGetStreamDone<T> = T Function(BuildContext);

class StreamValuable<T, Msg> extends Valuable<T> {
  final ValuableGetStreamData dataValue;
  final ValuableGetStreamError errorValue;
  final ValuableGetStreamDone doneValue;

  T Function(BuildContext) _currentValuer;

  StreamValuable(
    Stream<Msg> stream, {
    @required this.dataValue,
    @required this.errorValue,
    @required this.doneValue,
    T initialData,
    bool cancelOnError,
  }) : super() {
    _currentValuer = (_) => initialData;
    stream.listen((Msg data) {
      _changeCurrentValuer(
          (BuildContext context) => dataValue?.call(context, data));
    }, onError: (Object error, StackTrace stacktrace) {
      _changeCurrentValuer((BuildContext context) =>
          errorValue?.call(context, error, stacktrace));
    }, onDone: () {
      _changeCurrentValuer((BuildContext context) => doneValue?.call(context));
    }, cancelOnError: cancelOnError);
  }

  void _changeCurrentValuer(T Function(BuildContext) newValuer) {
    _currentValuer = newValuer;
    notifyListeners();
  }

  @override
  T getValue(BuildContext context) => _currentValuer(context);
}

// Comparator
enum _CompareOperator {
  equals,
  greater_than,
  smaller_than,
  greater_or_equals,
  smaller_or_equals,
  different
}

class ValuableCompare<T> extends ValuableBool {
  final Valuable<T> _operand1;
  final _CompareOperator _operator;
  final Valuable<T> _operand2;

  ValuableCompare._(this._operand1, this._operator, this._operand2)
      : super(false);

  // Equality comparator
  ValuableCompare.equals(Valuable<T> operand1, Valuable<T> operand2)
      : this._(operand1, _CompareOperator.equals, operand2);
  // Greater comparator
  ValuableCompare.greaterThan(Valuable<T> operand1, Valuable<T> operand2)
      : this._(operand1, _CompareOperator.greater_than, operand2);
  // Greater or equality comparator
  ValuableCompare.greaterOrEquals(Valuable<T> operand1, Valuable<T> operand2)
      : this._(operand1, _CompareOperator.greater_or_equals, operand2);
  // Smaller comparator
  ValuableCompare.smallerThan(Valuable<T> operand1, Valuable<T> operand2)
      : this._(operand1, _CompareOperator.smaller_than, operand2);
  // Smaller or equality comparator
  ValuableCompare.smallerOrEquals(Valuable<T> operand1, Valuable<T> operand2)
      : this._(operand1, _CompareOperator.smaller_or_equals, operand2);
  // Difference comparator
  ValuableCompare.different(Valuable<T> operand1, Valuable<T> operand2)
      : this._(operand1, _CompareOperator.different, operand2);

  @override
  bool getValue(BuildContext context) {
    return _compareWithOperator(context);
  }

  bool _compareWithOperator(BuildContext context) {
    bool retour;
    dynamic fieldValue = readValuable(_operand1, context);
    dynamic compareValue = readValuable(_operand2, context);

    switch (_operator) {
      case _CompareOperator.equals:
        retour = fieldValue == compareValue;
        break;
      case _CompareOperator.greater_than:
        retour = fieldValue > compareValue;
        break;
      case _CompareOperator.smaller_than:
        retour = fieldValue < compareValue;
        break;
      case _CompareOperator.smaller_or_equals:
        retour = fieldValue <= compareValue;
        break;
      case _CompareOperator.greater_or_equals:
        retour = fieldValue >= compareValue;
        break;
      case _CompareOperator.different:
        retour = fieldValue != compareValue;
        break;
      default:
        retour = false;
        break;
    }
    return retour;
  }
}

enum _NumOperator {
  sum,
  substract,
  multiply,
  divide,
  modulo,
  trunc_divide,
  negate
}

class ValuableNumOperation extends _ValuableNum {
  final Valuable<num> _operand1;
  final Valuable<num> _operand2;
  final _NumOperator _operator;

  ValuableNumOperation._(this._operand1, this._operator, this._operand2)
      : super(0);

  /// Sum operation
  ValuableNumOperation.sum(Valuable<num> operand1, Valuable<num> operand2)
      : this._(operand1, _NumOperator.sum, operand2);

  /// Substraction operation
  ValuableNumOperation.substract(Valuable<num> operand1, Valuable<num> operand2)
      : this._(operand1, _NumOperator.substract, operand2);

  /// Multiplication operation
  ValuableNumOperation.multiply(Valuable<num> operand1, Valuable<num> operand2)
      : this._(operand1, _NumOperator.multiply, operand2);

  /// Division operation
  ValuableNumOperation.divide(Valuable<num> operand1, Valuable<num> operand2)
      : this._(operand1, _NumOperator.divide, operand2);

  /// Trunctature division operation
  ValuableNumOperation.truncDivide(
      Valuable<num> operand1, Valuable<num> operand2)
      : this._(operand1, _NumOperator.trunc_divide, operand2);

  /// Modulo operation
  ValuableNumOperation.modulo(Valuable<num> operand1, Valuable<num> operand2)
      : this._(operand1, _NumOperator.modulo, operand2);

  /// Negate operation
  ValuableNumOperation.negate(Valuable<num> operand1)
      : this._(operand1, _NumOperator.sum, null);

  @override
  num getValue(BuildContext context) {
    return _compareWithOperator(context);
  }

  num _compareWithOperator(BuildContext context) {
    num retour;
    num ope1 = readValuable(_operand1, context);
    num ope2 =
        _operator != _NumOperator.negate ? readValuable(_operand2, context) : 0;

    switch (_operator) {
      case _NumOperator.sum:
        retour = ope1 + ope2;
        break;
      case _NumOperator.divide:
        retour = ope1 / ope2;
        break;
      case _NumOperator.modulo:
        retour = ope1 % ope2;
        break;
      case _NumOperator.multiply:
        retour = ope1 * ope2;
        break;
      case _NumOperator.substract:
        retour = ope1 - ope2;
        break;
      case _NumOperator.trunc_divide:
        retour = ope1 ~/ ope2;
        break;
      case _NumOperator.negate:
        retour = -ope1;
        break;
      default:
        retour = 0;
        break;
    }
    return retour;
  }
}

// Mixins
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
  _ValuableNum operator +(Valuable<num> other) =>
      ValuableNumOperation.sum(this, other);

  /// Subtraction operator.
  _ValuableNum operator -(Valuable<num> other) =>
      ValuableNumOperation.substract(this, other);

  /// Multiplication operator.
  _ValuableNum operator *(Valuable<num> other) =>
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
  _ValuableNum operator %(Valuable<num> other) =>
      ValuableNumOperation.modulo(this, other);

  /// Division operator.
  _ValuableNum operator /(Valuable<num> other) =>
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
  _ValuableNum operator ~/(Valuable<num> other) =>
      ValuableNumOperation.truncDivide(this, other);

  /// Negate operator.
  _ValuableNum operator -() => ValuableNumOperation.negate(this);
}
