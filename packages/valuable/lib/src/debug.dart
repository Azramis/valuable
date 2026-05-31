import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/callable.dart';

ValuableDebugSession? _debugSession;

sealed class ValuableDebugSession {
  factory ValuableDebugSession() => _debugSession ??= (kDebugMode
      ? _ValuableDebugSessionImpl()
      : _FictiveValuableDebugSession());

  /// Number of currently mounted valuables (not disposed yet)
  ///
  /// Allow to know if there is a memory leak.
  /// If this number is non-zero in a context where there should be no mounted valuables,
  /// it means that some valuables are not properly disposed, and so there is a memory leak.
  int get mountedValuablesCount;

  /// Total number of ever existed valuables (including disposed ones)
  ///
  /// Using this count with [mountedValuablesCount] can help compute
  /// the number of already disposed valuables.
  int get totalValuablesCount;

  /// Number of currently mounted callables (not disposed yet)
  ///
  /// Allow to know if there is a memory leak.
  /// If this number is non-zero in a context where there should be no mounted callables,
  /// it means that some callables are not properly disposed, and so there is a memory leak.
  int get mountedCallablesCount;

  /// Total number of ever existed callables (including disposed ones)
  ///
  /// Using this count with [mountedCallablesCount] can help compute
  /// the number of already disposed callables.
  int get totalCallablesCount;

  /// Number of callables that are aware of events (callables that have been executed at least one time)
  ///
  /// Events aware callables are callables that have been executed at least one time,
  /// and that can automatically re-call when a watched [Valuable] change.
  int get eventsAwareCallablesCount;

  /// Print debug info about Valuable and ValuableCallback instances
  ///
  /// This method can be used to detect memory leaks, by checking if there is still mounted valuables or callables
  /// in a context where there should be no mounted valuables or callables.
  void printDebugInfo();
}

@internal
extension ValuableDebugExtension on ValuableDebugSession {
  void mountValuable(Valuable valuable) {
    if (this is _ValuableDebugSessionImpl) {
      (this as _ValuableDebugSessionImpl)._mountValuable(valuable);
    }
  }

  void mountCallable(ValuableCallback callback) {
    if (this is _ValuableDebugSessionImpl) {
      (this as _ValuableDebugSessionImpl)._mountCallable(callback);
    }
  }

  void setCallableEventsAware(ValuableCallback callback) {
    if (this is _ValuableDebugSessionImpl) {
      (this as _ValuableDebugSessionImpl)._setCallableEventsAware(callback);
    }
  }
}

final class _ValuableDebugSessionImpl implements ValuableDebugSession {
  final Set<Valuable> _mountedValuables = {};
  final Set<ValuableCallback> _mountedCallables = {};
  final Set<ValuableCallback> _eventsAwareCallables = {};

  int _totalValuablesCount = 0;
  int _totalCallablesCount = 0;

  void _mountValuable(Valuable valuable) {
    if (_mountedValuables.contains(valuable)) return;

    _totalValuablesCount++;
    _mountedValuables.add(valuable);
    valuable.listenDispose(() => _mountedValuables.remove(valuable));
  }

  @override
  int get mountedValuablesCount => _mountedValuables.length;

  @override
  int get totalValuablesCount => _totalValuablesCount;

  void _mountCallable(ValuableCallback callback) {
    if (_mountedCallables.contains(callback)) return;

    _totalCallablesCount++;
    _mountedCallables.add(callback);
    callback.listenDispose(() {
      _mountedCallables.remove(callback);
      _eventsAwareCallables.remove(callback);
    });
  }

  void _setCallableEventsAware(ValuableCallback callback) {
    if (_eventsAwareCallables.contains(callback)) return;
    if (!_mountedCallables.contains(callback)) return;

    _eventsAwareCallables.add(callback);
  }

  @override
  int get mountedCallablesCount => _mountedCallables.length;

