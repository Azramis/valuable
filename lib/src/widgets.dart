import 'package:flutter/scheduler.dart';
import 'package:valuable/src/mixins.dart';
import 'package:valuable/valuable.dart';

import 'base.dart';
import 'package:flutter/material.dart';

export 'widgets/text.dart';
export 'widgets/checkbox.dart';
export 'widgets/dropdown.dart';

typedef ValuableConsumerBuilder = Widget Function(
    BuildContext context, ValuableWatcher watch, Widget? child);

class ValuableConsumer extends StatefulWidget {
  final Widget? child;
  final ValuableConsumerBuilder builder;

  const ValuableConsumer({this.child, required this.builder, Key? key})
      : super(key: key);

  @override
  _ValuableConsumerState createState() => _ValuableConsumerState();

  static _ValuableConsumerState? of(BuildContext context) =>
      context.findAncestorStateOfType<_ValuableConsumerState>();
}

class _ValuableConsumerState extends State<ValuableConsumer>
    with ValuableWatcherMixin {
  bool _markNeedBuild = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // remove all previous watched Valuable
    cleanWatched();

    return Builder(
        builder: (BuildContext context) =>
            widget.builder(context, watch, widget.child));
  }

  @override
  void didUpdateWidget(ValuableConsumer old) {
    super.didUpdateWidget(old);
  }

  T _watch<T>(Valuable<T> valuable,
          {ValuableContext? valuableContext,
          ValuableWatcherSelector? selector}) =>
      watch(valuable, valuableContext: valuableContext, selector: selector);

  @override
  ValuableContext get valuableContext => ValuableContext(context: context);

  @override
  void onValuableChange() {
    if (_markNeedBuild == false) {
      _markNeedBuild = true;

      if (SchedulerBinding.instance?.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance?.addPostFrameCallback((_) {
          setState(() {
            _markNeedBuild = false;
          });
        });
      } else {
        setState(() {
          _markNeedBuild = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();

    cleanWatched();
  }
}

extension WidgetValuable<T> on Valuable<T> {
  T watchIt(BuildContext context, {ValuableWatcherSelector? selector}) {
    ValuableContext vContext = ValuableContext(context: context);
    _ValuableConsumerState? state = ValuableConsumer.of(context);

    // If a consumer exists in the current UI tree, we make it watch the current Valuable
    return state != null
        ? state._watch(this, valuableContext: vContext, selector: selector)
        : this.getValue(vContext);
  }
}
