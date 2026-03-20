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
      for (final listener in _disposeListeners) {
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
