import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:valuable/src/errors.dart';
import 'package:valuable/src/exceptions.dart';
import 'package:valuable/src/mixins.dart';
import 'package:valuable/src/operations.dart';
import 'package:valuable/src/widgets.dart';

typedef ValuableWatcherSelector<T> = bool Function(
    Valuable<T> valuable, T previousWatchedValue);
typedef ValuableWatcher = T Function<T>(Valuable<T> valuable,
    {ValuableContext? valuableContext, ValuableWatcherSelector? selector});
typedef ValuableParentWatcher<T> = T Function(ValuableWatcher watch,
    {ValuableContext? valuableContext});

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
  final BuildContext? context;

  /// Constructor
  ///
  /// [context] is optional
  const ValuableContext({this.context});

  /// Get if the BuildContext [context] is present
  bool get hasBuildContext => context != null;

  /// Redefine equality operator
  @override
  bool operator ==(Object other) {
    return other is ValuableContext && (other.context == context);
  }

  @override
  int get hashCode => super.hashCode;
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
  @protected
  final _ValueCache valueCache = _ValueCache();

  /// Determines if the valuable use the cache or not
  ///
  /// If the valuable depends on the ValuableContext provide in the [getValue] method
  /// then it's not possible to use the cache, because of the volability of the value
  final bool _evaluateWithContext;

  final ValueNotifier<bool> _isMounted;

  final Map<Valuable, VoidCallback> _removeListeners =
      <Valuable, VoidCallback>{};

  bool _reevaluatingNeeded = false;

  Valuable({bool evaluateWithContext = false})
      : _isMounted = ValueNotifier(true),
        _evaluateWithContext = evaluateWithContext;

  /// Returns if this object is still mounted
  bool get isMounted => _isMounted.value;

  /// Factory [Valuable.value] to build a simple Valuable on a final value
  factory Valuable.value(Output value) {
    return _Valuable<Output>(value);
  }

  /// Factory [Valuable.byValuer] to build a Valuable that calculate its own value
  /// through a function.
  factory Valuable.byValuer(ValuableParentWatcher<Output> valuer,
      {bool evaluateWithContext = false}) {
    return _Valuable<Output>.byValuer(valuer);
  }

  /// Factory [Valuable.listenable] to build a Valuable that listen
  /// to a [ValueListenable] and provide its value
  factory Valuable.listenable(ValueListenable<Output> listenable) =>
    _ValuableListenable(listenable);

  /// Get the current value of the Valuable
  @mustCallSuper
  Output getValue([ValuableContext? context = const ValuableContext()]) {
    // Check if the valuable is dependent of the ValuableContext to evaluate
    // If not, check if it's invalidation phase
    // If not, check for the cache to be provided
    // in that case, return cached value rather than reevaluate it
    if (!_evaluateWithContext &&
        !_reevaluatingNeeded &&
        valueCache.isProvided) {
      return valueCache.currentValue;
    }
    // Before reading/calculating the value, the watched Valuables tree is cleaned
    // in order to remove the dependencies that may disapear.
    cleanWatched();

    Output value = getValueDefinition(_reevaluatingNeeded, context);

    //
    if (!_evaluateWithContext) {
      valueCache.currentValue = value;
    }
    // We are reevaluating the Valuable, so we can unmark it
    _reevaluatingNeeded = false;
    // After we proceed to get the value, watched Valuables tree will be renewed
    return value;
  }

  /// This method should be redefined in ever sub-classes to determine how works
  /// the method [getValue]
  @protected
  Output getValueDefinition(bool reevaluatingNeeded,
      [ValuableContext? context = const ValuableContext()]);

  @protected
  @override
  T watch<T>(Valuable<T> valuable,
      {ValuableContext? valuableContext,
      ValuableWatcherSelector<T>? selector}) {
    if (valuable == this) {
      throw ValuableIllegalUseException();
    }
    return super
        .watch(valuable, valuableContext: valuableContext, selector: selector);
  }

  @protected
  @override
  void onValuableChange() {
    markToReevaluate();
  }

  /// Mark the valuable to be reevaluated
  ///
  /// If it's the first time, then it notify listeners
  void markToReevaluate() {
    if (!_reevaluatingNeeded) {
      _reevaluatingNeeded = true;
      this.notifyListeners();
    }
  }

  /// Allows to be notified when this Valuable is disposed
  ///
  /// [onDispose] will be called when this Valuable is disposed
  void listenDispose(VoidCallback onDispose) {
    _isMounted.addListener(onDispose);
  }

  /// Should be called to clean all links to other Valuables, and all the rest
  @override
  void dispose() {
    _isMounted.value = false;
    _isMounted.dispose();
    List<VoidCallback> removers = _removeListeners.values.toList();
    removers.forEach((VoidCallback remover) => remover());

    super.dispose();
  }

  /// A method to map a Valuable from [Output] to [Other]
  Valuable<Other> map<Other>(Other Function(Output) toElement) =>
    Valuable.byValuer(
      (watch, {valuableContext}) => 
        toElement(
          watch(
            this, 
            valuableContext: valuableContext,
          ),
        ),
      );

  Valuable<bool> _getCompare(dynamic other, CompareOperator ope) {
    Valuable compare;

    if (other is Output) {
      compare = Valuable.value(other);
    } else if (other is Valuable) {
      compare = other;
    } else {
      throw UnmatchTypeValuableError(this, other?.runtimeType ?? Null);
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

class _ValueCache<Output> {
  late Output _currentValue;
  bool _isProvided = false;
  Output get currentValue => _currentValue;
  set currentValue(Output value) {
    _currentValue = value;
    _isProvided = true;
  }

  bool get isProvided => _isProvided;
}

class _Valuable<Output> extends Valuable<Output> {
  final ValuableParentWatcher<Output> valuer;

  _Valuable.byValuer(this.valuer, {bool evaluateWithContext = false})
      : super(evaluateWithContext: evaluateWithContext);
  _Valuable(Output value)
      : this.byValuer((ValuableWatcher watch,
                {ValuableContext? valuableContext}) =>
            value);

  @override
  Output getValueDefinition(bool reevaluatingNeeded,
          [ValuableContext? context = const ValuableContext()]) =>
      valuer(watch, valuableContext: context);
}

/// A [Valuable] linked to [ValueListenable] to provide a value
class _ValuableListenable<T> extends Valuable<T> {
  final ValueListenable<T> _listenable;

  _ValuableListenable(this._listenable) : super(evaluateWithContext: false) {
    _listenable.addListener(markToReevaluate);
  }
  
  @override
  T getValueDefinition(bool reevaluatingNeeded, 
    [ValuableContext? context = const ValuableContext()]) => _listenable.value;

  @override
  void dispose(){
    super.dispose();
    _listenable.removeListener(markToReevaluate); // Unlink from the _listenable 
  }  
}

enum _BoolGroupType { and, or }

/// A class to make logical operations with Valuable<bool>
///
/// Group some Valuable<bool> with a boolean operator (AND OR), to get a super-Valuable
/// that depends on them.
class ValuableBoolGroup extends Valuable<bool> {
  final _BoolGroupType type;

  /// All the constraints to be used in the group to determine the value
  final List<Valuable<bool>> constraints;

  ValuableBoolGroup._(this.type, this.constraints)
      : super(
            evaluateWithContext:
                true /* Needed because of the parameter passed to children */);

  /// Constructor for an AND logical group
  ValuableBoolGroup.and(List<Valuable<bool>> constraints)
      : this._(_BoolGroupType.and, constraints);

  /// Constructor for an OR logical group
  ValuableBoolGroup.or(List<Valuable<bool>> constraints)
      : this._(_BoolGroupType.or, constraints);

  @override
  @protected
  bool getValueDefinition(bool reevaluatingNeeded,
      [ValuableContext? valuableContext = const ValuableContext()]) {
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

/// Method prototype for a Future complete
typedef ValuableGetFutureResult<Output, Res> = Output Function(
    ValuableContext? context, Res result);

/// Method prototype for a Future error
typedef ValuableGetFutureError<Output> = Output Function(
    ValuableContext? context, Object error, StackTrace stackTrace);

/// Method prototype to get a value while a Future is not complete/in error
typedef ValuableGetFutureLoading<Output> = Output Function(
    ValuableContext? context);

/// A Valuable that depends on a Future
///
/// This object provides a function for each state of the future, to have a value
/// that depends on it
///
/// - [dataValue] that process to return an [Output] value depends on the [Res] complete
/// response of the future
/// - [noDataValue] will return an [Output] value while the future is still incomplete
/// - [errorValue] will return an [Output] when the future complete on error
class FutureValuable<Output, Res> extends Valuable<Output> {
  final Future<Res> _future;

  /// A function to return a value when the future is complete normally
  final ValuableGetFutureResult<Output, Res> dataValue;

  /// A function to return a value when the future is still incomplete
  final ValuableGetFutureLoading<Output> noDataValue;

  /// A function to return a value when the future is complete on error
  final ValuableGetFutureError<Output> errorValue;

  bool _isComplete = false;
  bool _isError = false;
  late final Res _resultValue;
  late final Object _error;
  late final StackTrace _stackTrace;

  /// Constructor to provide each functions
  FutureValuable(Future<Res> future,
      {required this.dataValue,
      required this.noDataValue,
      required this.errorValue,
      bool evaluateWithContext = false})
      : _future = future,
        super(
          evaluateWithContext: evaluateWithContext,
        ) {
    _future.then((Res value) {
      _isComplete = true;
      _resultValue = value;
      markToReevaluate();
    }, onError: (Object error, StackTrace stackTrace) {
      _error = error;
      _stackTrace = stackTrace;
      _isComplete = _isError = true;
      markToReevaluate();
    });
  }

  /// Constructor to simply map result value as Valuable value
  ///
  /// [Output] must be super type or type of [Res]
  FutureValuable.values(Future<Res> future,
      {required Output noDataValue, required Output errorValue})
      : this(future,
            dataValue: (ValuableContext? context, Res result) =>
                result as Output,
            noDataValue: (ValuableContext? context) => noDataValue,
            errorValue: (ValuableContext? context, Object error,
                    StackTrace stackTrace) =>
                errorValue);

  @override
  @protected
  Output getValueDefinition(bool reevaluatingNeeded,
      [ValuableContext? context = const ValuableContext()]) {
    Output retour;
    if (_isComplete) {
      if (_isError) {
        retour = errorValue.call(context, _error, _stackTrace);
      } else {
        retour = dataValue.call(context, _resultValue);
      }
    } else {
      retour = noDataValue.call(context);
    }

    return retour;
  }
}

/// Method prototype for onData of the Stream
typedef ValuableGetStreamData<Output, Res> = Output Function(
    ValuableContext?, Res);

/// Method prototype for onError of the Stream
typedef ValuableGetStreamError<Output> = Output Function(
    ValuableContext?, Object, StackTrace);

/// Method prototype for onDone of the Stream
typedef ValuableGetStreamDone<Output> = Output Function(ValuableContext?);

/// A Valuable that remains on a Stream<Msg>
/// 
/// This object provide a valuer function, for each possible state of the Stream
/// 
/// - [dataValue] while the Stream messaging without error
/// - [errorValue] when the Stream get an error
/// - [doneValue] when the Stream closes and is done
class StreamValuable<Output, Msg> extends Valuable<Output> {
  /// A function to provide an [Output] value on a [Msg] message
  final ValuableGetStreamData<Output, Msg> dataValue;
  /// A function to provide an [Output] value on an error in the Stream
  final ValuableGetStreamError<Output> errorValue;
  /// A function to provide an [Output] value when the Stream closes
  final ValuableGetStreamDone<Output> doneValue;

  late Output Function(ValuableContext?) _currentValuer;

  late final StreamSubscription _subscription;

  /// Constructor to provide each functions
  StreamValuable(Stream<Msg> stream,
      {required this.dataValue,
      required this.errorValue,
      required this.doneValue,
      required Output initialData,
      bool? cancelOnError,
      bool evaluateWithContext = false,})
      : super(evaluateWithContext: evaluateWithContext) {
    _currentValuer = (_) => initialData;
    _subscription = stream.listen((Msg data) {
      _changeCurrentValuer(
          (ValuableContext? context) => dataValue.call(context, data));
    }, onError: (Object error, StackTrace stacktrace) {
      _changeCurrentValuer((ValuableContext? context) =>
          errorValue.call(context, error, stacktrace));
    }, onDone: () {
      _changeCurrentValuer(
          (ValuableContext? context) => doneValue.call(context));
    }, cancelOnError: cancelOnError);
  }

  /// Constructor to simplify the case when [Output] == [Msg]
  StreamValuable.values(
    Stream<Msg> stream,
    {
      required Output errorValue,
      required Output doneValue,
      required Output initialData,
      bool? cancelOnError,
      bool evaluateWithContext = false,
    }
  ) : this(stream, 
    dataValue: (ValuableContext? context, Msg msg) => msg as Output, 
    errorValue: (ValuableContext? context, Object error, StackTrace st,) => errorValue,
    doneValue: (ValuableContext? context,) => doneValue,
    initialData: initialData,
    cancelOnError: cancelOnError,
    evaluateWithContext: evaluateWithContext,
  );

  void _changeCurrentValuer(Output Function(ValuableContext?) newValuer) {
    _currentValuer = newValuer;
    markToReevaluate();
  }

  @override
  @protected
  Output getValueDefinition(bool reevaluatingNeeded,
          [ValuableContext? context = const ValuableContext()]) =>
      _currentValuer(context);

  @override
  void dispose() {
    super.dispose();
    _subscription.cancel(); // Cancel subscription to free memory
  }
}
