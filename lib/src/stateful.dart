import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/history.dart';

/// A Valuable that manage a state.
///
/// When the value of the state changes, the valuable notify all dependant components
/// (other Valubales, Consumer, ...)
abstract class StatefulValuable<Output> extends Valuable<Output> {
  @protected
  Output get state;

  factory StatefulValuable(Output initialState) =>
      _StatefulValuableImpl(initialState);

  void setValue(Output value);

  /// Build an [HistorizedStatefulValuable] based on this Valuable
  @override
  HistorizedStatefulValuable<Output> historize();

  /// Build an [ReWritableHistorizedValuable] based on this Valuable
  ReWritableHistorizedValuable<Output> historizeRW();
}

/// Provide some method implementations to fullfil [StatefulValuable] contract
mixin StatefulValuableMixin<Output> on Valuable<Output> implements StatefulValuable<Output> {
  @override
  HistorizedStatefulValuable<Output> historize() => HistorizedStatefulValuable<Output>(this);

  @override
  ReWritableHistorizedValuable<Output> historizeRW() => ReWritableHistorizedValuable<Output>(this);

  @override
  @protected
  Output getValueDefinition(bool reevaluatingNeeded,
          [ValuableContext? context = const ValuableContext()]) =>
      state;
}

class _StatefulValuableImpl<Output> extends Valuable<Output>
    with StatefulValuableMixin<Output> {
  Output _state;

  @protected
  @override
  Output get state => _state;

  _StatefulValuableImpl(Output initialState)
      : _state = initialState,
        super();

  void setValue(Output value) {
    if (_state != value) {
      _state = value;
      markToReevaluate();
    }
  }
}
