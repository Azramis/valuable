import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:valuable/src/async.dart';
import 'package:valuable/src/callable.dart';
import 'package:valuable/src/debug.dart';
import 'package:valuable/src/disposable.dart';
import 'package:valuable/src/errors.dart';
import 'package:valuable/src/history.dart';
import 'package:valuable/src/mixins.dart';
import 'package:valuable/src/operations.dart';
import 'package:valuable/src/scope.dart';

part 'exceptions.dart';

sealed class Opt<T> {
  const Opt._();

  const factory Opt.some(T value) = Some<T>._;
  const factory Opt.none() = None<T>._;

  R fold<R>(R Function(T value) onSome, R Function() onNone) => switch (this) {
    Some<T>(:final value) => onSome(value),
    None<T>() => onNone(),
  };

  Opt<T> tap({void Function(T value)? onSome, void Function()? onNone}) {
    fold((value) => onSome?.call(value), () => onNone?.call());
    return this;
  }
}

final class Some<T> extends Opt<T> {
  final T value;
  const Some._(this.value) : super._();
}

final class None<T> extends Opt<T> {
  const None._() : super._();
}

typedef ValuableWatcherSelector<T> =
    bool Function(Valuable<T> valuable, T previousWatchedValue);
typedef ValuableWatcher =
    T Function<T>(
      Valuable<T> valuable, {
      ValuableContext? valuableContext,
      ValuableWatcherSelector<T>? selector,
    });
typedef ValuableParentWatcher<T> =
    T Function(ValuableWatcher watch, {ValuableContext? valuableContext});

