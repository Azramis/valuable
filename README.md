# Valuable

## About

_What is Valuable ?_  

 Valuable is another state management library (one more...), it takes its roots from [Riverpod]([https://](https://riverpod.dev/fr/)) and from which it is inspired.

_Why Valuable ?_

 Unlike **Riverpod**, **Valuable** each of its Provider-like is autonomous and remain on itself, it dispatch its own update events.  
 In fact, **Valuable** is a graph state management.  
 It was made to build Widget tree as stateless as possible, with the ability to refresh some part of the tree, without the necessity to split it ton an infinite number of **StatelessWidget**.
 While **Riverpod** needs to have its Providers global, **Valuable** tends to have its owns local, or in some kind of a ViewModel.
 In my mind, when I built this library, I went with the idea, that **Riverpod** and **Valuable** will not be concurrent, but complementary :

- **Riverpod** for the global state of the app
- **Valuable** for each local state (Widget, Views, ...)

_How it works ?_

 At this time, **Valuable** depends on Flutter, because it uses its ``ChangeNotifier`` class. It is something I think about, and may change in the future to create a non flutter dependent package.
 Like it was said, **Valuable** is a graph state management. It was designed to works inside AND outside the Widget Tree.
 Each _node_, obviously named a _Valuable_ 🎉, can depend on some other nodes and more. If a node in this graph becomes invalid, then it notifies all its listeners, which become invalid too; It works like a flow, to invalidate all graph segments that need to be reevaluate.

## How to use Valuable ?

Declare a _Valuable_ which matches the behaviour you want.

- ``StatefulValuable<T>`` for _Valuable_ that can be setted, the most used
- ``FutureValuable<Output, Res>`` that manages to provide an ``Output`` from a ``Future<Res>`` in each of its states.
- ``StreamValuable<Output, Msg>`` that manages to provide an ``Output`` from a ``Stream<Msg>``
- ``Valuable<T>`` otherwise. Can be an immutable value, or an evaluative function. This is the root type of **all** _Valuable_

### For all _Valuable_

#### Read current value

```dart
    Valuable<T> myValuable = ...

    myValuable.getValue(); // Get the current value of the valuable (read state or evaluate it)
```

In some case, ``getValue`` requires a ``ValuableContext`` that can contain special informations (like a ``BuildContext`` for example).
``ValuableContext`` is not mandatory, and can provide extensibility for the future.

#### Listen for change

As a _Valuable_ inherits from ``ChangeNotifier``, its value's change can be listen by

```dart
    myValuable.addListener(() {
        // Value has change here or have been reevaluated !
    }
```

_Obviously, that's not how we'll use it in a Flutter's widget tree, but we'll see that later._

#### Invalidate it

Sometime, it could be useful to mark the _Valuable_ as invalid for it to reevaluate its value.

```dart
    myValuable.markToReevaluate();
```

#### Compare it

_Valuable_ redefines few common operators to compare themselves. It's able to compare to its generic type directly too.
Available operators are :

- ``>``
- ``<``
- ``<=``
- ``>=``

Obviously, it's impossible to reuse ``==`` and ``!=`` operators, so in these cases, 2 functions have been created:

- ``equals``
- ``notEquals``

Some examples

```dart
    Valuable<int> a = ...
    Valuable<int> b = ...

    Valuable<bool> equality = a.equals(b);
```

Whenever ``a`` or ``b`` change, ``equality`` is notified, and notify itself all its listeners, that **IS** the point of _Valuable_

```dart
    Valuable<int> a = ...
    int b = ...

    Valuable<bool> equality = a.equals(b);
```

It also works, but ``equality`` notifies only on ``a`` changes.

### ``StatefulValuable<T>``

As it was said, ``StatefulValuable<T>`` are the most used _Valuable_ as it's the only one we can directly affect.  
It's instanciated with a value, and can be changed at anytime and anywhere we can access it.  
At any change, all listeners are notified.

#### Instanciate it

```dart
    StatefulValuable<int> counter = StatefulValuable<int>(0);
```

_That's all !_

#### Set it

```dart
    counter.setValue(1);
```

### ``FutureValuable<Output, Res>``

``FutureValuable<Output, Res>`` have been created in the purpose of computing a ``Future<Res>`` to a safe runtime ``Output`` value. In fact ``FutureValuable<Output, Res>`` inherits ``Valuable<Output>``, so it can used all of its useful methods.

There are 2 constructors that can be written.

#### FutureValuable computing constructor

```dart
    late final Future<int> distantCounter = ...
    late final FutureValuable<String, int> distantCounterStr = FutureValuable<String, int>(
            distantCounter,
            dataValue: (ValuableContext? context, int result) => "My counter is $result", // Future is done
            noDataValue: (ValuableContext? context) => "Still in progress", // Future is not done yet
            errorValue: (ValuableContext? context, Object error, StackTrace st) => "Can't retrieve counter !", // Future done in error
        );
```

This way, we can provide a value, depending of the ``Future<Res>`` state and value.

#### FutureValuable providing constructor

This constructor is the simpliest for the case ``Res == Output``, and provide value for waiting and error states.

```dart
    late final Future<int> distantCounter = ...
    late final FutureValuable<int, int> distantCounterVal = FutureValuable<int, int>.values(
            distantCounter,
            noDataValue: 0, // Future is not done yet
            errorValue: -1, // Future done in error
        );
```

Then the _Valuable_ always have a correct runtime value, without error management complexity.

### ``StreamValuable<Output, Msg>``

``StreamValuable<Output, Msg>`` works exactly the same as ``FutureValuable<Output, Msg>``, but remains on a ``Stream`` instead a ``Future``.

Let show the code directly !

#### StreamValuable computing constructor

```dart
    late final Stream<int> continuousCounter = ...
    late final StreamValuable<String, int> continuousCounterStr = StreamValuable<String, int>(
            continuousCounter,
            dataValue: (ValuableContext? context, int result) => "$result", // Stream data
            doneValue: (ValuableContext? context) => "Done.", // Stream done
            errorValue: (ValuableContext? context, Object error, StackTrace st) => "On error !", // Stream in error
            initialValue: "0",
        );
```

### ``Valuable<T>``

As it was said, ``Valuable<T>`` is the root type of all _Valuable_, but it offer two factories for :

- simple immuable value, to interact with others _Valuable_
- auto evaluated _Valuable_, that can depend on others _Valuable_

#### Simple immuable value

```dart
    final Valuable<int> zero = Valuable.value(0);
```

#### Auto evaluated

```dart
    final StatefulValuable<int> counter = StatefulValuable<int>(2);
    final late Valuable<double> halfCounter = Valuable.byValuer((ValuableWatcher watch) => watch(counter) / 2);
    ...
    print(halfCounter.getValue()); // Print '1'
    counter.setValue(3); // halfCounter is notified of this change, marks as invalid, and notifies all its listeners
    print(halCounter.getValue()); // Print '1.5'
```

Here comes the real power of _Valuable_.  
This way, the _Valuables_ can be chained and then the graph is created.  
The differents states are defined directly by the _Valuable_ valuer and are safely used in the code through it.

## Valuable and the Widget tree

Like any other Flutter state management, _Valuable_ is designed to provide interaction with the Widget tree.  
Here are the different concepts to use _Valuable_ in Flutter UI:

- ``ValuableConsumer``
- ``ValuableWidget``
- ``watchIt`` extension

### ``ValuableConsumer``

This is the most common way to use some _Valuable_ inside the Widget tree, in purpose to produce a reactive UI.  
Inspired by **Riverpod**, this widget requires a ``ValuableConsumerBuilder`` that provide :

- a ``BuildContext context``
- a ``T watch(Valuable<T>)`` function to read the value, and especially to register at any changes of the ``Valuable<T>``
- a ``Widget? child`` that can be passed as optional argument of the ``ValuableConsumer``