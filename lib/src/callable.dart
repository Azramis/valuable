import 'package:valuable/src/base.dart';
import 'package:valuable/src/mixins.dart';

/// User-defined callback that can watch Valuable to be automatically re-call
class ValuableCallback with ValuableWatcherMixin {
  final void Function(ValuableWatcher, ValuableContext) _callback;

  ValuableCallback(this._callback) : super();

  void call([ValuableContext context]) {
    _callback(watch, context ?? valuableContext);
  }

  @override
  void onValuableChange() {
    this();
  }
}
