import 'package:flutter/foundation.dart';
import 'package:valuable/src/async.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/callable.dart';
import 'package:valuable/src/disposable.dart';
import 'package:valuable/src/linker.dart';
import 'package:valuable/src/operations.dart';
import 'package:valuable/src/stateful.dart';

/// A class to manage the lifecycle of multiple valuables and callbacks, and dispose them all together when needed
///
/// A scope can be useful to manage the lifecycle of valuables and callbacks in a specific part of the application,
/// for example in a widget, a service, or any other entity that needs to create valuables and callbacks and dispose them when they are no longer needed.
///
/// By using a scope, you can ensure that all the valuables and callbacks created within the scope are properly disposed when the scope is disposed,
/// preventing memory leaks and ensuring that resources are properly released.
final class ValuableScope with VDisposableMixin {
  ValuableScope();

  final _disposables = <VDisposable, VoidCallback>{};

  /// Dispose all the scoped entities, and call all the registered dispose callbacks
  @override
  void disposeInternal() {
    Object? firstError;
    StackTrace? firstStackTrace;

    try {
      final entries = List<MapEntry<VDisposable, VoidCallback>>.from(
        _disposables.entries,
      );
      for (final entry in entries) {
        if (entry.key.isDisposed) continue;

        // Begin by removing the listener to prevent any new callback from being called during the dispose process, then dispose the object itself
        try {
          entry.value();
        } catch (e, s) {
          firstError ??= e;
          firstStackTrace ??= s;

          FlutterError.reportError(
            FlutterErrorDetails(
              exception: e,
              stack: s,
              library: 'valuable',
              context: ErrorDescription(
                'while removing dispose listener during disposal of ${entry.key}',
              ),
              informationCollector: () => <DiagnosticsNode>[
                DiagnosticsProperty<VDisposable>('disposable', entry.key),
              ],
            ),
          );
        }

        try {
          entry.key.dispose();
        } catch (e, s) {
          firstError ??= e;
          firstStackTrace ??= s;

          FlutterError.reportError(
            FlutterErrorDetails(
              exception: e,
              stack: s,
              library: 'valuable',
              context: ErrorDescription('while disposing ${entry.key}'),
              informationCollector: () => <DiagnosticsNode>[
                DiagnosticsProperty<VDisposable>('disposable', entry.key),
              ],
            ),
          );
        }
      }
    } finally {
      // Clear the disposables map to release references to the disposed objects and callbacks
      _disposables.clear();
    }

    if (firstError != null) {
      Error.throwWithStackTrace(
        firstError,
        firstStackTrace ?? StackTrace.current,
      );
    }
  }

  V _scope<V extends VDisposable>(V disposable) {
    if (isDisposed) {
      throw StateError('ValuableScope has been disposed');
    }

    if (disposable.isDisposed) {
      throw StateError('Cannot add a disposed object to the scope');
    }

    // Listen to the dispose event of the object, and remove it from the disposables map when it is disposed
    _disposables.putIfAbsent(
      disposable,
      // Listen only if the disposable is not already in the map, to avoid listening multiple times to the same object in case of multiple calls to _scope with the same object
      () => disposable.listenDispose(() => _disposables.remove(disposable)),
    );

    return disposable;
  }

