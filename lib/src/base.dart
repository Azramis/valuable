import 'dart:async';

import 'package:flutter/material.dart';
import 'package:valuable/src/errors.dart';
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
final Valuable<bool> boolTrue = Valuable<bool>.value(true);

/// Shortcut to get a valuable with the value false
final Valuable<bool> boolFalse = Valuable<bool>.value(false);

/// Shortcut to get a valuable with the value of an empty string
final Valuable<String> stringEmpty = Valuable<String>.value("");

/// Shortcut to get a valuable with the int value 0
final Valuable<int> intZero = Valuable<int>.value(0);

/// Shortcut to get a valuable with the double value 0.0
final Valuable<double> doubleZero = Valuable<double>.value(0.0);

/// Immutable object that let transit informations about the current context of a valuable's value reading
@immutable
class ValuableContext {
  /// BuildContext that can be attached to a ValuableContext
  ///
  /// [ValuableConsumer] passes a BuildContext when it get values through [watch] method
  final BuildContext context;

  /// Constructor
  ///
  /// [context] is optional
  const ValuableContext({this.context});

  /// Get if the BuildContext [context] is present
  bool get hasBuildContext => context != null;
}

/// Main class Valuable
///
/// This class inherits of ChangeNotifier to manage its events.
///
/// It's importance to notice that the dispose of this object has to be done to avoid
/// memory leaks and useless remaining references. For these reasons, the method [dispose] should be called
/// when the object isn't used anymore.
///
/// It's possible to know if the Valuable object is still mounted by testing getter
/// [isMounted]. When [isMounted] becomes *false*, it can't back to *true*, this object
/// will die.
/// Furthermore, it's possible to listen for the object unmounting by using the method
/// [listenDispose].
///
/// This class defines 2 factories to build simpler Valuable:
/// - [Valuable.value] represent a Valuable at its simplest form : a value.
/// No function, no depenancies, just a value that would be returned by [getValue]
/// - [Valuable.byValuer] which is more complex but even more powerful. Indeed, the
/// [valuer] param is a function, where Valuable calculate its self value. In fact
/// it's even possible to depends on other Valuables, whose values are possibly changeable.
/// When these Valuable values change, our Valuable is notified, and notify at its turn
/// to be read again.
///
/// Lastly, the most useful method, [getValue]. Simple as its name, this method returns
/// the current value of the Valuable (final or calculated).
/// In addition, it's even possible to pass a [ValuableContext] to specify the context
/// where the value is needed.
abstract class Valuable<Output> extends ChangeNotifier
    with ValuableWatcherMixin {
  final ValueNotifier<bool> _isMounted;

  final Map<Valuable, VoidCallback> _removeListeners =
      <Valuable, VoidCallback>{};

  Valuable() : _isMounted = ValueNotifier(true);

  /// Returns if this object is still mounted
  bool get isMounted => _isMounted?.value ?? false;

  /// Factory [Valuable.value] to build a simple Valuable on a final value
  factory Valuable.value(Output value) {
    return _Valuable<Output>(value);
  }

  /// Factory [Valuable.valuer] to build a Valuable that calculate its own value
  /// through a function.
  factory Valuable.byValuer(ValuableParentWatcher<Output> valuer) {
    return _Valuable<Output>.byValuer(valuer);
  }

  /// Get the current value of the Valuable
  @mustCallSuper
  Output getValue([ValuableContext context = const ValuableContext()]) {
    // Before reading/calculating the value, the watched Valuables tree is cleaned
    // in order to remove the dependencies that may disapear.
    cleanWatched();
    // After we proceed to get the value, watched Valuables tree will be renewed
    return getValueDefinition(context);
  }

  /// This method should be redefined in ever sub-classes to determine how works
  /// the method [getValue]
  @protected
  Output getValueDefinition(
      [ValuableContext context = const ValuableContext()]);

  @protected
  @override
  T watch<T>(Valuable<T> valuable,
      {ValuableContext valuableContext, ValuableWatcherSelector<T> selector}) {
    if (valuable == this) {
      throw ValuableIllegalUseException();
    }
    return super
        .watch(valuable, valuableContext: valuableContext, selector: selector);
  }

  @protected
  @override
  void onValuableChange() {
    this.notifyListeners();
  }

  /// Allows to be notified when this Valuable is disposed
  ///
  /// [onDispose] will be called when this Valuable is disposed
  void listenDispose(VoidCallback onDispose) {
    assert(onDispose != null, "onDispose should not be null !");
    _isMounted.addListener(onDispose);
  }

  /// Should be called to clean all links to other Valuables, and all the rest
  @override
  void dispose() {
    _isMounted.value = false;
    _isMounted.dispose();
    List<VoidCallback> removers = _removeListeners.values.toList();
    removers.forEach((VoidCallback remover) => remover?.call());

    super.dispose();
  }

  Valuable<bool> _getCompare(dynamic other, CompareOperator ope) {
    Valuable compare;

    if (other is Output) {
      compare = Valuable.value(other);
    } else if (other is Valuable) {
      compare = other;
    } else {
      throw UnmatchTypeValuableError(this, other?.runtimeType);
    }

    return ValuableCompare(this, ope, compare);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> operator >(dynamic other) {
    return _getCompare(other, CompareOperator.greater_than);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> operator >=(dynamic other) {
    return _getCompare(other, CompareOperator.greater_or_equals);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> operator <(dynamic other) {
    return _getCompare(other, CompareOperator.smaller_than);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> operator <=(dynamic other) {
    return _getCompare(other, CompareOperator.smaller_or_equals);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> equals(dynamic other) {
    return _getCompare(other, CompareOperator.equals);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> notEquals(dynamic other) {
    return _getCompare(other, CompareOperator.different);
  }
}

class _Valuable<Output> extends Valuable<Output> {
  final ValuableParentWatcher<Output> valuer;

  _Valuable.byValuer(this.valuer) : super();
  _Valuable(Output value)
      : this.byValuer((ValuableWatcher<Output> watch,
                {ValuableContext valuableContext}) =>
            value);

  @override
  Output getValueDefinition(
          [ValuableContext context = const ValuableContext()]) =>
      valuer(watch, valuableContext: context);
}

/*class ValuableBool extends _Valuable<bool> with ValuableBoolOperators {
  ValuableBool(bool value) : super(value);
  ValuableBool.byValuer(ValuableParentWatcher<bool> valuer)
      : super.byValuer(valuer);
}*/

enum _BoolGroupType { and, or }

/// A class to make logical operations with Valuable<bool>
///
/// Group some Valuable<bool> with a boolean operator (AND OR), to get a super-Valuable
/// that depends on them.
class ValuableBoolGroup extends Valuable<bool> {
  final _BoolGroupType type;

  /// All the constraints to be used in the group to determine the value
  final List<Valuable<bool>> constraints;

  ValuableBoolGroup._(this.type, this.constraints) : super();

  /// Constructor for an AND logical group
  ValuableBoolGroup.and(List<Valuable<bool>> constraints)
      : this._(_BoolGroupType.and, constraints);

  /// Constructor for an OR logical group
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

/*class ValuableString extends _Valuable<String> {
  ValuableString(String value) : super(value);
  ValuableString.byValuer(ValuableParentWatcher<String> valuer)
      : super.byValuer(valuer);
}

abstract class ValuableNum<Output extends num> extends _Valuable<Output> {
  ValuableNum(Output value) : super(value);
  ValuableNum.byValuer(ValuableParentWatcher<Output> valuer)
      : super.byValuer(valuer);
}

class ValuableInt extends ValuableNum<int> {
  ValuableInt(int value) : super(value);
  ValuableInt.byValuer(ValuableParentWatcher<int> valuer)
      : super.byValuer(valuer);
}

class ValuableDouble extends ValuableNum<double> {
  ValuableDouble(double value) : super(value);
  ValuableDouble.byValuer(ValuableParentWatcher<double> valuer)
      : super.byValuer(valuer);
}*/

/// Method prototype for a Future complete
typedef ValuableGetFutureResult<Output, Res> = Output Function(
    ValuableContext context, Res result);

/// Method prototype for a Future error
typedef ValuableGetFutureError<Output> = Output Function(
    ValuableContext context, Object error, StackTrace stackTrace);

/// Method prototype to get a value while a Future is not complete/in error
typedef ValuableGetFutureLoading<Output> = Output Function(
    ValuableContext context);

/// A Valuable that depends on a Future
///
/// This object provides a function for each state of the future, to have a value
/// that depends on it
///
/// - [dataValue] that process to return an [Output] value depends on the [Res] complete
/// response of the future
/// - [noDataValue] will return an [Output] value while the future is still incomplete
/// - [errorValue] will return an [Output] when the future complete on error
///
/// If a function is not provide, then a null value is returned at its place
class FutureValuable<Output, Res> extends Valuable<Output> {
  final Future<Res> _future;

  /// A function to return a value when the future is complete normally
  final ValuableGetFutureResult<Output, Res> dataValue;

  /// A function to return a value when the future is still incomplete
  final ValuableGetFutureLoading<Output> noDataValue;

  /// A function to return a value when the future is complete on error
  final ValuableGetFutureError<Output> errorValue;

  bool _isComplete;
  bool _isError;
  Res _resultValue;
  Object _error;
  StackTrace _stackTrace;

  /// Constructor to provide each functions
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

  /// Constructor to simply map result value as Valuable value
  ///
  /// [Output] must be super type or type of [Res]
  FutureValuable.values(Future<Res> future,
      {Output noDataValue, Output errorValue})
      : this(future,
            dataValue: (ValuableContext context, Res result) =>
                result as Output,
            noDataValue: (ValuableContext context) => noDataValue,
            errorValue: (ValuableContext context, Object error,
                    StackTrace stackTrace) =>
                errorValue);

  @override
  Output getValueDefinition(
      [ValuableContext context = const ValuableContext()]) {
    Output retour;
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

/// Method prototype for onData of the Stream
typedef ValuableGetStreamData<Output, Res> = Output Function(
    ValuableContext, Res);

/// Method prototype for onError of the Stream
typedef ValuableGetStreamError<Output> = Output Function(
    ValuableContext, Object, StackTrace);

/// Method prototype for onDone of the Stream
typedef ValuableGetStreamDone<Output> = Output Function(ValuableContext);

class StreamValuable<Output, Msg> extends Valuable<Output> {
  final ValuableGetStreamData dataValue;
  final ValuableGetStreamError errorValue;
  final ValuableGetStreamDone doneValue;

  Output Function(ValuableContext) _currentValuer;

  StreamSubscription _subscription;

  StreamValuable(
    Stream<Msg> stream, {
    @required this.dataValue,
    @required this.errorValue,
    @required this.doneValue,
    Output initialData,
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

  void _changeCurrentValuer(Output Function(ValuableContext) newValuer) {
    _currentValuer = newValuer;
    notifyListeners();
  }

  @override
  Output getValueDefinition(
          [ValuableContext context = const ValuableContext()]) =>
      _currentValuer(context);

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel(); // Cancel subscription to free memory
  }
}
