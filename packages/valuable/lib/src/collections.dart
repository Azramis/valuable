// ignore_for_file: experimental_member_use

import 'dart:collection';

import 'package:meta/meta.dart';

/*
  Dart doesnt provide an unmodifiable queue, so this is an implementation
  for the need of this library
*/
extension type UnmodifiableQueueView<E>(Queue<E> queue) implements Queue<E> {
  @redeclare
  void add(E value) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @redeclare
  void addAll(Iterable<E> iterable) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @redeclare
  void addFirst(E value) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @redeclare
  void addLast(E value) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @redeclare
  void clear() {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @redeclare
  bool remove(Object? value) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @redeclare
  E removeFirst() {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @redeclare
  E removeLast() {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @redeclare
  void removeWhere(bool Function(E element) test) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }

  @redeclare
  void retainWhere(bool Function(E element) test) {
    throw new UnsupportedError("Cannot modify an unmodifiable queue");
  }
}
