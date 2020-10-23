import 'base.dart';
import 'package:flutter/material.dart';

typedef ValuableWatcher<T> = T Function(Valuable);
typedef ValuableConsumerBuilder = Widget Function(
    BuildContext, ValuableWatcher, Widget);

class ValuableConsumer extends StatefulWidget {
  final Widget child;
  final ValuableConsumerBuilder builder;

  const ValuableConsumer({this.child, this.builder, Key key}) : super(key: key);

  @override
  _ValuableConsumerState createState() => _ValuableConsumerState();

  static _ValuableConsumerState of(BuildContext context) =>
      context?.findAncestorStateOfType<_ValuableConsumerState>();
}

class _ValuableConsumerState extends State<ValuableConsumer> {
  final Map<Valuable, VoidCallback> _watched = <Valuable, VoidCallback>{};
  bool _markNeedBuild = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
        builder: (BuildContext context) =>
            widget.builder(context, _watch, widget.child));
  }

  @override
  void didUpdateWidget(ValuableConsumer old) {
    super.didUpdateWidget(old);

    // remove all previous watched Valuable
    _cleanWatched();
  }

  /// Watch a valuable, that eventually change
  T _watch<T>(Valuable<T> valuable) {
    if (valuable != null && !_watched.containsKey(valuable)) {
      VoidCallback callback = _onValuableChange;

      _watched.putIfAbsent(valuable, () => callback);
      valuable.addListener(callback);
      valuable.listenDispose(() {
        _unwatch(valuable);
      });
    }

    return valuable.getValue(context);
  }

  /// Remove listener on the valuable, that may change scope, or that about to be disposed
  /// Internal purpose
  void _unwatch(Valuable valuable) {
    if (_watched.containsKey(valuable)) {
      //valuable.removeListener(_watched[valuable]); Not necessary until dispose has been done
      _watched.remove(valuable);
    }
  }

  void _onValuableChange() {
    if (_markNeedBuild == false) {
      _markNeedBuild = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _markNeedBuild = false;
        });
      });
    }
  }

  @override
  void dispose() {
    super.dispose();

    _cleanWatched();
  }

  void _cleanWatched() {
    _watched.forEach((Valuable key, VoidCallback value) {
      key?.removeListener(value);
    });
    _watched.clear();
  }
}

extension WidgetValuable<T> on Valuable<T> {
  T watch(BuildContext context) {
    _ValuableConsumerState state = ValuableConsumer.of(context);

    // If a consumer exists in the current UI tree, we make it watch the current Valuable
    state?._watch(this);
    return getValue(context);
  }
}
