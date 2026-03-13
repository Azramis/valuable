import 'package:flutter/scheduler.dart';
import 'package:valuable/src/mixins.dart';
import 'package:valuable/valuable.dart';

import 'base.dart';
import 'package:flutter/material.dart';

/// Contract for the implementation function needed to build [Widget] for a [ValuableConsumer]
typedef ValuableConsumerBuilder =
    Widget Function(BuildContext context, ValuableWatcher watch, Widget? child);

/// A widget that is used to watch [Valuable] inside a widget tree
///
/// It allows to re-build only certain part of a complete widget tree, instead
/// of calling [State.setState] and re-execute all of the [State.build] method
class ValuableConsumer extends StatefulWidget {
  final Widget? child;
  final ValuableConsumerBuilder builder;

  const ValuableConsumer({this.child, required this.builder, super.key});

  @override
  State<ValuableConsumer> createState() => _ValuableConsumerState();

  static _ValuableConsumerState? _maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<_ValuableConsumerState>();
}

class _ValuableConsumerState extends State<ValuableConsumer>
    with ValuableWatcherMixin {
  bool _markNeedBuild = false;

  @override
  Widget build(BuildContext context) {
    // remove all previous watched Valuable
    cleanWatched();

    return Builder(
      builder: (BuildContext context) =>
          widget.builder(context, watch, widget.child),
    );
  }

  T _watch<T>(
    Valuable<T> valuable, {
    ValuableContext? valuableContext,
    ValuableWatcherSelector? selector,
  }) => watch(valuable, valuableContext: valuableContext, selector: selector);

  @override
  ValuableContext get valuableContext => ValuableContext(context: context);

  @override
  void onValuableChange() {
    if (_markNeedBuild == false) {
      _markNeedBuild = true;

      void callback(_) {
        if (mounted) {
          setState(() {
            _markNeedBuild = false;
          });
        }
      }

      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback(callback);
      } else {
        callback(null);
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
    final vContext = ValuableContext(context: context);
    final state = ValuableConsumer._maybeOf(context);

    // If a consumer exists in the current UI tree, we make it watch the current Valuable
    return state != null
        ? state._watch(this, valuableContext: vContext, selector: selector)
        : getValue(vContext);
  }
}

abstract class ValuableWidget extends Widget {
  const ValuableWidget({super.key});
  @override
  Element createElement() => ValuableWidgetElement(this);

  Widget build(BuildContext context, ValuableWatcher watch);
}

class ValuableWidgetElement extends ComponentElement with ValuableWatcherMixin {
  bool _mounted = false;

  /// Creates an element that uses the given widget as its configuration.
  ValuableWidgetElement(ValuableWidget super.widget);

  @override
  Widget build() {
    // remove all previous watched Valuable
    cleanWatched();
    return (widget as ValuableWidget).build(this, watch);
  }

  @override
  void onValuableChange() {
    void callback(_) {
      if (_mounted) {
        markNeedsBuild();
      }
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback(callback);
    } else {
      callback(null);
    }
  }

  @protected
  @override
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

  @override
  void update(ValuableWidget newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    markNeedsBuild();
  }
}