  @override
  int get totalCallablesCount => _totalCallablesCount;

  @override
  int get eventsAwareCallablesCount => _eventsAwareCallables.length;

  @override
  void printDebugInfo() {
    if (kDebugMode) {
      final buffer = StringBuffer();
      const separator =
          "+------------------------------------------------------------------------------+";
      void separate() => buffer.writeln(separator);
      void oneText(String text, [bool center = true]) {
        const insets = 4; // 2 space and 2 "|" in the separator
        final maxTextLength = separator.length - insets;
        final textLength = min(text.length, maxTextLength);
        final truncatedText = textLength < text.length
            ? "${text.substring(0, textLength - 3)}..."
            : text;

        final leftPadding = center
            ? (separator.length - insets - textLength) ~/ 2
            : 1;

        final rightPadding =
            separator.length - insets - textLength - leftPadding;
        buffer.writeln(
          "| ${" " * leftPadding}$truncatedText${" " * rightPadding} |",
        );
      }

      void twoTexts(String leftText, String rightText) {
        const leftPadding = 2; // 1 space and 1 "|" in the separator
        const rightPadding = 2; // 1 space and 1 "|" in the separator
        const middlePaddingMin = 2; // 2 space between the two texts
        final remainingLength =
            separator.length - leftPadding - rightPadding - middlePaddingMin;

        final leftTextLength = leftText.length;
        final rightTextLength = rightText.length;

        String truncatedLeftText = leftText;
        String truncatedRightText = rightText;
        int middlePadding = remainingLength;

        if (leftTextLength + rightTextLength < remainingLength) {
          middlePadding =
              remainingLength -
              leftTextLength -
              rightTextLength +
              middlePaddingMin;
        } else {
          middlePadding = middlePaddingMin;
          if (leftTextLength < remainingLength ~/ 2) {
            truncatedRightText =
                "${rightText.substring(0, remainingLength - leftTextLength - (middlePadding + middlePaddingMin) - 3)}...";
          } else if (rightTextLength < remainingLength ~/ 2) {
            truncatedLeftText =
                "${leftText.substring(0, remainingLength - rightTextLength - (middlePadding + middlePaddingMin) - 3)}...";
          } else {
            truncatedLeftText =
                "${leftText.substring(0, (remainingLength ~/ 2) - 3)}...";
            truncatedRightText =
                "${rightText.substring(0, (remainingLength ~/ 2) - 3)}...";
          }
        }

        buffer.writeln(
          "| $truncatedLeftText${" " * middlePadding}$truncatedRightText |",
        );
      }

      buffer.writeln();
      separate();
      oneText("Valuable Debug Info");
      separate();
      twoTexts("Ever existed valuables count", totalValuablesCount.toString());
      separate();
      twoTexts("Mounted valuables count", mountedValuablesCount.toString());
      separate();
      twoTexts("Ever existed callables count", totalCallablesCount.toString());
      separate();
      twoTexts("Mounted callables count", mountedCallablesCount.toString());
      separate();
      twoTexts(
        "Events aware callables count",
        eventsAwareCallablesCount.toString(),
      );
      separate();

      debugPrint(buffer.toString());

      if (mountedValuablesCount > 0) {
        buffer.clear();
        buffer.writeln();
        separate();
        oneText("Mounted valuables details");
        separate();
        for (final valuable in _mountedValuables) {
          twoTexts(valuable.toString(), valuable.runtimeType.toString());
        }
        separate();
        debugPrint(buffer.toString());
      }
    }
  }
}

final class _FictiveValuableDebugSession implements ValuableDebugSession {
  @override
  int get mountedValuablesCount => 0;

  @override
  int get totalValuablesCount => 0;

  @override
  int get mountedCallablesCount => 0;

  @override
  int get totalCallablesCount => 0;

  @override
  int get eventsAwareCallablesCount => 0;

  @override
  void printDebugInfo() {}
}
