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

  Valuable _getCompare(dynamic other, CompareOperator ope) {
    Valuable compare;

    if (other is T) {
      compare = Valuable.value(other);
    } else if (other is Valuable) {
      compare = other;
    } else {
      throw Error();
    }

    return ValuableCompare(this, ope, compare);
  }

  ValuableBool operator >(Valuable<T> other) {
    return _getCompare(other, CompareOperator.greater_than);
  }

  ValuableBool operator >=(Valuable<T> other) {
    return _getCompare(other, CompareOperator.greater_or_equals);
  }

  ValuableBool operator <(Valuable<T> other) {
    return _getCompare(other, CompareOperator.smaller_than);
  }

  ValuableBool operator <=(Valuable<T> other) {
    return _getCompare(other, CompareOperator.smaller_or_equals);
  }

  ValuableBool equals(dynamic other) {
    return _getCompare(other, CompareOperator.equals);
  }

  ValuableBool notEquals(dynamic other) {
    return _getCompare(other, CompareOperator.different);
  }
}

class _Valuable<T> extends Valuable<T> {
  final T value;

  _Valuable(this.value) : super();

  T getValue(BuildContext context) => value;
}

class ValuableBool extends _Valuable<bool> with _ValuableBoolOperators {
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
    with _ValuableBoolOperators {
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
enum CompareOperator {
  equals,
  greater_than,
  smaller_than,
  greater_or_equals,
  smaller_or_equals,
  different
}

class ValuableCompare<T> extends ValuableBool {
  final Valuable<T> _operand1;
  final CompareOperator _operator;
  final Valuable<T> _operand2;

  ValuableCompare(this._operand1, this._operator, this._operand2)
      : super(false);

  @override
  bool getValue(BuildContext context) {
    return _compareWithOperator(context);
  }

  bool _compareWithOperator(BuildContext context) {
    bool retour;
    dynamic fieldValue = readValuable(_operand1, context);
    dynamic compareValue = readValuable(_operand2, context);

    switch (_operator) {
      case CompareOperator.equals:
        retour = fieldValue == compareValue;
        break;
      case CompareOperator.greater_than:
        retour = fieldValue > compareValue;
        break;
      case CompareOperator.smaller_than:
        retour = fieldValue < compareValue;
        break;
      case CompareOperator.smaller_than:
        retour = fieldValue <= compareValue;
        break;
      case CompareOperator.greater_or_equals:
        retour = fieldValue >= compareValue;
        break;
      case CompareOperator.different:
        retour = fieldValue != compareValue;
        break;
      default:
        retour = false;
        break;
    }
    return retour;
  }
}

// Mixins
mixin _ValuableBoolOperators on Valuable<bool> {
  ValuableBool operator &(Valuable<bool> other) {
    return ValuableBoolGroup.and(<Valuable<bool>>[this, other]);
  }

  ValuableBool operator |(Valuable<bool> other) {
    return ValuableBoolGroup.or(<Valuable<bool>>[this, other]);
  }
}
