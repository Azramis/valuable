import 'dart:async';

import 'package:valuable/src/base.dart';
import 'package:valuable/src/disposable.dart';
import 'package:valuable/src/mixins.dart';

typedef ValuableCallbackPrototype =
    void Function(ValuableWatcher watch, {ValuableContext? valuableContext});

/// User-defined callback that can watch Valuable to be automatically re-call
sealed class ValuableCallback with ValuableWatcherMixin, VDisposableMixin {
  /// The real callback to execute
  final ValuableCallbackPrototype _callback;

  /// A callback that will execute immediately after a watched [Valuable] change
  ///
  /// Once executed one time, this callback will execute immediatly
  /// each time a watched [Valuable] fires an invalidation event.
  factory ValuableCallback.immediate(ValuableCallbackPrototype callback) =
      _ValuableCallbackImmediate;

  /// A callback that schedule execution in the **microtask queue**, after a watched [Valuable] change
  ///
  /// Once executed one time, this callback will schedule execution as a microtask
  /// when any watched [Valuable] fires an invalidation event.
  factory ValuableCallback.microtask(ValuableCallbackPrototype callback) =
      _ValuableCallbackMicrotask;

  /// A callback that schedule execution in the **event queue**, after a watched [Valuable] change
  ///
  /// Once executed one time, this callback will schedule execution as an event task
  /// when any watched [Valuable] fires an invalidation event.
  factory ValuableCallback.future(ValuableCallbackPrototype callback) =
      _ValuableCallbackFuture;

  ///
  ValuableCallback._(this._callback);

  /// Allow to consider this instance as Function, so it can be used
  /// like this :
  ///
  /// ```dart
  /// final StatefulValuable<String> tracer = StatefulValuable<String>("init");
  /// final ValuableCallback printTrace = ValuableCallback(_printTrace);
  ///
  /// void _printTrace(ValuableWatcher watch, {ValuableContext valuableContext}) {
  ///   print(watch(tracer));
  /// }
  ///
  /// printTrace(); /// OUPUT : init
  /// tracer.setValue("newValue"); /// Automatically OUTPUT : newValue
  /// ```
  void call({ValuableContext? valuableContext});

  ValuableContext? _lastUsedValuableContext;

  void _internalCall({ValuableContext? valuableContext}) {
    if (isDisposed) return;

    cleanWatched();
    _lastUsedValuableContext = valuableContext ?? this.valuableContext;
    _callback(watch, valuableContext: _lastUsedValuableContext);
  }

  @override
  void onValuableChange() => call(valuableContext: _lastUsedValuableContext);

  /// Cleaning the ValuableCallback
  @override
  void disposeInternal() => cleanWatched();
}

final class _ValuableCallbackImmediate extends ValuableCallback {
  _ValuableCallbackImmediate(super._callback) : super._();

  @override
  void call({ValuableContext? valuableContext}) =>
      _internalCall(valuableContext: valuableContext);
}

final class _ValuableCallbackMicrotask extends ValuableCallback {
  _ValuableCallbackMicrotask(super._callback) : super._();

  bool _scheduled = false;

  @override
  void call({ValuableContext? valuableContext}) {
    _nextCallbackContext = valuableContext;
    if (_scheduled) return;
    _scheduled = true;
    scheduleMicrotask(_microtaskExec);
  }

  ValuableContext? _nextCallbackContext;

  void _microtaskExec() {
    _scheduled = false;
    _internalCall(valuableContext: _nextCallbackContext);
  }
}

final class _ValuableCallbackFuture extends ValuableCallback {
  _ValuableCallbackFuture(super._callback) : super._();

  @override
  void call({ValuableContext? valuableContext}) {
    _nextCallbackContext = valuableContext;
    if (_futureExecHandle != null) return;

    _futureExecHandle = Future(_futureExec).whenComplete(() {
      _futureExecHandle = null;
    });
  }

  Future<void>? _futureExecHandle;
  ValuableContext? _nextCallbackContext;

  void _futureExec() => _internalCall(valuableContext: _nextCallbackContext);
}
