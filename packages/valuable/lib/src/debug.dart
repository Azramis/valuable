import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/callable.dart';

ValuableDebugSession? _debugSession;

sealed class ValuableDebugSession {
  factory ValuableDebugSession() => _debugSession ??= (kDebugMode
      ? _ValuableDebugSessionImpl()
      : _FictiveValuableDebugSession());

  int get mountedValuablesCount;
  int get totalValuablesCount;

  int get mountedCallablesCount;
  int get totalCallablesCount;
  int get inLoopCallablesCount;

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

  void addInLoopCallable(ValuableCallback callback) {
    if (this is _ValuableDebugSessionImpl) {
      (this as _ValuableDebugSessionImpl)._addInLoopCallable(callback);
    }
  }
}

final class _ValuableDebugSessionImpl implements ValuableDebugSession {
  final Set<Valuable> _mountedValuables = {};
  final Set<ValuableCallback> _mountedCallables = {};
  final Set<ValuableCallback> _inLoopCallables = {};

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
      _inLoopCallables.remove(callback);
    });
  }

  void _addInLoopCallable(ValuableCallback callback) {
    if (_inLoopCallables.contains(callback)) return;
    if (!_mountedCallables.contains(callback)) return;

    _inLoopCallables.add(callback);
  }

  @override
  int get mountedCallablesCount => _mountedCallables.length;

  @override
  int get totalCallablesCount => _totalCallablesCount;

  @override
  int get inLoopCallablesCount => _inLoopCallables.length;

  @override
  void printDebugInfo() {
    if (kDebugMode) {
      final buffer = StringBuffer();
      const separator =
          "+------------------------------------------------------------------------------+";
      void separate() => buffer.writeln(separator);
      void oneText(String text, [bool center = true]) {
        final leftPadding = center
            ? ((separator.length - 2 - text.length) / 2).floor()
            : 1;
        final rightPadding = separator.length - 2 - text.length - leftPadding;
        buffer.writeln("|${" " * leftPadding}$text${" " * rightPadding}|");
      }

      void twoTexts(String leftText, String rightText) {
        final leftPadding = 1;
        final rightPadding = 1;
        final middlePadding =
            separator.length -
            2 -
            leftPadding -
            rightPadding -
            leftText.length -
            rightText.length;
        buffer.writeln(
          "|${" " * leftPadding}$leftText${" " * middlePadding}$rightText${" " * rightPadding}|",
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
      twoTexts("In loop callables count", inLoopCallablesCount.toString());
      separate();

      print(buffer.toString());

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
        print(buffer.toString());
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
  int get inLoopCallablesCount => 0;

  @override
  void printDebugInfo() {}
}
