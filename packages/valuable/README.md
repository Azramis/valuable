# Valuable

## About

_What is Valuable ?_  

 Valuable is another state management library (one more...), it takes its roots from [Riverpod](https://riverpod.dev/fr/) and from which it is inspired.

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

#### Dispose it

As a `ChangeNotifier`, a _Valuable_ should be disposed to avoid memory leaks.  
You often have to call `Valuable.dispose()` explicitly in order to free resources, but _Valuables_ can also be disposed in a chain.  
In fact, when a _Valuable_ watches a sibling, it listens to its sibling's disposal event too. If the sibling is disposed, the dependent _Valuable_ may dispose itself to avoid depending on a disposed _Valuable_.

However, even if a _Valuable_ could be auto-disposed because it watches a sibling, this isn't always true.
Look at this case:

```dart
final a = Valuable<bool>.value(true);
final b = Valuable<String>.value("ez");
final c = Valuable<String>.value("pz");
final d = Valuable<String>.computed((watch, {valuableContext}) {
    return watch(a) ? watch(b) : watch(c);
});

c.dispose();
```

As mentioned above, we could imagine that `d` will auto-dispose due to `c`'s disposal; however, this is not the case.  
Under the hood, `d` **never** watches `c` because `watch(a)` is always `true`, so it never registers to `c`'s disposal event either!

For this reason, `dispose` must be called at least once on each instantiated _Valuable_. Especially since the method can be called multiple times without any issues.

#### Watch for memory leaks

The package provides a singleton class `ValuableDebugSession` in order to get information on current _Valuable_ usage.

Even if this singleton is available in any mode, it only works during debug mode. Otherwise, it does nothing (to avoid consuming performance).

On it you access to :

- `mountedValuablesCount` that is the current number of mounted _Valuables_
- `totalValuablesCount` that is the ever existed number of _Valuables_
- `mountedCallablesCount` that is the current number of mounted `ValuableCallback`
- `totalCallablesCount` that is the ever existed number of `ValuableCallback`
- `eventsAwareCallablesCount` that is the current number of `ValuableCallback` in their reacting-to-event phase
- `printDebugInfo()` that prints all these values into the console using Flutter `debugPrint`

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

``FutureValuable<Output, Res>`` have been created in the purpose of computing a ``Valuable<Future<Res>>`` to a safe runtime ``Output`` value. In fact ``FutureValuable<Output, Res>`` inherits ``Valuable<Output>``, so it can use all of its useful methods.

There are 2 constructors that can be written.

#### FutureValuable computing constructor

```dart
    late final Valuable<Future<int>> distantCounter = ...
    late final FutureValuable<String, int> distantCounterStr = FutureValuable<String, int>(
            distantCounter,
            dataValue: (ValuableContext? context, int result) => "My counter is $result", // Future is done
            noDataValue: (ValuableContext? context) => "Still in progress", // Future is not done yet
            errorValue: (ValuableContext? context, Object error, StackTrace st) => "Can't retrieve counter !", // Future done in error
        );
```

This way, we can provide a value, depending of the ``Valuable<Future<Res>>`` state and value.

#### FutureValuable providing constructor

This constructor is the simpliest for the case ``Res == Output``, and provide value for waiting and error states.

```dart
    late final Valuable<Future<int>> distantCounter = ...
    late final FutureValuable<int, int> distantCounterVal = FutureValuable<int, int>.values(
            distantCounter,
            noDataValue: 0, // Future is not done yet
            errorValue: -1, // Future done in error
        );
```

Then the _Valuable_ always have a correct runtime value, without error management complexity.

#### FutureValuable AsyncValue 'constructor'

In some cases, it's not the desired behavior to map to a certain type ``Output``, but it's necessary to map dynamically during runtime.  
For that, it's possible to use this code below.

```dart
    late final Valuable<Future<int>> distantCounter = ...
    late final FutureValuableAsyncValue<int> distantCounterVal = FutureValuable.asyncVal(distantCounter);
```

The _Valuable_ returns a ``ValuableAsyncValue<int>``.  This kind of object is really useful as it offers a ``map()`` method to compute the current state of the Future.

### ``StreamValuable<Output, Msg>``

``StreamValuable<Output, Msg>`` works exactly the same as ``FutureValuable<Output, Msg>``, but remains on a ``Stream`` instead a ``Future``.

Let show the code directly !

#### StreamValuable computing constructor

```dart
    late final Valuable<Stream<int>> continuousCounter = ...
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

- simple immutable value, to interact with others _Valuable_
- auto evaluated _Valuable_, that can depend on others _Valuable_

#### Simple immutable value

```dart
    final Valuable<int> zero = Valuable.value(0);
```

#### Link to a ``ValueListenable``

```dart
    late final AnimatedController controller = AnimatedController();
    late final Valuable<double> vcont = Valuable<double>.listenable(controller);
```

#### Auto evaluated

```dart
    final StatefulValuable<int> counter = StatefulValuable<int>(2);
    final late Valuable<double> halfCounter = Valuable.evaluate((ValuableWatcher watch) => watch(counter) / 2);
    ...
    print(halfCounter.getValue()); // Print '1'
    counter.setValue(3); // halfCounter is notified of this change, marks as invalid, and notifies all its listeners
    print(halCounter.getValue()); // Print '1.5'
```

Here comes the real power of _Valuable_.  
This way, the _Valuables_ can be chained and then the graph is created.  
The differents states are defined directly by the _Valuable_ valuer and are safely used in the code through it.

### Some special _Valuable_

There are some special derivatives of _Valuable_, that can not really define how to get a value.  
These just link to another _Valuable_ to let it provide the value, but instead they allow extra behaviors.

#### ValuableLinker

The ``ValuableLinker`` is just an other _Valuable_, that just needs to have a default value.  
But its main purpose is to link to another _Valuable_ of the same generic type, to watch and provide a value.  

This way, we can delegate to a deeper node of the widget tree, the management of a _Valuable_ (that follows an ``Animation`` for example), and pass through the tree, a ``ValuableLinker`` to link to it.  
The linker became aware of any _Valuable_ changes !

Two methods are available on ``ValuableLinker<T>``, ``link(Valuable<T>)`` and ``unlink()``.  
As it was said, the main purpose of this class is to link to an other _Valuable_, but ``ValuableLinker`` can't link if already linked. In this case, a ``StateError`` is thrown.  
You shall unlink the ``ValuableLinker`` before reuse the ``link`` method (it was an arbitrary choice to make it explicit).

For a complete example, just refer to [sample_linker.dart](example/lib/src/sample_linker.dart) in the example.

#### HistorizedValuable

``HistorizedValuable`` is the contract class to describe a _Valuable_ that can maintain an history for all values of a _Valuable_.  

Historize a _Valuable_ is as simple as this:

```dart
    final historized = Valuable<T>().historize();
```

The ``historize()`` is available on the ``Valuable`` base type.

``HistorizedValuable`` is derivated to ``HistorizedStatefulValuable`` to historize the ``StatefulValuable`` and ``HistorizedValuableLinker`` to historize ``ValuableLinker``. This way, it can provide the transitive methods to each types (``setValue``, ``link``, etc.).

``HistorizedValuable`` provide an ``UnmodifiableQueueView<ValuableHistoryNode> get history`` accessor, that list all history node for a _Valuable_.

``StatefulValuable`` comes with an ``historizeRW`` method too. This method provide a ``ReWritableHistorizedValuable`` that is a ``StatefulValuable`` with extra methods/accessor to play with history:

- ``canUndo``, accessor to know if undo is possible
- ``canRedo``, accessor to know if redo is possible
- ``undoToInitial()``, that set the value to initial value in the history
- ``undo()``, that set the value to the previous in the history
- ``redo()``, that set the value to the next value in the history
- ``redoToCurrent()``, that set the value to latest value (current) in the history

Take a look to the great example in [sample_history.dart](example/lib/src/sample_history.dart)

### Valuable Scope

`ValuableScope` was introduced in order to simplify disposal of _Valuables_ created locally.  
Before, each _Valuable_ had to be disposed manually, so when we create too many _Valuables_ at the same place it can be easy to forget to dispose one or more...

`ValuableScope` defines factory methods to instantiate many kinds of _Valuable_ (and related helpers), including:
- `Valuable value(...)` &rarr; `Valuable.value`
- `Valuable computed(...)` &rarr; `Valuable.computed`
- `Valuable listenable(...)` &rarr; `Valuable.listenable`
- `Valuable listenableComputed(...)` &rarr; `Valuable.listenableComputed`
- `StatefulValuable stateful(...)` &rarr; `StatefulValuable`
- `Valuable<bool> groupAnd(...)` &rarr; `ValuableBoolGroup.and`
- `Valuable<bool> groupOr(...)` &rarr; `ValuableBoolGroup.or`
- `Valuable future(...)` &rarr; `FutureValuable`
- `Valuable futureToValues(...)` &rarr; `FutureValuable.values`
- `Valuable<ValuableAsyncValue> futureToAsyncVal(...)` &rarr; `FutureValuable.asyncVal`
- `Valuable stream(...)` &rarr; `StreamValuable`
- `Valuable streamToValues(...)` &rarr; `StreamValuable.values`
- `Valuable<ValuableAsyncValue> streamToAsyncVal(...)` &rarr; `StreamValuable.asyncVal`
- `Valuable ifThen(...)` &rarr; `ValuableIf`
- `Valuable ifThenValue(...)` &rarr; `ValuableIf.value`
- `Valuable switchCase(...)` &rarr; `ValuableSwitch`
- `Valuable switchCaseValue(...)` &rarr; `ValuableSwitch.value`
- `ValuableCallback callback(...)` &rarr; `ValuableCallback.immediate`
- `ValuableCallback futureCallback(...)` &rarr; `ValuableCallback.future`
- `ValuableCallback microtaskCallback(...)` &rarr; `ValuableCallback.microtask`
- `ValuableLinker linker(...)` → `ValuableLinker`
- `Valuable<bool> compare(...)` → `ValuableCompare`
- `Valuable<bool> eq(...)` → `ValuableCompare.equals`
- `Valuable<bool> gt(...)` → `ValuableCompare.greaterThan`
- `Valuable<bool> gte(...)` → `ValuableCompare.greaterOrEquals`
- `Valuable<bool> lt(...)` → `ValuableCompare.smallerThan`
- `Valuable<bool> lte(...)` → `ValuableCompare.smallerOrEquals`
- `Valuable<bool> neq(...)` → `ValuableCompare.different`
- `Valuable<num> sum(...)` → `ValuableNumOperation.sum`
- `Valuable<num> substract(...)` → `ValuableNumOperation.substract`
- `Valuable<num> multiply(...)` → `ValuableNumOperation.multiply`
- `Valuable<double> divide(...)` → `ValuableNumOperation.divide`
- `Valuable<int> truncDivide(...)` → `ValuableNumOperation.truncDivide`
- `Valuable<num> modulo(...)` → `ValuableNumOperation.modulo`
- `Valuable<num> negate(...)` → `ValuableNumOperation.negate`
- `Valuable<String> concatenate(...)` → `ValuableStringOperation.concate`
  
`nestedScope()` is a defined method of `ValuableScope` useful to define sub-scope that might be disposed before the entire parent scope. But if the parent scope is disposed, it disposes its children too.

Scope can be used directly by creating an instance of it, then use its methods to create wanted _Valuable_ and finally dispose it when need to.

Most of the time, _Valuables_ will be declared as member of a `State` instance, to be used by children Widgets. To avoid this boilerplate, a mixin for `State` is present into this package, `StateValuableScopeMixin`.

### `StateValuableScopeMixin`

As mentioned in the previous part, this mixin avoids some boilerplate by providing a `ValuableScope` directly inside a `State`.  
It gives access to a `vScope` member, which is a final `ValuableScope`. With it, you can create scoped _Valuables_ to use.  
`vScope` will be automatically disposed when the `State` is disposed, ensuring that all scoped _Valuables_ are disposed too.  
With this mixin, you no longer need to dispose _Valuables_ manually; just declare and use them!

But, there is another twist with this mixin...  

It may happen that you pass a `Valuable` as parameter to a `StatefulWidget`.  
By the way, you might watch it by local _Valuables_ in your `State`.  
For example :

```dart
class MyWidget extends StatefulWidget {
    MyWidget({
        required this.total,
        super.key,
    });

    final Valuable<double> total;

    @override
    State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with StateValuableScopeMixin<MyWidget> {

    late final color = widget.total.map((total) => total > 0.0 ? Colors.green : Colors.red);
    
    ...
}
```

This works most of time, but there is a problem.  
What happens if `MyWidget.total` change ?

Answer is &rarr; Nothing !  
While `color` doesn't need to compute, it will not register to the new `total` changes, leading to state loss.  
In order to resolve this situation, it is necessary to check for `MyWidget.total` instance change in `didUpdateWidget` then force `color.markToReevaluate`.
With one or two dependent _Valuables_ it could be acceptable, but for more it will become more and more complex.

This is for this reason that `StateValuableScopeMixin` came with the `interopValuableArg` method.  
This protected method allows to create a **proxy _Valuable_** for a Widget _Valuable_ parameter to manage changes and boilerplate describe before.

Updated code :

```dart
class MyWidget extends StatefulWidget {
    MyWidget({
        required this.total,
        super.key,
    });

    final Valuable<double> total;

    @override
    State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with StateValuableScopeMixin<MyWidget> {
    late final total = interopValuableArg((widget) => widget.total);
    late final color = total.map((total) => total > 0.0 ? Colors.green : Colors.red);

    ...
}
```

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

- ``+`` operator that produces a ``Valuable<num>``, result of the sum.
- ``-`` operator that produces a ``Valuable<num>``, result of the substraction.
- ``*`` operator that produces a ``Valuable<num>``, result of the multiplication.
- ``/`` operator that produces a ``Valuable<double>``, result of the division.
- ``%`` operator that produces a ``Valuable<num>``, result of the modulo.
- ``~/`` operator that produces a ``Valuable<int>``, result of the integer division.
- ``-Valuable<num>`` that produces a ``Valuable<num>``, that is the negated value.

#### ``Valuable<String>``

- ``+`` operator that produces a ``Valuable<String>``, result of the concatenation between two ``Valuable<String>``

#### ``StatefulValuable<bool>``

- ``negate()`` that changes the value to the opposite boolean value

#### ``StatefulValuable<num>``

- ``negate()`` that applies a ``-1`` factor to the value
- ``add(num other)`` that changes the value by adding ``other`` to current value
- ``substract(num other)`` that changes the value by substracting ``other`` to current value
- ``multiply(num other)`` that changes the value by multiplying ``other`` with current value

#### ``StatefulValuable<int>``

- ``increment()`` add one to current value
- ``decrement()`` substract one to current value
- ``divide(num other)`` that changes the value with an integer division by ``other``

#### ``StatefulValuable<double>``

- ``divide(num other)`` that changes by dividing current value with ``other``

#### ``ValueListenable<T>``

- ``toValuable`` provide a ``Valuable<T>`` by calling ``Valuable<T>.listenable(this)``

#### ``ValuableWatcher``

- ``T def<T>(Valuable<T>? valuable, T defaultValue)`` that extends the behavior of a ``ValuableWatcher`` to be used with a Nullable _Valuable_
  
### Operations

#### ``ValuableCompare<T>``

#### ``ValuableNumOperation<Output extends num>``

#### ``ValuableStringOperation``

#### ``ValuableSwitch<Switch, Output>``

#### ``ValuableIf<Output>``
