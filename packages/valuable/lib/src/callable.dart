import 'dart:async';

import 'package:valuable/src/base.dart';
import 'package:valuable/src/mixins.dart';

typedef ValuableCallbackPrototype = void Function(ValuableWatcher watch,
    {ValuableContext? valuableContext});

/// User-defined callback that can watch Valuable to be automatically re-call
abstract class ValuableCallback with ValuableWatcherMixin {
  /// The real callback to execute
  final ValuableCallbackPrototype _callback;

  /// This factory only continues existing for backward compatibility.
  /// Will be removed in a future release
  ///
  /// Default implementation [ValuableCallback.immediate] for backward compatibility
  @deprecated
  factory ValuableCallback(ValuableCallbackPrototype callback) =>
      ValuableCallback.immediate(callback);

  /// A callback that will execute immediately after a watched [Valuable] change
  ///
  /// Once executed one time, this callback will execute immediatly
  /// each time a watched [Valuable] fires an invalidation event.
  factory ValuableCallback.immediate(ValuableCallbackPrototype callback) =>
      _ValuableCallbackImmediate(callback);

  /// A callback that schedule execution in the **microtask queue**, after a watched [Valuable] change
  ///
  /// Once executed one time, this callback will schedule execution as a microtask
  /// when any watched [Valuable] fires an invalidation event.
  factory ValuableCallback.microtask(ValuableCallbackPrototype callback) =>
      _ValuableCallbackMicrotask(callback);

  /// A callback that schedule execution in the **event queue**, after a watched [Valuable] change
  ///
  /// Once executed one time, this callback will schedule execution as an event task
  /// when any watched [Valuable] fires an invalidation event.
  factory ValuableCallback.future(ValuableCallbackPrototype callback) =>
      _ValuableCallbackFuture(callback);

  ///
  ValuableCallback._(this._callback) : super();

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

  void _internalCall({ValuableContext? valuableContext}) {
    cleanWatched();
    _callback(watch, valuableContext: valuableContext ?? this.valuableContext);
  }

  @override
  void onValuableChange() {
    this();
  }

  /// Cleaning the ValuableCallback
  void dispose() {
    cleanWatched();
  }
}

class _ValuableCallbackImmediate extends ValuableCallback {
  _ValuableCallbackImmediate(
    void Function(ValuableWatcher watch, {ValuableContext? valuableContext})
        _callback,
  ) : super._(_callback);

  @override
  void call({ValuableContext? valuableContext}) =>
      _internalCall(valuableContext: valuableContext);
}

class _ValuableCallbackMicrotask extends ValuableCallback {
  _ValuableCallbackMicrotask(
    void Function(ValuableWatcher watch, {ValuableContext? valuableContext})
        _callback,
  ) : super._(_callback);

  @override
  void call({ValuableContext? valuableContext}) {
    _nextCallbackContext = valuableContext;
    scheduleMicrotask(_microtaskExec);
  }

  ValuableContext? _nextCallbackContext;

  void _microtaskExec() => _internalCall(valuableContext: _nextCallbackContext);
}

class _ValuableCallbackFuture extends ValuableCallback {
  _ValuableCallbackFuture(
    void Function(ValuableWatcher watch, {ValuableContext? valuableContext})
        _callback,
  ) : super._(_callback);

  @override
  void call({ValuableContext? valuableContext}) {
    _nextCallbackContext = valuableContext;
    if (_futureExecHandle != null) return;

    _futureExecHandle =
        Future(_futureExec).then((_) => _futureExecHandle == null);
  }

  Future<void>? _futureExecHandle;
  ValuableContext? _nextCallbackContext;

  void _futureExec() => _internalCall(valuableContext: _nextCallbackContext);
}
