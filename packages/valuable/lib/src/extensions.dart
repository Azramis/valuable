import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/operations.dart';
import 'package:valuable/src/stateful.dart';

/// Extension to define operators for Valuable<bool>
extension BoolOperators on Valuable<bool> {
  /// Logical AND between Valuable/boolean value
  Valuable<bool> operator &(Valuable<bool> other) {
    return ValuableBoolGroup.and(<Valuable<bool>>[this, other]);
  }

  /// Logical OR between Valuable/boolean value
  Valuable<bool> operator |(Valuable<bool> other) {
    return ValuableBoolGroup.or(<Valuable<bool>>[this, other]);
  }

  /// Create a new Valuable<bool> that depends on the current, but with the negated value
  Valuable<bool> negation() {
    return this.map((value) => !value);
  }

  /// Get a new Valuable whom the value depends on the current Valuable value
  ///
  /// If current value is true then [value] is returned, else if [elseValue] is
  /// specified then it returned
  Valuable<Output> then<Output>(Valuable<Output> value,
      {Valuable<Output>? elseValue}) {
    return ValuableIf<Output>(
        this,
        (ValuableWatcher watch, {ValuableContext? valuableContext}) =>
            watch(value),
        elseCase: (elseValue != null)
            ? (ValuableWatcher watch, {ValuableContext? valuableContext}) =>
                watch(elseValue)
            : null);
  }

  /// Same as [then] function, but with direct value as parameters
  Valuable<Output> thenValue<Output>(Output value,
      {required Output elseValue}) {
    return ValuableIf<Output>.value(this, value, elseValue: elseValue);
  }
}

/// Extension to define operators for Valuable<bool>
extension NumOperators<T extends num> on Valuable<T> {
  /// Addition operator.
  Valuable<num> operator +(Valuable<num> other) =>
      ValuableNumOperation.sum(this, other);

  /// Subtraction operator.
  Valuable<num> operator -(Valuable<num> other) =>
      ValuableNumOperation.substract(this, other);

  /// Multiplication operator.
  Valuable<num> operator *(Valuable<num> other) =>
      ValuableNumOperation.multiply(this, other);

  ///
  /// Euclidean modulo operator.
  ///
  /// Returns the remainder of the Euclidean division. The Euclidean division of
  /// two integers `a` and `b` yields two integers `q` and `r` such that
  /// `a == b * q + r` and `0 <= r < b.abs()`.
  ///
  /// The Euclidean division is only defined for integers, but can be easily
  /// extended to work with doubles. In that case `r` may have a non-integer
  /// value, but it still verifies `0 <= r < |b|`.
  ///
  /// The sign of the returned value `r` is always positive.
  ///
  /// See [remainder] for the remainder of the truncating division.
  ///
  Valuable<num> operator %(Valuable<num> other) =>
      ValuableNumOperation.modulo(this, other);

  /// Division operator.
  Valuable<double> operator /(Valuable<num> other) =>
      ValuableNumOperation.divide(this, other);

  ///
  /// Truncating division operator.
  ///
  /// If either operand is a [double] then the result of the truncating division
  /// `a ~/ b` is equivalent to `(a / b).truncate().toInt()`.
  ///
  /// If both operands are [int]s then `a ~/ b` performs the truncating
  /// integer division.
  ///
  Valuable<int> operator ~/(Valuable<num> other) =>
      ValuableNumOperation.truncDivide(this, other);

  /// Negate operator.
  Valuable<num> operator -() => ValuableNumOperation.negate(this);
}

/// Extension to define operators for Valuable<String>
extension StringOperators on Valuable<String> {
  /// Concate operator
  Valuable<String> operator +(Valuable<String> other) =>
      ValuableStringOperation.concate(this, other);
}

extension ListOperators<E> on Valuable<List<E>> {
  /// Notify listener that the list or its values have been updated
  void listUpdated() => this.markToReevaluate();

  /// Returns the object at the given [index] in the list
  /// or throws a [RangeError] if [index] is out of bounds.
  E operator [](int index) => this.getValue()[index];

