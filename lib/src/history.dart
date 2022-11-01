
import 'package:valuable/src/base.dart';

class _ValuableHistoryContainer<T> {
  final Valuable<T> valuable;

  final List<_ValuableHistoryNode<T>> _history=<_ValuableHistoryNode<T>>[];

  int _currentIdx=-1;

  
}

class _ValuableHistoryNode<T> {
  final T value;

  final DateTime timestamp = DateTime.now();

  _ValuableHistoryNode(this.value);
}