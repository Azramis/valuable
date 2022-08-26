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