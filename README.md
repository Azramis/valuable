# Valuable

## About

_What is Valuable ?_  

 Valuable is another state management library (one more...), it takes its roots from [Riverpod]([https://](https://riverpod.dev/fr/)) and from which it is inspired.

_Why Valuable ?_

 Unlike **Riverpod**, **Valuable** each of its Provider-like is autonomous and remain on itself, it dispatch its own update events.  
 In fact, **Valuable** is a graph state management.  
 It was made to build Widget tree as stateless as possible, with the ability to refresh some part of the tree, without the necessity to split it to an infinite number of **StatelessWidget**.
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

``FutureValuable<Output, Res>`` have been created in the purpose of computing a ``Future<Res>`` to a safe runtime ``Output`` value. In fact ``FutureValuable<Output, Res>`` inherits ``Valuable<Output>``, so it can use all of its useful methods.

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

Let the code speaks

```dart
    final StatefulValuable<Color> myColor = StatefulValuable<Color>(Colors.red);

    Widget build(BuildContext context) {
        return Column(
            children: <Widget>[
                Container(
                    color: Colors.amber,
                    width: 100,
                    height: 100,
                ),
                ValuableConsumer(
                    builder: (BuildContext context, ValuableWatcher watch, _) =>
                        Container(
                            color: watch(myColor),
                            width: 100,
                            height: 100,
                        ),
                ),
                Row(
                    children: <Widget>[
                        TextButton(
                            onPressed: () => myColor.setValue(Colors.blue),
                            child: const Text("Blue"),
                        ),
                        TextButton(
                            onPressed: () => myColor.setValue(Colors.red),
                            child: const Text("Red"),
                        ),
                    ],
                ),
            ],
        );               
    }
```

In this example, we build an UI with 2 colored squares and 2 buttons.  
The first square is designed to never change, whereas the second can changed its color when we pressed either of the buttons.  
When we set the value of ``myColor`` by pressing a button, **only** the ``builder`` of the ``ValuableConsumer`` is played again in order to change the color.  
This way, we create a databinding between ``myColor`` and the UI.

### ``ValuableWidget``

In some cases, you may want to define a reusable Widget that depends on one or more _Valuable_.  
``ValuableWidget`` exists for this reason. It's exactly the same as declare a new ``StatelessWidget`` where the built Widget is a ``ValuableConsumer``, but without the boilerplate.  

Instead, ``ValuableWidget.build`` gains access to the function ``watch`` as it exists in the ``ValuableConsumer.builder``.

Let's redo the same code as above, but isolate the ``ValuableConsumer`` as Widget, to reuse it later.

```dart

    class ColoredSquare extends ValuableWidget {
        /// No need to know that is a StatefulValuable or other, only need to depend on a Valuable<Color>
        final Valuable<Color> myColor;

        const ColoredSquare({
                required this.myColor,
                Key? key,
            }) : super(key: key);

        Widget build(BuildContext context, ValuableWatcher watch) {
            return Container(
                        color: watch(myColor),
                        width: 100,
                        height: 100,
                    );
        }    
    }
```

and then use it

```dart
    final StatefulValuable<Color> myColor = StatefulValuable<Color>(Colors.red);

    Widget build(BuildContext context) {
        return Column(
            children: <Widget>[
                Container(
                    color: Colors.amber,
                    width: 100,
                    height: 100,
                ),
                ColoredSquare(
                    myColor: myColor,
                ),
                Row(
                    children: <Widget>[
                        TextButton(
                            onPressed: () => myColor.setValue(Colors.blue),
                            child: const Text("Blue"),
                        ),
                        TextButton(
                            onPressed: () => myColor.setValue(Colors.red),
                            child: const Text("Red"),
                        ),
                    ],
                ),
            ],
        );               
    }
```

The behavior is the same, but we gain the possibility to reuse the ``ColoredSquare`` and to separe the concerns.  

### ``watchIt``

This is an extension on ``Valuable<T>``, that allows to retrieve the closest ``ValuableConsumer`` in the tree and use its ``watch`` function to read the value and to subscribe to the _Valuable_ changes.  
If no ``ValuableConsumer`` are found in the tree, the value is simply returned to avoid runtime error.  

Code sample

```dart
    final StatefulValuable<Color> myColor = StatefulValuable<Color>(Colors.red);

    Widget build(BuildContext context) {
        return Column(
            children: <Widget>[
                Container(
                    color: Colors.amber,
                    width: 100,
                    height: 100,
                ),
                Container(
                        color: myColor.watchIt(context),
                        width: 100,
                        height: 100,
                    ),
                ),
                Row(
                    children: <Widget>[
                        TextButton(
                            onPressed: () => myColor.setValue(Colors.blue),
                            child: const Text("Blue"),
                        ),
                        TextButton(
                            onPressed: () => myColor.setValue(Colors.red),
                            child: const Text("Red"),
                        ),
                    ],
                ),
            ],
        );               
    }
```

The usage of this method **is not encouraged**.  
It can be useful in some cases, but it doesnt separe the rebuilt parts and tends to invalidate to much UI (performance shortage). Use at your own risks.  

## Go deeper

Some explanations to go deeper with _Valuable_

### Extensions

The library defines few extensions to add some functionality to certain generic types of _Valuable_.  
It can be operators, but methods too.  
It often results in a _Valuable_ that can be notified from the source _Valuable_, in order to reevaluate itself.

The simpliest extensions are listed there.

#### ``Valuable<bool>``

- ``&`` operator between 2 ``Valuable<bool>`` to create a ``Valuable<bool>`` that result of an **and** operation.
- ``|`` operator, to create a ``Valuable<bool>`` that result of an **or** operation.
- ``negation()`` method, generate a ``Valuable<bool>`` that is the negation of the caller.

#### ``Valuable<T extends num>``

- ``+``operator that produces a ``Valuable<num>``, result of the sum.