  /// Sets the value at the given [index] in the list to [value]
  /// or throws a [RangeError] if [index] is out of bounds.
  void operator []=(int index, E value) {
    if (this.getValue()[index] != value) {
      this.getValue()[index] = value;
      listUpdated();
    }
  }

  /// Returns the first element.
  ///
  /// Throws a [StateError] if `this` is empty.
  /// Otherwise returns the first element in the iteration order,
  /// equivalent to `this.elementAt(0)`.
  E get first => this.getValue().first;

  /// Returns the last element.
  ///
  /// Throws a [StateError] if `this` is empty.
  /// Otherwise may iterate through the elements and returns the last one
  /// seen.
  /// Some iterables may have more efficient ways to find the last element
  /// (for example a list can directly access the last element,
  /// without iterating through the previous ones).
  E get last => this.getValue().last;

  /// Checks that this iterable has only one element, and returns that element.
  ///
  /// Throws a [StateError] if `this` is empty or has more than one element.
  E get single => this.getValue().single;

  /// Updates the first position of the list to contain [value].
  ///
  /// Equivalent to `theList[0] = value;`.
  ///
  /// The list must be non-empty.
  set first(E value) {
    if (this.first != value) {
      this.getValue().first = value;
      listUpdated();
    }
  }

  /// Updates the last position of the list to contain [value].
  ///
  /// Equivalent to `theList[theList.length - 1] = value;`.
  ///
  /// The list must be non-empty.
  set last(E value) {
    if (this.last != value) {
      this.getValue().last = value;
      listUpdated();
    }
  }

  /// The number of objects in this list.
  ///
  /// The valid indices for a list are `0` through `length - 1`.
  int get length => this.getValue().length;

  /// Changes the length of this list.
  ///
  /// If [newLength] is greater than
  /// the current length, entries are initialized to `null`.
  /// Increasing the length fails if the element type does not allow `null`.
  ///
  /// Throws an [UnsupportedError] if the list is fixed-length or
  /// if attempting tp enlarge the list when `null` is not a valid element.
  set length(int newLength) {
    if (this.length != newLength) {
      this.getValue().length = newLength;
      listUpdated();
    }
  }

  /// Adds [value] to the end of this list,
  /// extending the length by one.
  ///
  /// Throws an [UnsupportedError] if the list is fixed-length.
  void add(E value) {
    this.getValue().add(value);
    listUpdated();
  }

  /// Appends all objects of [iterable] to the end of this list.
  ///
  /// Extends the length of the list by the number of objects in [iterable].
  /// Throws an [UnsupportedError] if this list is fixed-length.
  void addAll(Iterable<E> iterable) {
    this.getValue().addAll(iterable);
    listUpdated();
  }

  /// Sorts this list according to the order specified by the [compare] function.
  ///
  /// The [compare] function must act as a [Comparator].
  ///
  ///     List<String> numbers = ['two', 'three', 'four'];
  ///     // Sort from shortest to longest.
  ///     numbers.sort((a, b) => a.length.compareTo(b.length));
  ///     print(numbers);  // [two, four, three]
  ///
  /// The default List implementations use [Comparable.compare] if
  /// [compare] is omitted.
  ///
  ///     List<int> nums = [13, 2, -11];
  ///     nums.sort();
  ///     print(nums);  // [-11, 2, 13]
  ///
  /// A [Comparator] may compare objects as equal (return zero), even if they
  /// are distinct objects.
  /// The sort function is not guaranteed to be stable, so distinct objects
  /// that compare as equal may occur in any order in the result:
  ///
  ///     List<String> numbers = ['one', 'two', 'three', 'four'];
  ///     numbers.sort((a, b) => a.length.compareTo(b.length));
  ///     print(numbers);  // [one, two, four, three] OR [two, one, four, three]
  void sort([int compare(E a, E b)?]) {
    this.getValue().sort(compare);
    listUpdated();
  }

  /// Shuffles the elements of this list randomly.
  void shuffle([Random? random]) {
    this.getValue().shuffle(random);
    listUpdated();
  }

