import 'package:valuable/src/base.dart';
import 'package:valuable/src/mixins.dart';

/// User-defined callback that can watch Valuable to be automatically re-call
class ValuableCallback with ValuableWatcherMixin {
  final void Function(ValuableWatcher watch, {ValuableContext valuableContext})
      _callback;

  ValuableCallback(this._callback) : super();

  void call({ValuableContext valuableContext}) {
    cleanWatched();
    _callback(watch, valuableContext: valuableContext ?? this.valuableContext);
  }

  @override
  void onValuableChange() {
    this();
  }
}
