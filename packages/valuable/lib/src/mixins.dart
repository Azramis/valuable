import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/scope.dart';

class _ValuableWatchedInfos<T> {
  final VoidCallback removeValueListener;
  final VoidCallback removeDisposeListener;
  final List<ValuableWatcherSelector<T>> selectors;
  T previousWatchedValue;
  bool evaluateWithContext;

  _ValuableWatchedInfos({
    required this.removeValueListener,
    required this.removeDisposeListener,
    required this.previousWatchedValue,
    List<ValuableWatcherSelector<T>>? selectors,
    this.evaluateWithContext = false,
  }) : selectors = selectors ?? <ValuableWatcherSelector<T>>[];

  void dispose() {
    removeValueListener();
    removeDisposeListener();
  }
}

/// A mixin to provide extension of classes that might want to watch some valuable
/// and take action on possible changes
mixin ValuableWatcherMixin {
  final Map<Valuable, _ValuableWatchedInfos> _watched =
      <Valuable, _ValuableWatchedInfos>{};

  @protected
  @visibleForOverriding
  @mustCallSuper
  bool get evaluateWithContext =>
      _watched.values.any((infos) => infos.evaluateWithContext);

  /// Watch a valuable, that eventually change
  @protected
  @mustCallSuper
  T watch<T>(
    Valuable<T> valuable, {
    ValuableContext? valuableContext,
    ValuableWatcherSelector<T>? selector,
  }) {
    final result = valuable.getValue(valuableContext ?? this.valuableContext);

    _watched.update(
      valuable,
      (infos) {
        if (infos is _ValuableWatchedInfos<T>) {
          infos.evaluateWithContext = valuable.evaluateWithContext;
          infos.previousWatchedValue =
              result; // Save value for future comparaison
          if (selector != null) {
            infos.selectors.add(selector);
          }
        }

        return infos;
      },
      ifAbsent: () {
        void callback() => _callValuableChange<T>(valuable);
        valuable.addListener(callback);

        final removeListener = valuable.listenDispose(() {
          _unwatch(valuable);
          onWatchedValuableDispose(valuable);
        });

        return _ValuableWatchedInfos<T>(
          removeValueListener: () => valuable.removeListener(callback),
          removeDisposeListener: removeListener,
          previousWatchedValue: result,
          selectors: [?selector],
          evaluateWithContext: valuable.evaluateWithContext,
        );
      },
    );

    return result;
  }

  /// Remove listener on the valuable, that may change scope, or that about to be disposed
  void _unwatch(Valuable valuable) => _watched.remove(valuable)?.dispose();

  /// Allows inheriting classes to react when a watched Valuable is disposed.
  @protected
  @visibleForOverriding
  void onWatchedValuableDispose(Valuable valuable) {}

  void _callValuableChange<T>(Valuable<T> valuable) {
    if (_watched.containsKey(valuable)) {
      if (_watched[valuable] != null) {
        final infos = _watched[valuable] as _ValuableWatchedInfos<T>;

        bool selectOk;

        final selectors = infos.selectors;

        if (selectors.isNotEmpty) {
          // If there are available selectors, we must test them until [selectOk]
          // is true, or we reach the end of the list

          selectOk = false;
          T previousWatchedValue = infos.previousWatchedValue;
          for (final selector in selectors) {
            selectOk =
                selectOk || selector.call(valuable, previousWatchedValue);

            if (selectOk) {
              break;
            }
          }
        } else {
          selectOk = true;
        }

        // valuable change will be dispatched only if all conditions are resolved
        if (selectOk) {
          onValuableChange();
        }
      }
    }
  }

  /// Called when a Valuable notify a change.
  ///
  /// This method should be overriden to define the implementor behavior
  @protected
  @visibleForOverriding
  void onValuableChange();

  @protected
  @visibleForOverriding
  ValuableContext? get valuableContext => null;

  @protected
  void cleanWatched() {
    for (final infos in _watched.values) {
      infos.dispose();
    }

    _watched.clear();
  }
}

typedef ValuableStatefulWidgetParam<P, T extends StatefulWidget> =
    Valuable<P> Function(T widget);

/// A mixin to provide a scope for Valuables, allowing to easily manage their lifecycle
mixin StateValuableScopeMixin<T extends StatefulWidget> on State<T> {
  final ValuableScope _valuableScope = ValuableScope();

  @override
  void dispose() {
    _valuableScope.dispose();
    super.dispose();
  }

  ValuableScope get vScope => _valuableScope;

  final _interops =
      <ValuableStatefulWidgetParam<dynamic, T>, Valuable<dynamic>>{};

  /// Get a Valuable from the widget, and keep it in the scope, so it will be automatically disposed when the State is disposed
  /// If the extracted Valuable change, the computed valuable will be automatically updated with the new value
  ///
  /// [extractor] is a function that extract a Valuable from the widget, it should be pure, and not have any side effect,
  /// because it will be called multiple times, and should return the same Valuable for the same widget
  ///
  /// Exemple of use :
  /// ```dart
  /// class MyWidget extends StatefulWidget {
  ///   final Valuable<String> title;
  ///
  ///   MyWidget({required this.title});
  /// }
  ///
  /// class _MyWidgetState extends State<MyWidget> with StateValuableScopeMixin<MyWidget> {
  ///   late final titleValuable = interopValuableArg((widget) => widget.title);
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///    return ValuableConsumer(
  ///      builder: (context, watch, child) => Text(watch(titleValuable)),
  ///    );
  ///   }
  /// }
  /// ```
  @protected
  Valuable<P> interopValuableArg<P>(
    ValuableStatefulWidgetParam<P, T> extractor,
  ) {
    return _interops.putIfAbsent(
          extractor,
          () => _valuableScope.computed(
            (watch, {valuableContext}) => watch(extractor(widget)),
          ),
        )
        as Valuable<P>;
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final extractor in _interops.keys) {
      if (extractor(oldWidget) != extractor(widget)) {
        // If the extracted valuable changed, we need to update the computed valuable
        final valuable = _interops[extractor]!;
        valuable.markToReevaluate();
      }
    }
  }
}
