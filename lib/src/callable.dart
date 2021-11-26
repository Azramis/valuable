import 'package:valuable/src/base.dart';
import 'package:valuable/src/mixins.dart';

/// User-defined callback that can watch Valuable to be automatically re-call
class ValuableCallback with ValuableWatcherMixin {
  /// The real callback to execute
  final void Function(ValuableWatcher watch, {ValuableContext? valuableContext})
      _callback;

  ///
  ValuableCallback(this._callback) : super();

  /// Allow to consider this instance as Function, so it can be used
  /// like this :
  ///
  /// ```dart
  /// final StatefulValuable<String> tracer = StatefulValuable<String>("init");
  /// final ValuableCallback printTrace = ValuableCallback(_printTrace);
  ///
  /// void _printTrace(ValuableWatcher watch, {ValuableContext valuableContext}) {
  ///   print(watch(tracer));
  /// }
  ///
  /// printTrace(); /// OUPUT : init
  /// tracer.setValue("newValue"); /// Automatically OUTPUT : newValue
  /// ```
  void call({ValuableContext? valuableContext}) {
    cleanWatched();
    _callback(watch, valuableContext: valuableContext ?? this.valuableContext);
  }

  @override
  void onValuableChange() {
    this();
  }
}