  /// Removes all objects from this list;
  /// the length of the list becomes zero.
  ///
  /// Throws an [UnsupportedError], and retains all objects, if this
  /// is a fixed-length list.
  void clear() {
    if (this.length > 0) {
      this.getValue().clear();
      listUpdated();
    }
  }

  /// Inserts the object at position [index] in this list.
  ///
  /// This increases the length of the list by one and shifts all objects
  /// at or after the index towards the end of the list.
  ///
  /// The list must be growable.
  /// The [index] value must be non-negative and no greater than [length].
  void insert(int index, E element) {
    this.getValue().insert(index, element);
    listUpdated();
  }

  /// Inserts all objects of [iterable] at position [index] in this list.
  ///
  /// This increases the length of the list by the length of [iterable] and
  /// shifts all later objects towards the end of the list.
  ///
  /// The list must be growable.
  /// The [index] value must be non-negative and no greater than [length].
  void insertAll(int index, Iterable<E> iterable) {
    this.getValue().insertAll(index, iterable);
    listUpdated();
  }

  /// Removes the first occurrence of [value] from this list.
  ///
  /// Returns true if [value] was in the list, false otherwise.
  ///
  ///     List<String> parts = ['head', 'shoulders', 'knees', 'toes'];
  ///     parts.remove('head'); // true
  ///     parts.join(', ');     // 'shoulders, knees, toes'
  ///
  /// The method has no effect if [value] was not in the list.
  ///
  ///     // Note: 'head' has already been removed.
  ///     parts.remove('head'); // false
  ///     parts.join(', ');     // 'shoulders, knees, toes'
  ///
  /// An [UnsupportedError] occurs if the list is fixed-length.
  bool remove(Object? value) {
    bool result;
    result = this.getValue().remove(value);
    if (result) {
      listUpdated();
    }
    return result;
  }

  /// Removes the object at position [index] from this list.
  ///
  /// This method reduces the length of `this` by one and moves all later objects
  /// down by one position.
  ///
  /// Returns the removed object.
  ///
  /// The [index] must be in the range `0 ≤ index < length`.
  ///
  /// Throws an [UnsupportedError] if this is a fixed-length list. In that case
  /// the list is not modified.
  E removeAt(int index) {
    E result;
    result = this.getValue().removeAt(index);
    listUpdated();
    return result;
  }

  /// Pops and returns the last object in this list.
  ///
  /// The list must not be empty.
  ///
  /// Throws an [UnsupportedError] if this is a fixed-length list.
  E removeLast() {
    E result;
    result = this.getValue().removeLast();
    listUpdated();
    return result;
  }

  /// Removes all objects from this list that satisfy [test].
  ///
  /// An object [:o:] satisfies [test] if [:test(o):] is true.
  ///
  ///     List<String> numbers = ['one', 'two', 'three', 'four'];
  ///     numbers.removeWhere((item) => item.length == 3);
  ///     numbers.join(', '); // 'three, four'
  ///
  /// Throws an [UnsupportedError] if this is a fixed-length list.
  void removeWhere(bool test(E element)) {
    this.getValue().removeWhere(test);
    listUpdated();
  }

  /// Removes all objects from this list that fail to satisfy [test].
  ///
  /// An object [:o:] satisfies [test] if [:test(o):] is true.
  ///
  ///     List<String> numbers = ['one', 'two', 'three', 'four'];
  ///     numbers.retainWhere((item) => item.length == 3);
  ///     numbers.join(', '); // 'one, two'
  ///
  /// Throws an [UnsupportedError] if this is a fixed-length list.
  void retainWhere(bool test(E element)) {
    this.getValue().retainWhere(test);
    listUpdated();
  }

  /// Returns the concatenation of this list and [other].
  ///
  /// Returns a new list containing the elements of this list followed by
  /// the elements of [other].
  ///
  /// The default behavior is to return a normal growable list.
  /// Some list types may choose to return a list of the same type as themselves
  /// (see [Uint8List.+]);
  List<E> operator +(List<E> other) => this.getValue() + other;

