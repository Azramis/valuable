import 'package:flutter/foundation.dart';
import 'package:valuable/src/async.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/callable.dart';
import 'package:valuable/src/operations.dart';
import 'package:valuable/src/stateful.dart';

final class ValuableScope {
  ValuableScope();

  final _disposeCalls = <VoidCallback>{};

  void dispose() {
    for (final call in _disposeCalls) {
      call();
    }
    _disposeCalls.clear();
  }

  V _scope<V extends Object>(V object) {
    switch (object) {
      case Valuable valuable:
        _disposeCalls.add(valuable.dispose);
      case ValuableCallback callback:
        _disposeCalls.add(callback.dispose);
      case ValuableScope scope:
        _disposeCalls.add(scope.dispose);
      default:
    }

    return object;
  }

  Valuable<T> value<T>(
    T value, {
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    Valuable<T>.value(value, cleaningValueCallback: cleaningValueCallback),
  );

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

  Valuable<T> listenable<T>(
    ValueListenable<T> listenable, {
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    Valuable<T>.listenable(
      listenable,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

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

  StatefulValuable<T> stateful<T>(
    T initialState, {
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    StatefulValuable<T>(
      initialState,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );

  Valuable<bool> groupAnd(Iterable<Valuable<bool>> valuables) =>
      _scope(ValuableBoolGroup.and(valuables));

  Valuable<bool> groupOr(Iterable<Valuable<bool>> valuables) =>
      _scope(ValuableBoolGroup.or(valuables));

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

  Valuable<ValuableAsyncValue<T>> futureToAsyncVal<T>(
    Valuable<Future<T>> future,
  ) => _scope(FutureValuable.asyncVal(future));

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

  Valuable<ValuableAsyncValue<T>> streamToAsyncVal<T>(
    Valuable<Stream<T>> stream,
  ) => _scope(StreamValuable.asyncVal(stream));

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

  Valuable<T> switchCase<T, S>(
    Valuable<S> switchable, {
    required ValuableParentWatcher<T> defaultCase,
    List<ValuableCaseItem<S, T>>? cases,
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
    bool evaluateCasesWithContext = false,
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

  Valuable<T> switchCaseValue<T, S>(
    Valuable<S> switchable, {
    required T defaultCase,
    List<ValuableCaseItem<S, T>>? cases,
    ValuableValueCleaningCallback<T>? cleaningValueCallback,
  }) => _scope(
    ValuableSwitch.value(
      switchable,
      cases: cases,
      defaultValue: defaultCase,
      cleaningValueCallback: cleaningValueCallback,
    ),
  );
}
