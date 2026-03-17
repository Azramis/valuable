import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';

class _ValuableWatchedInfos<T> {
  final VoidCallback removeValueListener;
  final VoidCallback removeDisposeListener;
  final List<ValuableWatcherSelector<T>?> selectors =
      <ValuableWatcherSelector<T>?>[];
  T previousWatchedValue;

  _ValuableWatchedInfos({
    required this.removeValueListener,
    required this.removeDisposeListener,
    required this.previousWatchedValue,
  });

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
        });

        return _ValuableWatchedInfos<T>(
          removeValueListener: () => valuable.removeListener(callback),
          removeDisposeListener: removeListener,
          previousWatchedValue: result,
        );
      },
    );

    return result;
  }

  /// Remove listener on the valuable, that may change scope, or that about to be disposed
  void _unwatch(Valuable valuable) => _watched.remove(valuable)?.dispose();

  void _callValuableChange<T>(Valuable<T> valuable) {
    if (_watched.containsKey(valuable)) {
      if (_watched[valuable] != null) {
        final infos = _watched[valuable] as _ValuableWatchedInfos<T>;

        bool selectOk;

        List<ValuableWatcherSelector<T>?> selectors = infos.selectors;

        if (selectors.isNotEmpty) {
          // If there are available selectors, we must test them until [selectOk]
          // is true, or we reach the end of the list

          selectOk = false;
          T previousWatchedValue = infos.previousWatchedValue;
          for (ValuableWatcherSelector<T>? selector in selectors) {
            selectOk =
                selectOk ||
                (selector?.call(valuable, previousWatchedValue) ?? false);

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
