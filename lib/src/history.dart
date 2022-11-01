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
abstract class HistorizedValuable<T> implements Valuable<T> {
  /// History of this Valuable
  ///
  /// An unmodifiable queue, that need to be read from the end
  /// to go back in history
  UnmodifiableQueueView<ValuableHistoryNode<T>> get history;

  factory HistorizedValuable(Valuable<T> valuable) =>
      _HistorizedValuable<T>(valuable);
}

abstract class HistorizedStatefulValuable<T>
    implements StatefulValuable<T>, HistorizedValuable<T> {
  factory HistorizedStatefulValuable(StatefulValuable<T> valuable) =>
      _HistorizedStatefulValuable<T>(valuable);
}

abstract class HistorizedValuableLinker<T>
    implements ValuableLinker<T>, HistorizedValuable<T> {
  factory HistorizedValuableLinker(ValuableLinker<T> valuable) =>
      _HistorizedValuableLinker<T>(valuable);
}

mixin _HistorizedValuableMixin<T> on Valuable<T> {
  Valuable<T> get _innerValuable;

  final Queue<ValuableHistoryNode<T>> _history =
      Queue<ValuableHistoryNode<T>>();

  bool _shouldHistorize(T value) =>
      (_history.isEmpty || _history.last.value != value);

  void _historize(T value) => _history.addLast(ValuableHistoryNode<T>._(value));

  @override
  T getValueDefinition(bool reevaluatingNeeded,
      [ValuableContext? context = const ValuableContext()]) {
    T value = watch(_innerValuable, valuableContext: context);

    if (_shouldHistorize(value)) {
      _historize(value);
    }

    return value;
  }

  UnmodifiableQueueView<ValuableHistoryNode<T>> get history =>
      UnmodifiableQueueView(_history);

  void _registerAutodispose() {
    _innerValuable.listenDispose(dispose);
  }
}

class _HistorizedValuable<T> extends Valuable<T>
    with _HistorizedValuableMixin<T>
    implements HistorizedValuable<T> {
  final Valuable<T> _valuable;

  _HistorizedValuable(this._valuable) {
    _registerAutodispose();
  }

  @override
  Valuable<T> get _innerValuable => _valuable;
}

class _HistorizedStatefulValuable<T> extends Valuable<T>
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

class _HistorizedValuableLinker<T> extends Valuable<T>
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
  void unlink() {
    _valuable.unlink();
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
abstract class ReWritableHistorizedValuable<T>
    implements HistorizedStatefulValuable<T> {
  /// Tests if [undo] may be applied
  bool get canUndo;

  /// Tests if [redo] may be applied
  bool get canRedo;

  /// Go backward in history
  void undo();

  /// Go forward in history
  void redo();

  /// Current index position for the history pointer
  int get currentHistoryHead;

  factory ReWritableHistorizedValuable(StatefulValuable<T> valuable) =>
      _ReWritableHistorizedValuable<T>(valuable);
}

class _ReWritableHistorizedValuable<T> extends _HistorizedStatefulValuable<T>
    implements ReWritableHistorizedValuable<T> {
  int _currentHistoryHead = -1;

  _ReWritableHistorizedValuable(StatefulValuable<T> valuable) : super(valuable);

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
  bool _shouldHistorize(T value) => (_history.isEmpty ||
      _history.elementAt(_currentHistoryHead).value != value);

  void _eraseHistoryBeyondHead() {
    while (_currentHistoryHead < (_history.length - 1)) {
      _history.removeLast();
    }
  }

  bool get canUndo =>
      _currentHistoryHead >
      0; // We can undo only if we arent on the first value ever

  bool get canRedo =>
      (_currentHistoryHead + 1) <
      _history
          .length; // We can redo only if the history Queue is longer than the actual head position

  void undo() {
    --_currentHistoryHead; // Move the head backward
    _setValueFromHeadHistory(); // Set value from current head position
  }

  void redo() {
    ++_currentHistoryHead; // Move the head forward
    _setValueFromHeadHistory(); // Set value from current head position
  }

  void _setValueFromHeadHistory() {
    ValuableHistoryNode<T> node = _history.elementAt(_currentHistoryHead);
    super.setValue(
        node.value); // History will not change, as the values will be the same
  }
}

/// Valuable value representation at a certain momentum
class ValuableHistoryNode<T> {
  /// Value
  final T value;

  /// Instant when the node was created
  final DateTime timestamp = DateTime.now();

  /// Created only by the framework
  ValuableHistoryNode._(this.value);
}
