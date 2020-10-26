import 'package:flutter/material.dart';
import 'package:valuable/src/mixins.dart';
import 'package:valuable/src/operations.dart';

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

/// Immutable object that let transit informations about the current context of a valuable's value reading
@immutable
class ValuableContext {
  final BuildContext context;

  const ValuableContext({this.context});

  bool get hasBuildContext => context != null;
}

mixin ValuableWatcherMixin {
  final Map<Valuable, VoidCallback> _watched = <Valuable, VoidCallback>{};

  /// Watch a valuable, that eventually change
  @protected
  T watch<T>(Valuable<T> valuable) {
    if (valuable != null && !_watched.containsKey(valuable)) {
      VoidCallback callback = onValuableChange;

      _watched.putIfAbsent(valuable, () => callback);
      valuable.addListener(callback);
      valuable.listenDispose(() {
        unwatch(valuable);
      });
    }

    return valuable.getValue(valuableContext);
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

abstract class Valuable<T> extends ChangeNotifier {
  final ValueNotifier<bool> _isMounted;

  final Map<Valuable, VoidCallback> _removeListeners =
      <Valuable, VoidCallback>{};

  Valuable() : _isMounted = ValueNotifier(true);

  factory Valuable.value(T value) {
    return _Valuable<T>(value);
  }

  T getValue([ValuableContext context = const ValuableContext()]);

  @protected
  V readValuable<V>(Valuable<V> valuable,
      [ValuableContext context = const ValuableContext()]) {
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

  T getValue([ValuableContext context = const ValuableContext()]) => value;
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
  bool getValue([ValuableContext context = const ValuableContext()]) {
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
  T getValue([ValuableContext context = const ValuableContext()]) {
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
  T getValue([ValuableContext context = const ValuableContext()]) =>
      _currentValuer(context);
}
