import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';

class _ValuableWatchedInfos<T> {
  final VoidCallback callback;
  final List<ValuableWatcherSelector<T>?> selectors =
      <ValuableWatcherSelector<T>?>[];
  T previousWatchedValue;

  _ValuableWatchedInfos(
      {required this.callback, required this.previousWatchedValue});
}

/// A mixin to provide extension of classes that might want to watch some valuable
/// and take action on possible changes
mixin ValuableWatcherMixin {
  final Map<Valuable, _ValuableWatchedInfos> _watched =
      <Valuable, _ValuableWatchedInfos>{};

  /// Watch a valuable, that eventually change
  @protected
  @mustCallSuper
  T watch<T>(Valuable<T> valuable,
      {ValuableContext? valuableContext,
      ValuableWatcherSelector<T>? selector}) {
    T result;

    result = valuable.getValue(valuableContext ?? this.valuableContext);

    if (!_watched.containsKey(valuable)) {
      VoidCallback callback = () => _callValuableChange<T>(valuable);

      _watched.putIfAbsent(
          valuable,
          () => _ValuableWatchedInfos<T>(
              callback: callback, previousWatchedValue: result));
      valuable.addListener(callback);
      valuable.listenDispose(() {
        unwatch(valuable);
      });
    }

    if (_watched.containsKey(valuable)) {
      _ValuableWatchedInfos<T> infos =
          _watched[valuable] as _ValuableWatchedInfos<T>;
      infos.previousWatchedValue = result; // Save value for future comparaison
      if (selector != null) {
        infos.selectors.add(selector);
      }
    }

    return result;
  }

  /// Remove listener on the valuable, that may change scope, or that about to be disposed
  /// Internal purpose
  @protected
  void unwatch(Valuable valuable) {
    if (_watched.containsKey(valuable)) {
      _removeValuableListener(valuable);
      _watched.remove(valuable);
    }
  }

  void _callValuableChange<T>(Valuable<T> valuable) {
    if (_watched.containsKey(valuable)) {
      if (_watched[valuable] != null) {
        _ValuableWatchedInfos<T> infos =
            _watched[valuable] as _ValuableWatchedInfos<T>;

        bool selectOk;

        List<ValuableWatcherSelector<T>?> selectors = infos.selectors;

        if (selectors.isNotEmpty) {
          // If there are available selectors, we must test them until [selectOk]
          // is true, or we reach the end of the list

          selectOk = false;
          T previousWatchedValue = infos.previousWatchedValue;
          for (ValuableWatcherSelector<T>? selector in selectors) {
            selectOk = selectOk ||
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
  void onValuableChange();

  @protected
  ValuableContext? get valuableContext => null;

  @protected
  void cleanWatched() {
    _watched.forEach((Valuable key, _ValuableWatchedInfos value) {
      _removeValuableListener(key);
    });
    _watched.clear();
  }

  void _removeValuableListener(Valuable valuable) {
    if (_watched.containsKey(valuable) && valuable.isMounted) {
      _ValuableWatchedInfos infos = _watched[valuable]!;
      valuable.removeListener(infos.callback);
    }
  }
}
