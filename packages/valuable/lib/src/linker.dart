import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/extensions.dart';
import 'package:valuable/src/history.dart';

/// A special Valuable that can link to another Valuable to provide a value
///
/// When unlinked, the value provided is the [defaultValue].
///
/// Otherwise, it watch the linked Valuable to provide its value.
abstract class ValuableLinker<Output> extends Valuable<Output> {
  @protected
  Valuable<Output>? get linkedValuable;

  @protected
  Output get defaultValue;

  /// Link to a Valuable
  void link(Valuable<Output> valuable);

  /// Unlink from the Valuable
  void unlink();

  factory ValuableLinker(Output defaultValue) =>
      _ValuableLinkerImpl<Output>(defaultValue);
}

/// Provide some method implementations to fullfil [ValuableLinker] contract
mixin ValuableLinkerMixin<Output> on Valuable<Output>
    implements ValuableLinker<Output> {
  @override
  Output getValueDefinition(bool reevaluatingNeeded,
      [ValuableContext? context = const ValuableContext()]) {
    return watch.def(linkedValuable, defaultValue,
        valuableContext: valuableContext);
  }

  @override
  HistorizedValuableLinker<Output> historize() =>
      HistorizedValuableLinker<Output>(this);
}

class _ValuableLinkerImpl<Output> extends Valuable<Output>
    with ValuableLinkerMixin<Output> {
  Valuable<Output>? _linkedValuable;

  final Output _defaultValue;

  _ValuableLinkerImpl(this._defaultValue) : super();

  @protected
  @override
  Output get defaultValue => _defaultValue;

  @protected
  @override
  Valuable<Output>? get linkedValuable => _linkedValuable;

  @override
  void link(Valuable<Output> valuable) {
    if (_linkedValuable != null) {
      throw StateError(
        "A valuable is already linked ! You must unlink before linking to another Valuable",
      );
    }
    _linkedValuable = valuable;
    _linkedValuable!.listenDispose(
        unlink); // Listen Valuable dispose, to automatically unlink
    markToReevaluate(); // We have linked a Valuable, the linker may change its value
  }

  @override
  void unlink() {
    cleanWatched(); // Remove the listener
    _linkedValuable = null; // Detach the Valuate
    markToReevaluate(); // The linker returns to its default value
  }
}