typedef ValuableValueCleaningCallback<T> =
    void Function(T previousValue, Opt<T> newValue, bool isDisposal);

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

  static const _identity = Object();

  @override
  int get hashCode => Object.hash(_identity, context);
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
/// No function, no dependencies, just a value that would be returned by [getValue]
/// - [Valuable.computed] which is more complex but even more powerful. Indeed, the
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
    with ValuableWatcherMixin
    implements VDisposable {
  final _valueCache = _ValueCache<Output>();

  /// Determines if the valuable use the cache or not
  ///
  /// If the valuable depends on the ValuableContext provided in the [getValue] method
  /// then it's not possible to use the cache, because of the volatility of the value
  final bool _evaluateWithContext;
  @override
  bool get evaluateWithContext =>
      _evaluateWithContext || super.evaluateWithContext;

  final ValueNotifier<bool> _isMounted;

  final ValuableValueCleaningCallback<Output>? _cleaningValueCallback;

  bool _reevaluatingNeeded = false;

  Valuable({
    bool evaluateWithContext = false,
    ValuableValueCleaningCallback<Output>? cleaningValueCallback,
    Opt<Output> initCacheValue = const Opt.none(),
  }) : _isMounted = ValueNotifier(true),
       _evaluateWithContext = evaluateWithContext,
       _cleaningValueCallback = cleaningValueCallback {
    initCacheValue.tap(onSome: (value) => _valueCache.currentValue = value);
    ValuableDebugSession().mountValuable(this);
  }

  /// Returns if this object is still mounted
  bool get isMounted => _isMounted.value;
  @override
  bool get isDisposed => !isMounted;

  /// Factory [Valuable.value] to build a simple Valuable on a final value
  factory Valuable.value(
    Output value, {
    ValuableValueCleaningCallback<Output>? cleaningValueCallback,
  }) = _Valuable<Output>;

  /// Factory [Valuable.computed] to build a Valuable that calculate its own value
  /// through a function.
  factory Valuable.computed(
    ValuableParentWatcher<Output> computation, {
    bool evaluateWithContext,
    ValuableValueCleaningCallback<Output>? cleaningValueCallback,
  }) = _Valuable<Output>.computed;

  /// Factory [Valuable.listenable] to build a Valuable that listen
  /// to a [ValueListenable] and provide its value
  factory Valuable.listenable(
    ValueListenable<Output> listenable, {
    ValuableValueCleaningCallback<Output>? cleaningValueCallback,
  }) => _ValuableListenable(
    listenable,
    (ValueListenable<Output> listenable) => listenable.value,
    cleaningValueCallback: cleaningValueCallback,
  );

  /// Factory [Valuable.listenableComputed] to build a Valuable that listen
  /// to a [Listenable] and provide a value by computation
  static Valuable<Output> listenableComputed<L extends Listenable, Output>(
    L listenable,
    Output Function(L listenable) computation, {
    ValuableValueCleaningCallback<Output>? cleaningValueCallback,
  }) => _ValuableListenable(
    listenable,
    computation,
    cleaningValueCallback: cleaningValueCallback,
  );

  /// Get the current value of the Valuable
  @mustCallSuper
  Output getValue([ValuableContext? context]) {
    // Valuable is not mounted anymore, it can't be read, so we throw an error to prevent use after dispose bugs
    if (!isMounted) {
      throw ValuableDisposedException(this);
    }

    // Check if the valuable is dependent of the ValuableContext to evaluate
    // If not, check if it's invalidation phase
    // If not, check for the cache to be provided
    // in that case, return cached value rather than reevaluate it
    if (!evaluateWithContext &&
        !_reevaluatingNeeded &&
        _valueCache.isProvided) {
      return _valueCache.currentValue;
    }
    // Before reading/calculating the value, the watched Valuables tree is cleaned
    // in order to remove the dependencies that may disappear.
    cleanWatched();

    final value = getValueDefinition(_reevaluatingNeeded, context);
    final willCacheForCleaning = _cleaningValuePhase(newValue: Opt.some(value));

    if (willCacheForCleaning || !evaluateWithContext) {
      _valueCache.currentValue = value;
    }
    // We are reevaluating the Valuable, so we can unmark it
    _reevaluatingNeeded = false;
    // After we proceed to get the value, watched Valuables tree will be renewed
    return value;
  }

  /// Try to call [_cleaningValueCallback] if it's provided, to clean the previous
  /// value before updating it with the new one, or before disposing the Valuable
  /// if [isDisposal] is true.
  ///
  /// When [isDisposal] is true, the [newValue] is not relevant, so it will be set to [Opt.none()].
  ///
  /// [_cleaningValueCallback] will be called only if there is a cached value, and if the new value is different from the cached one,
  /// to prevent use-after-dispose bugs when the new value is the same instance as the current one.
  ///
  /// Returns true if the [_cleaningValueCallback] is provided.
  /// The return value is used by [getValue] to decide whether a value must be kept
  /// in the cache when [evaluateWithContext] is `true` (i.e. when caching is
  /// otherwise disabled): if a cleaning callback exists, the previous value is
  /// cached so it can be passed to the callback on the next reevaluation or on
  /// disposal.
  ///
  /// When [evaluateWithContext] is `false`, [getValue] may still cache values for
  /// performance regardless of whether a cleaning callback is provided; in that
  /// case the caching behavior does not depend on this return value.
  bool _cleaningValuePhase({
    Opt<Output> newValue = const Opt.none(),
    bool isDisposal = false,
  }) {
    final valueCleaningCallback = _cleaningValueCallback;
    // If there is no cleaning callback, then there is no need to run the cleaning phase, and we can directly return
    if (valueCleaningCallback == null) return false;

    // If a cleaning callback is provided, we call it with the previous value. We must therefore save
    // the previous value before updating the cache, even when the cache is not used because of the
    // ValuableContext dependency. However, when `evaluateWithContext` is true, `getValue` may be
    // called repeatedly with the same instance. In that case we must avoid running the cleaning phase
    // on the same instance that we are about to return, to prevent use-after-dispose bugs.
    final bool hasCachedValue = _valueCache.isProvided;
    final bool shouldRunCleaning =
        hasCachedValue &&
        newValue.fold(
          (v) => !identical(_valueCache.currentValue, v),
          () => true,
        );

    if (shouldRunCleaning) {
      // If the cache is provided, then we are in a reevaluation or disposal phase,
      // so we can call the cleaning callback with the previous value and the optional new one.
      // The [isDisposal] flag tells the callback whether this is a disposal (newValue may be ignored) or a normal reevaluation.
      valueCleaningCallback(_valueCache.currentValue, newValue, isDisposal);
    }

    return true;
  }

  /// This method should be redefined in ever sub-classes to determine how works
  /// the method [getValue]
  @protected
  Output getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? context,
  ]);

  @protected
  @override
  T watch<T>(
    Valuable<T> valuable, {
    ValuableContext? valuableContext,
    ValuableWatcherSelector<T>? selector,
  }) {
    if (valuable == this) {
      throw ValuableIllegalUseException();
    }
    return super.watch(
      valuable,
      valuableContext: valuableContext,
      selector: selector,
    );
  }

  @protected
  @override
  void onValuableChange() => markToReevaluate();

  /// Mark the valuable to be reevaluated
  ///
  /// If it's the first time, then it notify listeners
  void markToReevaluate() {
    if (!isMounted) return;
    if (!_reevaluatingNeeded) {
      _reevaluatingNeeded = true;
      notifyListeners();
    }
  }

  /// Allows to be notified when this Valuable is disposed
  ///
  /// [onDispose] will be called when this Valuable is disposed
  /// Returns a function to remove the listener
  @override
  VoidCallback listenDispose(VoidCallback onDispose) {
    if (isDisposed) {
      throw StateError('Valuable already disposed');
    }

    void safeDispose() {
      try {
        onDispose();
      } catch (e, s) {
        // An error occurred during dispose notification, we report it but we don't rethrow it because we want to ensure that the dispose process is still completed,
        // and all the references are cleared to prevent memory leak, even if some listeners throw errors during the dispose notification
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            stack: s,
            library: 'valuable',
            context: ErrorDescription(
              'while notifying dispose listener of $runtimeType',
            ),
          ),
        );
      }
    }

    _isMounted.addListener(safeDispose);
    return () => _isMounted.removeListener(safeDispose);
  }

  /// Build an [HistorizedValuable] based on this Valuable
  HistorizedValuable<Output> historize() => HistorizedValuable<Output>(this);

  @override
  void onWatchedValuableDispose(_) {
    // A watched Valuable was disposed, current value can't be computed anymore,
    // as one of its dependencies is now unreadable, so we need to dispose this Valuable as well
    // to prevent it to be read with an inconsistent state, and to clean all the links to the other Valuables that may cause memory leak
    dispose();
  }

  /// Should be called to clean all links to other Valuables, and all the rest
  @override
  void dispose() {
    if (isMounted) {
      try {
        _isMounted.value = false;
      } catch (e, s) {
        // An error occurred during dispose notification (outside this scope, in a listener for example),
        // we report it but we don't rethrow it because we want to ensure that the dispose process is still completed,
        // and all the references are cleared to prevent memory leak, even if some listeners throw errors during the dispose notification
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            stack: s,
            library: 'valuable',
            context: ErrorDescription('while disposing $runtimeType'),
          ),
        );
      }

      try {
        // Last chance to clean the value with the cleaning callback, if provided,
        // to prevent memory leak, by calling the cleaning callback with isDisposal = true,
        // and newValue of [Opt.none()] because the valuable is in disposal phase, so the new value is not relevant
        // Prevent [_cleaningValuePhase] to break disposal if the cleaning callback throw an error, by catching it
        _cleaningValuePhase(isDisposal: true);
      } catch (e, s) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            stack: s,
            library: 'valuable',
            context: ErrorDescription(
              'while running cleaning callback during disposal of $runtimeType',
            ),
          ),
        );
      } finally {
        _isMounted.dispose();
        cleanWatched();
        super.dispose();
      }
    }
  }

  /// A method to map a Valuable from [Output] to [Other]
  Valuable<Other> map<Other>(
    Other Function(Output) toElement, {
    ValuableScope? scope,
  }) {
    Other computation(ValuableWatcher watch, {ValuableContext? valuableContext}) =>
        toElement(watch(this, valuableContext: valuableContext));

    return scope?.computed(computation) ?? Valuable.computed(computation);
  }

  Valuable<bool> _getCompare(
    dynamic other,
    CompareOperator ope, {
    ValuableScope? scope,
  }) {
    Valuable compare;

    if (other is Output) {
      compare = scope?.value(other) ?? Valuable.value(other);
    } else if (other is Valuable) {
      compare = other;
    } else {
      throw UnmatchTypeValuableError(this, other?.runtimeType ?? Null);
    }

    return scope?.compare(this, ope, compare) ??
        ValuableCompare(this, ope, compare);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> operator >(dynamic other) {
    return _getCompare(other, CompareOperator.greaterThan);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> operator >=(dynamic other) {
    return _getCompare(other, CompareOperator.greaterOrEquals);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> operator <(dynamic other) {
    return _getCompare(other, CompareOperator.smallerThan);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> operator <=(dynamic other) {
    return _getCompare(other, CompareOperator.smallerOrEquals);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> equals(dynamic other, {ValuableScope? scope}) {
    return _getCompare(other, CompareOperator.equals, scope: scope);
  }

  /// Compare with a value that type is [Output] or another [Valuable]
  ///
  /// If [other] type is not [Output] or [Valuable] then an [UnmatchTypeValuableError]
  /// is thrown
  Valuable<bool> notEquals(dynamic other, {ValuableScope? scope}) {
    return _getCompare(other, CompareOperator.different, scope: scope);
  }
}

final class _ValueCache<Output> {
  late Output _currentValue;
  bool _isProvided = false;
  Output get currentValue => _currentValue;
  set currentValue(Output value) {
    _currentValue = value;
    _isProvided = true;
  }

  bool get isProvided => _isProvided;
}

final class _Valuable<Output> extends Valuable<Output> {
  final ValuableParentWatcher<Output> computation;

  _Valuable.computed(
    this.computation, {
    super.evaluateWithContext = false,
    super.cleaningValueCallback,
    super.initCacheValue = const Opt.none(),
  });
  _Valuable(
    Output value, {
    ValuableValueCleaningCallback<Output>? cleaningValueCallback,
  }) : this.computed(
         (_, {valuableContext}) => value,
         cleaningValueCallback: cleaningValueCallback,
         initCacheValue: Opt.some(value),
       );

  @override
  Output getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? context,
  ]) => computation(watch, valuableContext: context);
}

/// A [Valuable] linked to a [Listenable] and will compute a value with it
final class _ValuableListenable<L extends Listenable, V> extends Valuable<V> {
  final L _listenable;
  final V Function(L) _computation;

  _ValuableListenable(
    this._listenable,
    this._computation, {
    super.cleaningValueCallback,
  }) : super(evaluateWithContext: false) {
    _listenable.addListener(markToReevaluate);
  }

  @override
  V getValueDefinition(bool reevaluatingNeeded, [ValuableContext? context]) =>
      _computation(_listenable);

  @override
  void dispose() {
    super.dispose();
    _listenable.removeListener(markToReevaluate); // Unlink from the _listenable
  }
}

enum _BoolGroupType { and, or }

/// A class to make logical operations with [Valuable<bool>]
///
/// Group some [Valuable<bool>] with a boolean operator (AND OR), to get a super-Valuable
/// that depends on them.
final class ValuableBoolGroup extends Valuable<bool> {
  final _BoolGroupType _type;

  /// All the constraints to be used in the group to determine the value
  final List<Valuable<bool>> constraints;

  ValuableBoolGroup._(this._type, this.constraints);

  /// Constructor for an AND logical group
  ValuableBoolGroup.and(List<Valuable<bool>> constraints)
    : this._(_BoolGroupType.and, constraints);

  /// Constructor for an OR logical group
  ValuableBoolGroup.or(List<Valuable<bool>> constraints)
    : this._(_BoolGroupType.or, constraints);

  @override
  @protected
  bool getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? valuableContext,
  ]) {
    bool retour = _type == _BoolGroupType.and;

    for (Valuable<bool> constraint in constraints) {
      if (_type == _BoolGroupType.and) {
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
typedef ValuableGetFutureResult<Output, Res> =
    Output Function(ValuableContext? context, Res result);

/// Method prototype for a Future error
typedef ValuableGetFutureError<Output> =
    Output Function(
      ValuableContext? context,
      Object error,
      StackTrace stackTrace,
    );

/// Method prototype to get a value while a Future is not complete/in error
typedef ValuableGetFutureLoading<Output> =
    Output Function(ValuableContext? context);

/// A Valuable that depends on a Future
///
/// This object provides a function for each state of the future, to have a value
/// that depends on it
///
/// - [dataValue] that process to return an [Output] value depends on the [Res] complete
/// response of the future
/// - [noDataValue] will return an [Output] value while the future is still incomplete
/// - [errorValue] will return an [Output] when the future complete on error
final class FutureValuable<Output, Res> extends Valuable<Output> {
  //final Future<Res> _future;
  final Valuable<Future<Res>> _valuableFuture;

  /// A function to return a value when the future is complete normally
  final ValuableGetFutureResult<Output, Res> dataValue;

  /// A function to return a value when the future is still incomplete
  final ValuableGetFutureLoading<Output> noDataValue;

  /// A function to return a value when the future is complete on error
  final ValuableGetFutureError<Output> errorValue;

  bool _isComplete = false;
  bool _isError = false;
  late Res _resultValue;
  late Object _error;
  late StackTrace _stackTrace;

  late Future<Res> _currentFuture;

  late final ValuableCallback _callback = ValuableCallback.immediate((
    watch, {
    valuableContext,
  }) {
    Future<Res> future = watch(_valuableFuture);
    _currentFuture = future;

    // Reinitialise computing value
    _isComplete = false;
    _isError = false;
    markToReevaluate();

    future.then(
      (Res value) {
        if (_currentFuture == future) {
          _isComplete = true;
          _resultValue = value;
          markToReevaluate();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (_currentFuture == future) {
          _error = error;
          _stackTrace = stackTrace;
          _isComplete = _isError = true;
          markToReevaluate();
        }
      },
    );
  });

  late final VoidCallback _unregisterListenDisposeFromCallback;

  /// Constructor to provide each functions
  FutureValuable(
    Valuable<Future<Res>> future, {
    required this.dataValue,
    required this.noDataValue,
    required this.errorValue,
    super.evaluateWithContext = false,
    super.cleaningValueCallback,
  }) : _valuableFuture = future {
    _unregisterListenDisposeFromCallback = _callback.listenDispose(dispose);
    _callback();
  }

  /// Constructor to simply map result value as Valuable value
  ///
  /// [Output] must be super type or type of [Res]
  FutureValuable.values(
    Valuable<Future<Res>> future, {
    required Output noDataValue,
    required Output errorValue,
    ValuableValueCleaningCallback<Output>? cleaningValueCallback,
  }) : this(
         future,
         dataValue: (_, Res result) => result as Output,
         noDataValue: (_) => noDataValue,
         errorValue: (_, _, _) => errorValue,
         cleaningValueCallback: cleaningValueCallback,
       );

  /// Pseudo constructor to map directly a [Res] value to an [AsyncValue<Res>]
  static FutureValuableAsyncValue<Res> asyncVal<Res>(
    Valuable<Future<Res>> future,
  ) {
    return FutureValuable<ValuableAsyncValue<Res>, Res>(
      future,
      dataValue: (_, result) => ValuableAsyncValue.data(result),
      errorValue: (_, error, stackTrace) =>
          ValuableAsyncValue.error(error, stackTrace),
      noDataValue: (_) => ValuableAsyncValue.noData(),
    );
  }

  @override
  @protected
  Output getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? context,
  ]) {
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

  @override
  void dispose() {
    super.dispose();
    _unregisterListenDisposeFromCallback();
    _callback.dispose();
  }
}

/// Equivalent to a [FutureValuable<ValuableAsyncValue<Res>, Res>]
typedef FutureValuableAsyncValue<Res> =
    FutureValuable<ValuableAsyncValue<Res>, Res>;

/// Method prototype for onData of the Stream
typedef ValuableGetStreamData<Output, Msg> =
    Output Function(ValuableContext? context, Msg data);

/// Method prototype for onError of the Stream
typedef ValuableGetStreamError<Output> =
    Output Function(
      ValuableContext? context,
      Object error,
      StackTrace stackTrace,
    );

/// Method prototype for onDone of the Stream
typedef ValuableGetStreamDone<Output> =
    Output Function(ValuableContext? context);

/// A Valuable that remains on a [Stream<Msg>]
///
/// This object provide a valuer function, for each possible state of the Stream
///
/// - [dataValue] while the Stream messaging without error
/// - [errorValue] when the Stream get an error
/// - [doneValue] when the Stream closes and is done
final class StreamValuable<Output, Msg> extends Valuable<Output> {
  /// A function to provide an [Output] value on a [Msg] message
  final ValuableGetStreamData<Output, Msg> dataValue;

  /// A function to provide an [Output] value on an error in the Stream
  final ValuableGetStreamError<Output> errorValue;

  /// A function to provide an [Output] value when the Stream closes
  final ValuableGetStreamDone<Output> doneValue;

  late final ValuableGetStreamDone<Output> _defaultValuer;

  late Output Function(ValuableContext?) _currentValuer;
  StreamSubscription? _subscription;

  final Valuable<Stream<Msg>> _valuableStream;
  late final ValuableCallback _callback = ValuableCallback.immediate((
    watch, {
    valuableContext,
  }) {
    Stream<Msg> stream = watch(_valuableStream);
    // May cancel the previous subsciption if exists
    _subscription?.cancel();

    _changeCurrentValuer(_defaultValuer);

    _subscription = stream.listen(
      (Msg data) {
        _changeCurrentValuer(
          (ValuableContext? context) => dataValue.call(context, data),
        );
      },
      onError: (Object error, StackTrace stacktrace) {
        _changeCurrentValuer(
          (ValuableContext? context) =>
              errorValue.call(context, error, stacktrace),
        );
      },
      onDone: () {
        _changeCurrentValuer(
          (ValuableContext? context) => doneValue.call(context),
        );
      },
      cancelOnError: false,
    );
  });

  late final VoidCallback _unregisterListenDisposeFromCallback;

  /// Constructor to provide each functions
  StreamValuable(
    Valuable<Stream<Msg>> stream, {
    required this.dataValue,
    required this.errorValue,
    required this.doneValue,
    required Output initialData,
    super.evaluateWithContext = false,
    super.cleaningValueCallback,
  }) : _valuableStream = stream {
    _defaultValuer = (_) => initialData;
    _unregisterListenDisposeFromCallback = _callback.listenDispose(dispose);
    _callback();
  }

  /// Constructor to simplify the case when [Output] == [Msg]
  StreamValuable.values(
    Valuable<Stream<Msg>> stream, {
    required Output errorValue,
    required Output doneValue,
    required Output initialData,
    ValuableValueCleaningCallback<Output>? cleaningValueCallback,
  }) : this(
         stream,
         dataValue: (_, Msg msg) => msg as Output,
         errorValue: (_, _, _) => errorValue,
         doneValue: (_) => doneValue,
         initialData: initialData,
         cleaningValueCallback: cleaningValueCallback,
       );

  /// Pseudo constructor to map directly a [Msg] value to an [AsyncValue<Msg>]
  static StreamValuable<ValuableAsyncValue<Msg>, Msg> asyncVal<Msg>(
    Valuable<Stream<Msg>> stream,
  ) {
    return StreamValuable(
      stream,
      dataValue: (_, data) => ValuableAsyncValue.data(data),
      errorValue: (_, error, stackTrace) =>
          ValuableAsyncValue.error(error, stackTrace),
      doneValue: (_) => ValuableAsyncValue.noData(closed: true),
      initialData: ValuableAsyncValue.noData(),
    );
  }

  void _changeCurrentValuer(Output Function(ValuableContext?) newValuer) {
    _currentValuer = newValuer;
    markToReevaluate();
  }

  @override
  @protected
  Output getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? context,
  ]) => _currentValuer(context);

  @override
  void dispose() {
    _subscription?.cancel(); // Cancel subscription to free memory
    _unregisterListenDisposeFromCallback();
    _callback.dispose();
    super.dispose();
  }
}

/// Equivalent to a [StreamValuable<ValuableAsyncValue<Res>, Res>]
typedef StreamValuableAsyncValue<Res> =
    StreamValuable<ValuableAsyncValue<Res>, Res>;
