import 'dart:collection';

import 'package:valuable/src/base.dart';
import 'package:valuable/src/collections.dart';
import 'package:valuable/src/linker.dart';
import 'package:valuable/src/stateful.dart';

/// Contract class for Valuable that can maintain an history
///
/// This class provide an [history] accessor, to iterate through
/// the values history. As it's a [Queue], the last element
/// represents the current value, and the first element is the
/// first value the Valuable ever was.
///
/// Good to known, a value is put in history **only** when this
/// value is read from the Valuable, and is different of the previous value
/// in history (== is used for comparison). Only exception to this rule,
/// is [StatefulValuable] that put the value in history as early
/// as the [StatefulValuable.setValue] happens too
abstract interface class HistorizedValuable<T> implements Valuable<T> {
  /// History of this Valuable
  ///
  /// An unmodifiable queue, that need to be read from the end
  /// to go back in history
  UnmodifiableQueueView<ValuableHistoryNode<T>> get history;

  factory HistorizedValuable(Valuable<T> valuable) = _HistorizedValuable<T>;
}

abstract interface class HistorizedStatefulValuable<T>
    implements StatefulValuable<T>, HistorizedValuable<T> {
  factory HistorizedStatefulValuable(StatefulValuable<T> valuable) =
      _HistorizedStatefulValuable<T>;
}

abstract interface class HistorizedValuableLinker<T>
    implements ValuableLinker<T>, HistorizedValuable<T> {
  factory HistorizedValuableLinker(ValuableLinker<T> valuable) =
      _HistorizedValuableLinker<T>;
}

mixin _HistorizedValuableMixin<T> on Valuable<T>
    implements HistorizedValuable<T> {
  Valuable<T> get _innerValuable;

  final Queue<ValuableHistoryNode<T>> _history =
      Queue<ValuableHistoryNode<T>>();

  /// Remover for the dispose-listener registered on [_innerValuable].
  ///
  /// This is used to avoid keeping a dangling listener when this wrapper
  /// is disposed before the inner valuable.
  void Function()? _innerDisposeListenerRemover;

  bool _shouldHistorize(T value) =>
      (_history.isEmpty || _history.last.value != value);

  void _historize(T value) => _history.addLast(ValuableHistoryNode<T>._(value));

  @override
  T getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? context = const ValuableContext(),
  ]) {
    T value = watch(_innerValuable, valuableContext: context);

    if (_shouldHistorize(value)) {
      _historize(value);
    }

    return value;
  }

  @override
  late final UnmodifiableQueueView<ValuableHistoryNode<T>> history =
      UnmodifiableQueueView(_history);

  @override
  void dispose() {
    // Ensure we do not keep a dangling listener on the inner valuable.
    _innerDisposeListenerRemover?.call();
    _innerDisposeListenerRemover = null;
    super.dispose();
  }

  void _registerAutodispose() {
    // Guard against multiple registrations by not re-registering if a
    // remover is already present.
    if (_innerDisposeListenerRemover != null) {
      return;
    }
    _innerDisposeListenerRemover = _innerValuable.listenDispose(dispose);
  }
}

final class _HistorizedValuable<T> extends Valuable<T>
    with _HistorizedValuableMixin<T>
    implements HistorizedValuable<T> {
  final Valuable<T> _valuable;

  _HistorizedValuable(this._valuable) {
    _registerAutodispose();
  }

  @override
  Valuable<T> get _innerValuable => _valuable;
}

final class _HistorizedStatefulValuable<T> extends Valuable<T>
    with StatefulValuableMixin<T>, _HistorizedValuableMixin<T>
    implements HistorizedStatefulValuable<T> {
  final StatefulValuable<T> _valuable;

  _HistorizedStatefulValuable(this._valuable) {
    // Historize the initial value from the StatefulValuable
    if (_shouldHistorize(_valuable.state)) {
      _historize(_valuable.state);
    }
    _registerAutodispose();
  }

  @override
  Valuable<T> get _innerValuable => _valuable;

  @override
  void setValue(T value) {
    _valuable.setValue(value);
    if (_shouldHistorize(value)) {
      _historize(value);
    }
  }

  @override
  T get state => _valuable.state;
}