  /// Returns an unmodifiable [Map] view of `this`.
  ///
  /// The map uses the indices of this list as keys and the corresponding objects
  /// as values. The `Map.keys` [Iterable] iterates the indices of this list
  /// in numerical order.
  ///
  ///     List<String> words = ['fee', 'fi', 'fo', 'fum'];
  ///     Map<int, String> map = words.asMap();
  ///     map[0] + map[1];   // 'feefi';
  ///     map.keys.toList(); // [0, 1, 2, 3]
  Map<int, E> asMap() => this.getValue().asMap();

  /// Returns `true` if there are no elements in this collection.
  ///
  /// May be computed by checking if `iterator.moveNext()` returns `false`.
  bool get isEmpty => this.getValue().isEmpty;

  /// Returns true if there is at least one element in this collection.
  ///
  /// May be computed by checking if `iterator.moveNext()` returns `true`.
  bool get isNotEmpty => this.getValue().isNotEmpty;
}

/// Available operations on StatefulValuable<bool>
extension BoolStateOperations on StatefulValuable<bool> {
  /// Reassign the state value with the negated current value (true -> false)
  void negate() {
    setValue(!this.getValue());
  }
}

/// Available operations on StatefulValuable<T extends num>
extension NumStateOperations<T extends num> on StatefulValuable<T> {
  /// Reassign the state value with the negated current value (current * -1)
  void negate() {
    setValue((this.getValue() * -1) as T);
  }

  /// Reassign the state value by adding an other number
  void add(num other) {
    setValue((this.getValue() + other) as T);
  }

  /// Reassign the state value by substracting an other number
  void substract(num other) {
    setValue((this.getValue() - other) as T);
  }

  /// Reassign the state value by mutiplying with an other number
  void multiply(num other) {
    setValue((this.getValue() * other) as T);
  }
}

/// Available operations on StatefulValuable<int>
extension IntStateOperations on StatefulValuable<int> {
  /// Reassign the state by adding 1
  void increment() {
    add(1);
  }

  /// Reassign the state by substract 1
  void decrement() {
    add(-1);
  }

  /// Reassign the state value by dividing with an other number
  void divide(num other) {
    setValue(this.getValue() ~/ other);
  }
}

/// Available operations on StatefulValuable<double>
extension DoubleStateOperations on StatefulValuable<double> {
  /// Reassign the state value by dividing with an other number
  void divide(num other) {
    setValue(this.getValue() / other);
  }
}

/// Method to transform a [ValueListenable] to a [Valuable]
extension ValueListenableValuable<T> on ValueListenable<T> {
  /// Method to transform a [ValueListenable] to a [Valuable]
  Valuable<T> toValuable() => Valuable.listenable(this);
}

/// Method to transform a [ValueListenable] to a [Valuable]
extension ListenableValuable<L extends Listenable> on L {
  /// Method to transform a [ValueListenable] to a [Valuable]
  Valuable<T> toComputedValuable<T>(T computation(L listenable)) =>
      Valuable.listenableComputed(this, computation);
}

/// Provide extension on ValuableWatcher
extension ValuableWatcherExtension on ValuableWatcher {
  /// Method to manage a Nullable Valuable with a default value if it's null
  T def<T>(
    Valuable<T>? valuable,
    T defaultValue, {
    ValuableContext? valuableContext,
    ValuableWatcherSelector? selector,
  }) {
    if (valuable != null) {
      return this(
        valuable,
        valuableContext: valuableContext,
        selector: selector,
      );
    }
    return defaultValue;
  }
}

extension ValuableFutureExtension<T> on Valuable<Future<T>> {
  FutureValuableAsyncValue<T> toFutureAsyncValue() =>
      FutureValuable.asyncVal(this);
}

extension FutureExtension<T> on Future<T> {
  FutureValuableAsyncValue<T> toValuableFutureAsyncValue() =>
      FutureValuable.asyncVal(Valuable.value(this));
}

extension ValuableStreamExtension<T> on Valuable<Stream<T>> {
  StreamValuableAsyncValue<T> toStreamAsyncValue() =>
      StreamValuable.asyncVal(this);
}

extension StreamExtension<T> on Stream<T> {
  StreamValuableAsyncValue<T> toValuableStreamAsyncValue() =>
      StreamValuable.asyncVal(Valuable.value(this));
}
