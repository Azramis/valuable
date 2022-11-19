import 'dart:collection';

/*
  Dart doesnt provide an unmodifiable queue, so this is an implementation
  for the need of this library
*/

/// Inspired by the implementation UnmodifiableListBaseMixin from
mixin UnmodifiableQueueMixin<T> implements Queue<T> {
  @override
  void add(T value) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void addAll(Iterable<T> iterable) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void addFirst(T value) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void addLast(T value) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void clear() {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  bool remove(Object? value) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  T removeFirst() {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  T removeLast() {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void removeWhere(bool Function(T element) test) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @override
  void retainWhere(bool Function(T element) test) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }
}

abstract class UnmodifiableQueueBase<E> = ListQueue<E>
    with UnmodifiableQueueMixin<E>;

class UnmodifiableQueueView<E> extends UnmodifiableQueueBase<E> {
  final Queue<E> queue;

  UnmodifiableQueueView(this.queue);

  Queue<R> cast<R>() => queue.cast();
  Iterator<E> get iterator => queue.iterator;

  void forEach(void f(E element)) => queue.forEach(f);

  bool get isEmpty => queue.isEmpty;

  int get length => queue.length;

  E get first => queue.first;

  E get last => queue.last;

  E get single => queue.single;

  E elementAt(int index) => queue.elementAt(index);

  List<E> toList({bool growable = true}) => queue.toList();
}