final class _HistorizedValuableLinker<T> extends Valuable<T>
    with ValuableLinkerMixin<T>, _HistorizedValuableMixin<T>
    implements HistorizedValuableLinker<T> {
  final ValuableLinker<T> _valuable;

  _HistorizedValuableLinker(this._valuable) {
    _registerAutodispose();
  }

  @override
  Valuable<T> get _innerValuable => _valuable;

  @override
  T get defaultValue => _valuable.defaultValue;

  @override
  void link(Valuable<T> valuable) {
    _valuable.link(valuable);
  }

  @override
  Valuable<T>? get linkedValuable => _valuable.linkedValuable;

  @override
  void unlink([Valuable<T>? valuable]) {
    _valuable.unlink(valuable);
  }
}

/// Contract class for StatefulValuable that provide rewritable history management
///
/// Like [HistorizedValuable], this class provide an [history] accessor
/// but provide extra methods to navigate through values history too.
///
/// [canUndo] and [canRedo] allow to know if backward or forward
/// navigation in history are possible.
///
/// [undo] and [redo] apply the navigation.
///
/// Logically, [undo] can't go beyond the first value ever. The history
/// must retains its first node forever (the initial value of the Valuable)
///
/// Likewise, [redo] can't go beyond the last node in history.
///
/// Unlike [HistorizedValuable], history is setted from the [setValue]
/// so that every value can be retrieve from history.
abstract interface class ReWritableHistorizedValuable<T>
    implements HistorizedStatefulValuable<T> {
  /// Tests if [undo] or [undoToInitial] may be applied
  bool get canUndo;

  /// Tests if [redo] or [redoToCurrent] may be applied
  bool get canRedo;

  /// Go backward in history
  void undo();

  /// Go forward in history
  void redo();

  /// Go backward in history, to the initial value
  void undoToInitial();

  /// Go forward in history, to the current value
  void redoToCurrent();

  /// Current index position for the history pointer
  int get currentHistoryHead;

  factory ReWritableHistorizedValuable(StatefulValuable<T> valuable) =>
      _ReWritableHistorizedValuable<T>(valuable);
}

final class _ReWritableHistorizedValuable<T>
    extends _HistorizedStatefulValuable<T>
    implements ReWritableHistorizedValuable<T> {
  int _currentHistoryHead = -1;

  _ReWritableHistorizedValuable(super.valuable);

  @override
  int get currentHistoryHead => _currentHistoryHead;

  @override
  void setValue(T value) {
    // As we set the value, and we may be on a previous value in history tree
    // We shall reset the history that are beyond current head
    _eraseHistoryBeyondHead();
    super.setValue(value);
  }

  @override
  void _historize(T value) {
    super._historize(value);

    _currentHistoryHead =
        _history.length - 1; // Always reposition by current history length
  }

  @override
  bool _shouldHistorize(T value) =>
      (_history.isEmpty ||
      _history.elementAt(_currentHistoryHead).value != value);

  void _eraseHistoryBeyondHead() {
    while (_currentHistoryHead < (_history.length - 1)) {
      _history.removeLast();
    }
  }

  @override
  bool get canUndo => _currentHistoryHead > 0; // We can undo only if we arent on the first value ever

  @override
  bool get canRedo => (_currentHistoryHead + 1) < _history.length; // We can redo only if the history Queue is longer than the actual head position

  @override
  void undo() {
    --_currentHistoryHead; // Move the head backward
    _setValueFromHeadHistory(); // Set value from current head position
  }

  @override
  void redo() {
    ++_currentHistoryHead; // Move the head forward
    _setValueFromHeadHistory(); // Set value from current head position
  }

  @override
  void undoToInitial() {
    _currentHistoryHead = 0;
    _setValueFromHeadHistory();
  }

  @override
  void redoToCurrent() {
    _currentHistoryHead = _history.length - 1;
    _setValueFromHeadHistory();
  }

  void _setValueFromHeadHistory() {
    ValuableHistoryNode<T> node = _history.elementAt(_currentHistoryHead);
    super.setValue(
      node.value,
    ); // History will not change, as the values will be the same
  }
}

/// Valuable value representation at a certain momentum
final class ValuableHistoryNode<T> {
  /// Value
  final T value;

  /// Instant when the node was created
  final DateTime timestamp = DateTime.now();

  /// Created only by the framework
  ValuableHistoryNode._(this.value);
}
