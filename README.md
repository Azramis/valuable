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

#### Dirty it

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

