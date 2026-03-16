import 'dart:collection';

/*
  Dart doesn't provide an unmodifiable queue, so this is an implementation
  for the need of this library
*/
class UnmodifiableQueueView<E> implements Queue<E> {
  final Queue<E> _queue;

  UnmodifiableQueueView(this._queue);

  @override
  void add(E value) {
    throw UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void addAll(Iterable<E> iterable) {
    throw UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void addFirst(E value) {
    throw UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void addLast(E value) {
    throw UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void clear() {
    throw UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  bool remove(Object? value) {
    throw UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  E removeFirst() {
    throw UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  E removeLast() {
    throw UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void removeWhere(bool Function(E element) test) {
    throw UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void retainWhere(bool Function(E element) test) {
    throw UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  Iterator<E> get iterator => _queue.iterator;

  @override
  int get length => _queue.length;

  @override
  bool get isEmpty => _queue.isEmpty;

  @override
  bool get isNotEmpty => _queue.isNotEmpty;

  @override
  E get first => _queue.first;

  @override
  E get last => _queue.last;

  @override
  E get single => _queue.single;

  @override
  Queue<T> cast<T>() => _queue.cast<T>();
}
