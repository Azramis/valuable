import 'package:meta/meta.dart';
import 'package:valuable/src/base.dart';

/// Provide a safe representation of an async value
///
/// Inspired by the AsyncValue<T> from **Riverpod**, this object may be
/// used by [FutureValuable] or [StreamValuable] to provide a value depending
/// on current state
@immutable
abstract class ValuableAsyncValue<T> {
  const ValuableAsyncValue._();

  /// Provide an async value with a data
  factory ValuableAsyncValue.data(T data) => ValuableAsyncData._(data);

  /// Provide an async value from an error
  factory ValuableAsyncValue.error(Object error, StackTrace stackTrace) =>
      ValuableAsyncError._(error, stackTrace);

  /// Provide an async value from a no data momentum
  ///
  /// It may specify that's from a stream closing
  factory ValuableAsyncValue.noData({bool closed = false}) =>
      ValuableAsyncNoData._(closed: closed);

  /// Method to provide a value, depending of current async value type
  Output map<Output>({
    required Output Function(ValuableAsyncData<T> data) onData,
    required Output Function(ValuableAsyncError<T> error) onError,
    required Output Function(ValuableAsyncNoData<T> noData) onNoData,
  });
}

/// Representation of a valid data provided by an async process (Future, Stream, ...)
@immutable
class ValuableAsyncData<T> extends ValuableAsyncValue<T> {
  /// Current async data
  final T data;

  const ValuableAsyncData._(this.data) : super._();

  @override
  Output map<Output>({
    required Output Function(ValuableAsyncData<T> data) onData,
    required Output Function(ValuableAsyncError<T> error) onError,
    required Output Function(ValuableAsyncNoData<T> noData) onNoData,
  }) =>
      onData(this);
}

/// Representation of an error that occured during an async process
@immutable
class ValuableAsyncError<T> extends ValuableAsyncValue<T> {
  /// Stack trace provided with the error
  final StackTrace stackTrace;

  /// Current error that occured
  final Object error;

  const ValuableAsyncError._(this.error, this.stackTrace) : super._();

  @override
  Output map<Output>({
    required Output Function(ValuableAsyncData<T> data) onData,
    required Output Function(ValuableAsyncError<T> error) onError,
    required Output Function(ValuableAsyncNoData<T> noData) onNoData,
  }) =>
      onError(this);
}

/// Representation of a momentum when no data is provided, and no error occured
///
/// In case of async process from a Stream, this type of async value can be provided
/// after a valid data or an error
@immutable
class ValuableAsyncNoData<T> extends ValuableAsyncValue<T> {
  /// Indicates whether this state came from a closing stream or not
  final bool closed;

  const ValuableAsyncNoData._({
    this.closed = false,
  }) : super._();

  @override
  Output map<Output>({
    required Output Function(ValuableAsyncData<T> data) onData,
    required Output Function(ValuableAsyncError<T> error) onError,
    required Output Function(ValuableAsyncNoData<T> noData) onNoData,
  }) =>
      onNoData(this);
}
