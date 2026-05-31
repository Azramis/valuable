import 'package:flutter/foundation.dart';

abstract interface class VDisposable {
  /// Allows to be notified when this Object is disposed
  ///
  /// [onDispose] will be called when this Object is disposed
  /// Returns a function to remove the listener
  VoidCallback listenDispose(VoidCallback onDispose);

  /// Returns if this Object is already disposed
  bool get isDisposed;

  void dispose();
}

abstract mixin class VDisposableMixin implements VDisposable {
  final _disposeListeners = <VoidCallback>{};
  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  @override
  VoidCallback listenDispose(VoidCallback onDispose) {
    if (_isDisposed) {
      throw StateError('Already disposed');
    }

    _disposeListeners.add(onDispose);
    return () => _disposeListeners.remove(onDispose);
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    try {
      disposeInternal();
    } finally {
      // To avoid concurrent modification errors, we create a snapshot of the
      // listeners before iterating them. Clear first so we always drop
      // references even if a listener throws.
      final listeners = List<VoidCallback>.from(_disposeListeners);
      _disposeListeners.clear();

      for (final listener in listeners) {
        try {
          listener();
        } catch (e, s) {
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
    }
  }

  /// Override this method to add custom dispose logic, it will be called before notifying the dispose listeners
  @protected
  @visibleForOverriding
  void disposeInternal() {}
}