  /// See [Valuable.value]
  Valuable<T> value<T>(
    T value, {
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    Valuable<T>.value(value, cleaningValueCallback: cleaningValueCallback),
  );

  /// See [Valuable.computed]
  Valuable<T> computed<T>(
    ValuableParentWatcher<T> compute, {
    bool evaluateWithContext = false,
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    Valuable<T>.computed(
      compute,
      evaluateWithContext: evaluateWithContext,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  /// See [Valuable.listenable]
  Valuable<T> listenable<T>(
    ValueListenable<T> listenable, {
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    Valuable<T>.listenable(
      listenable,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  /// See [Valuable.listenableComputed]
  Valuable<T> listenableComputed<L extends Listenable, T>(
    L listenable,
    T Function(L listenable) computation, {
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    Valuable.listenableComputed(
      listenable,
      computation,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  /// See [StatefulValuable]
  StatefulValuable<T> stateful<T>(
    T initialState, {
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    StatefulValuable<T>(
      initialState,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  /// See [ValuableBoolGroup.and]
  Valuable<bool> groupAnd(List<Valuable<bool>> valuables) =>
      _scope(ValuableBoolGroup.and(valuables));

  /// See [ValuableBoolGroup.or]
  Valuable<bool> groupOr(List<Valuable<bool>> valuables) =>
      _scope(ValuableBoolGroup.or(valuables));

  /// See [FutureValuable]
  Valuable<T> future<T, R>(
    Valuable<Future<R>> future, {
    required ValuableGetFutureResult<T, R> dataValue,
    required ValuableGetFutureLoading<T> noDataValue,
    required ValuableGetFutureError<T> errorValue,
    bool evaluateWithContext = false,
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    FutureValuable<T, R>(
      future,
      dataValue: dataValue,
      noDataValue: noDataValue,
      errorValue: errorValue,
      evaluateWithContext: evaluateWithContext,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  /// See [FutureValuable.values]
  Valuable<T> futureToValues<T, R>(
    Valuable<Future<R>> future, {
    required T noDataValue,
    required T errorValue,
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    FutureValuable<T, R>.values(
      future,
      noDataValue: noDataValue,
      errorValue: errorValue,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  /// See [FutureValuable.asyncVal]
  Valuable<ValuableAsyncValue<T>> futureToAsyncVal<T>(
    Valuable<Future<T>> future,
  ) => _scope(FutureValuable.asyncVal(future));

  /// See [StreamValuable]
  Valuable<T> stream<T, R>(
    Valuable<Stream<R>> stream, {
    required ValuableGetStreamData<T, R> dataValue,
    required ValuableGetStreamError<T> errorValue,
    required ValuableGetStreamDone<T> doneValue,
    required T initialData,
    bool evaluateWithContext = false,
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    StreamValuable<T, R>(
      stream,
      dataValue: dataValue,
      errorValue: errorValue,
      doneValue: doneValue,
      initialData: initialData,
      evaluateWithContext: evaluateWithContext,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  /// See [StreamValuable.values]
  Valuable<T> streamToValues<T, R>(
    Valuable<Stream<R>> stream, {
    required T initialData,
    required T errorValue,
    required T doneValue,
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    StreamValuable<T, R>.values(
      stream,
      initialData: initialData,
      errorValue: errorValue,
      doneValue: doneValue,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  /// See [StreamValuable.asyncVal]
  Valuable<ValuableAsyncValue<T>> streamToAsyncVal<T>(
    Valuable<Stream<T>> stream,
  ) => _scope(StreamValuable.asyncVal(stream));

  /// See [ValuableIf]
  Valuable<T> ifThen<T>(
    Valuable<bool> testable,
    ValuableParentWatcher<T> thenCase, {
    required ValuableParentWatcher<T> elseCase,
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
    bool evaluateThenCaseWithContext = false,
    bool evaluateElseCaseWithContext = false,
  }) => _scope(
    ValuableIf(
      testable,
      thenCase,
      elseCase: elseCase,
      cleaningValueCallback: cleaningValueCallback,
      evaluateThenCaseWithContext: evaluateThenCaseWithContext,
      evaluateElseCaseWithContext: evaluateElseCaseWithContext,
    ),
  );

  /// See [ValuableIf.value]
  Valuable<T> ifThenValue<T>(
    Valuable<bool> testable,
    T thenValue, {
    required T elseValue,
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    ValuableIf.value(
      testable,
      thenValue,
      elseValue: elseValue,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  /// See [ValuableSwitch]
  Valuable<T> switchCase<T, S>(
    Valuable<S> switchable, {
    required ValuableParentWatcher<T> defaultCase,
    List<ValuableCaseItem<S, T>> cases = const [],
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
    bool evaluateDefaultCaseWithContext = false,
  }) => _scope(
    ValuableSwitch(
      switchable,
      cases: cases,
      defaultCase: defaultCase,
      cleaningValueCallback: cleaningValueCallback,
      evaluateDefaultCaseWithContext: evaluateDefaultCaseWithContext,
    ),
  );

  /// See [ValuableSwitch.value]
  Valuable<T> switchCaseValue<T, S>(
    Valuable<S> switchable, {
    required T defaultCase,
    List<ValuableCaseItem<S, T>> cases = const [],
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    ValuableSwitch.value(
      switchable,
      cases: cases,
      defaultValue: defaultCase,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  /// See [ValuableCallback.immediate]
  ValuableCallback callback(ValuableCallbackPrototype callback) =>
      _scope(ValuableCallback.immediate(callback));

  /// See [ValuableCallback.future]
  ValuableCallback futureCallback(ValuableCallbackPrototype callback) =>
      _scope(ValuableCallback.future(callback));

  /// See [ValuableCallback.microtask]
  ValuableCallback microtaskCallback(ValuableCallbackPrototype callback) =>
      _scope(ValuableCallback.microtask(callback));

  /// See [ValuableLinker]
  ValuableLinker<T> linker<T>(T defaultValue) =>
      _scope(ValuableLinker<T>(defaultValue));

  /// Build a nested scope, that will be automatically disposed when the parent scope is disposed
  ///
  /// See [ValuableScope] for more details about scopes
  ValuableScope nestedScope() => _scope(ValuableScope());
}
