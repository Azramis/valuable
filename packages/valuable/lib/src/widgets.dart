import 'package:flutter/scheduler.dart';
import 'package:valuable/src/mixins.dart';
import 'package:valuable/src/utils.dart';
import 'package:valuable/valuable.dart';

import 'base.dart';
import 'package:flutter/material.dart';

/// Contract for the implementation function needed to build [Widget] for a [ValuableConsumer]
typedef ValuableConsumerBuilder = Widget Function(
    BuildContext context, ValuableWatcher watch, Widget? child);

/// A widget that is used to watch [Valuable] inside a widget tree
///
/// It allows to re-build only certain part of a complete widget tree, instead
/// of calling [State.setState] and re-execute all of the [State.build] method
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

    // remove all previous watched Valuable
    //cleanWatched();
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

      if (mitigate(SchedulerBinding.instance)?.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        mitigate(WidgetsBinding.instance)?.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _markNeedBuild = false;
            });
          }
        });
      } else if (mounted) {
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

abstract class ValuableWidget extends Widget {
  const ValuableWidget({Key? key}) : super(key: key);
  @override
  Element createElement() => ValuableWidgetElement(this);

  Widget build(BuildContext context, ValuableWatcher watch);
}

class ValuableWidgetElement extends ComponentElement with ValuableWatcherMixin {
  bool _mounted = false;

  /// Creates an element that uses the given widget as its configuration.
  ValuableWidgetElement(ValuableWidget widget) : super(widget);

  @override
  Widget build() => (widget as ValuableWidget).build(this, this.watch);

  @override
  void onValuableChange() {
    if (mitigate(SchedulerBinding.instance)?.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      mitigate(WidgetsBinding.instance)?.addPostFrameCallback((_) {
        if (_mounted) {
          markNeedsBuild();
        }
      });
    } else if (_mounted) {
      markNeedsBuild();
    }
  }

  @protected
  ValuableContext get valuableContext => ValuableContext(context: this);

  @override
  @mustCallSuper
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _mounted = true;
  }

  @override
  @mustCallSuper
  void unmount() {
    super.unmount();

    _mounted = false;

    // When the element is unmounted, it should clean all listened Valuable
    // to avoid error-prone callback from Valuable update
    cleanWatched();
  }
}
