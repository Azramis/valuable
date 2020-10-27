import 'package:valuable/src/base.dart';

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
