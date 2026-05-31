import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleBoolOpe extends StatefulWidget {
  const SampleBoolOpe({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<SampleBoolOpe> createState() => _SampleBoolOpeState();
}

class _SampleBoolOpeState extends State<SampleBoolOpe>
    with StateValuableScopeMixin<SampleBoolOpe> {
  late final _cbCheckSuper = vScope.stateful<bool>(false);
  late final _cbCheck1 = vScope.stateful<bool>(false);
  late final _cbCheck2 = vScope.stateful<bool>(false);
  late final _cbCheck3 = vScope.stateful<bool>(false);

  late final _cbCheck1OrSuper = _cbCheck1 | _cbCheckSuper;
  late final _cbCheck2OrSuper = _cbCheck2 | _cbCheckSuper;
  late final _cbCheck3OrSuper = _cbCheck3 | _cbCheckSuper;

  late final _cbCheckAll = (_cbCheck1 & _cbCheck2 & _cbCheck3);
  late final _cbCheckAllOrSuper = _cbCheckAll | _cbCheckSuper;
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the SampleBoolOpe object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          ValuableConsumer(
            builder: (context, watch, _) {
              return CheckboxListTile(
                value: watch(_cbCheckSuper),
                title: const Text("Case Super"),
                onChanged: (value) => _cbCheckSuper.setValue(value!),
              );
            },
          ),
          ValuableConsumer(
            builder: (context, watch, _) {
              return CheckboxListTile(
                value: watch(_cbCheck1OrSuper),
                title: const Text("Case 1"),
                onChanged: (value) => _cbCheck1.setValue(value!),
              );
            },
          ),
          ValuableConsumer(
            builder: (context, watch, _) {
              return CheckboxListTile(
                value: watch(_cbCheck2OrSuper),
                title: const Text("Case 2"),
                onChanged: (value) => _cbCheck2.setValue(value!),
              );
            },
          ),
          ValuableConsumer(
            builder: (context, watch, _) {
              return CheckboxListTile(
                value: watch(_cbCheck3OrSuper),
                title: const Text("Case 3"),
                onChanged: (value) => _cbCheck3.setValue(value!),
              );
            },
          ),
          Expanded(
            child: ValuableConsumer(
              builder: (context, watch, _) {
                return Visibility(
                  visible: watch(_cbCheckAllOrSuper),
                  child: Container(color: Colors.blue),
                );
              },
            ),
          ),
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
