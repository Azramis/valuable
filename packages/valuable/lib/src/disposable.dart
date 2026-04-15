import 'package:flutter/foundation.dart';

@internal
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

@internal
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
      // To avoid concurrent modification error, we create a copy of the listeners list before iterating it,
      // and we clear the original list to release references to the listeners and allow them to be garbage collected
      final listeners = List.from(_disposeListeners);
      for (final listener in listeners) {
        listener();
      }
      _disposeListeners.clear();
    }
  }

  /// Override this method to add custom dispose logic, it will be called before notifying the dispose listeners
  @protected
  @visibleForOverriding
  void disposeInternal() {}
}
