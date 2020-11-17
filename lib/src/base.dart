import 'dart:async';

import 'package:flutter/material.dart';
import 'package:valuable/src/exceptions.dart';
import 'package:valuable/src/mixins.dart';
import 'package:valuable/src/operations.dart';

typedef ValuableWatcherSelector<T> = bool Function(
    Valuable<T> valuable, T previousWatchedValue);
typedef ValuableWatcher<T> = T Function(Valuable<T> valuable,
    {ValuableContext valuableContext, ValuableWatcherSelector selector});
typedef ValuableParentWatcher<T> = T Function(ValuableWatcher<T> watch,
    {ValuableContext valuableContext});

/// Shortcut to get a valuable with the value true
final Valuable<bool> boolTrue = ValuableBool(true);

/// Shortcut to get a valuable with the value false
final Valuable<bool> boolFalse = ValuableBool(false);

/// Shortcut to get a valuable with the value of an empty string
final Valuable<String> stringEmpty = ValuableString("");

/// Shortcut to get a valuable with the int value 0
final Valuable<int> intZero = ValuableInt(0);

/// Shortcut to get a valuable with the double value 0.0
final Valuable<double> doubleZero = ValuableDouble(0.0);

/// Immutable object that let transit informations about the current context of a valuable's value reading
@immutable
class ValuableContext {
  final BuildContext context;

  const ValuableContext({this.context});

  bool get hasBuildContext => context != null;
}

abstract class Valuable<T> extends ChangeNotifier with ValuableWatcherMixin {
  final ValueNotifier<bool> _isMounted;
  bool get isMounted => _isMounted?.value ?? false;

  final Map<Valuable, VoidCallback> _removeListeners =
      <Valuable, VoidCallback>{};

  Valuable() : _isMounted = ValueNotifier(true);

  factory Valuable.value(T value) {
    return _Valuable<T>(value);
  }

  @mustCallSuper
  T getValue([ValuableContext context = const ValuableContext()]) {
    cleanWatched();
    return getValueDefinition(context);
  }

  @protected
  T getValueDefinition([ValuableContext context = const ValuableContext()]);

  @override
  T watch<T>(Valuable<T> valuable,
      {ValuableContext valuableContext, ValuableWatcherSelector<T> selector}) {
    if (valuable == this) {
      throw ValuableIllegalUseException();
    }
    return super
        .watch(valuable, valuableContext: valuableContext, selector: selector);
  }

  @override
  void onValuableChange() {
    this.notifyListeners();
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

  T getValueDefinition([ValuableContext context = const ValuableContext()]) =>
      value;
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
  bool getValueDefinition(
      [ValuableContext valuableContext = const ValuableContext()]) {
    bool retour = type == _BoolGroupType.and;

    for (Valuable<bool> constraint in constraints) {
      if (type == _BoolGroupType.and) {
        retour = retour && watch(constraint, valuableContext: valuableContext);
        if (retour == false) {
          break;
        }
      } else {
        retour = retour || watch(constraint, valuableContext: valuableContext);
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

abstract class ValuableNum<T extends num> extends _Valuable<T> {
  ValuableNum(T value) : super(value);
}

class ValuableInt extends ValuableNum<int> {
  ValuableInt(int value) : super(value);
}

class ValuableDouble extends ValuableNum<double> {
  ValuableDouble(double value) : super(value);
}

typedef ValuableGetFutureResult<T, Res> = T Function(ValuableContext, Res);
typedef ValuableGetFutureError<T> = T Function(
    ValuableContext, Object, StackTrace);
typedef ValuableGetFutureLoading<T> = T Function(ValuableContext);

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
            dataValue: (ValuableContext context, Res result) => result as T,
            noDataValue: (ValuableContext context) => noDataValue,
            errorValue: (ValuableContext context, Object error,
                    StackTrace stackTrace) =>
                errorValue);

  @override
  T getValueDefinition([ValuableContext context = const ValuableContext()]) {
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

typedef ValuableGetStreamData<T, Res> = T Function(ValuableContext, Res);
typedef ValuableGetStreamError<T> = T Function(
    ValuableContext, Object, StackTrace);
typedef ValuableGetStreamDone<T> = T Function(ValuableContext);

class StreamValuable<T, Msg> extends Valuable<T> {
  final ValuableGetStreamData dataValue;
  final ValuableGetStreamError errorValue;
  final ValuableGetStreamDone doneValue;

  T Function(ValuableContext) _currentValuer;

  StreamSubscription _subscription;

  StreamValuable(
    Stream<Msg> stream, {
    @required this.dataValue,
    @required this.errorValue,
    @required this.doneValue,
    T initialData,
    bool cancelOnError,
  }) : super() {
    _currentValuer = (_) => initialData;
    _subscription = stream.listen((Msg data) {
      _changeCurrentValuer(
          (ValuableContext context) => dataValue?.call(context, data));
    }, onError: (Object error, StackTrace stacktrace) {
      _changeCurrentValuer((ValuableContext context) =>
          errorValue?.call(context, error, stacktrace));
    }, onDone: () {
      _changeCurrentValuer(
          (ValuableContext context) => doneValue?.call(context));
    }, cancelOnError: cancelOnError);
  }

  void _changeCurrentValuer(T Function(ValuableContext) newValuer) {
    _currentValuer = newValuer;
    notifyListeners();
  }

  @override
  T getValueDefinition([ValuableContext context = const ValuableContext()]) =>
      _currentValuer(context);

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel(); // Cancel subscription to free memory
  }
}
