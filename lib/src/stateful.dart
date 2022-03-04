import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';

/// A Valuable that manage a state.
///
/// When the value of the state changes, the valuable notify all dependant components
/// (other Valubales, Consumer, ...)
class StatefulValuable<T> extends Valuable<T> {
  T _state;

  @protected
  T get state => _state;

  StatefulValuable(T initialState)
      : _state = initialState,
        super();

  void setValue(T value) {
    if (_state != value) {
      _state = value;
      markToReevaluate();
    }
  }

  T getValueDefinition(bool reevaluatingNeeded,
          [ValuableContext? context = const ValuableContext()]) =>
      _state;
}
