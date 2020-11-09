import 'package:example/src/sample_text.dart';
import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: /*MyHomePage(title: 'Flutter Demo Home Page')*/ SampleTextWidget(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final StatefulValuableBool _cbCheckSuper = StatefulValuableBool(false);
  final StatefulValuableBool _cbCheck1 = StatefulValuableBool(false);
  final StatefulValuableBool _cbCheck2 = StatefulValuableBool(false);
  final StatefulValuableBool _cbCheck3 = StatefulValuableBool(false);

  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Column(
          children: <Widget>[
            ValuableConsumer(
              builder: (context, watch, _) {
                return CheckboxListTile(
                    value: watch(_cbCheckSuper),
                    title: Text("Case Super"),
                    onChanged: (bool value) => _cbCheckSuper.setValue(value));
              },
            ),
            ValuableConsumer(
              builder: (context, watch, _) {
                return CheckboxListTile(
                    value: watch(_cbCheck1 | _cbCheckSuper),
                    title: Text("Case 1"),
                    onChanged: (bool value) => _cbCheck1.setValue(value));
              },
            ),
            ValuableConsumer(
              builder: (context, watch, _) {
                return CheckboxListTile(
                    value: watch(_cbCheck2 | _cbCheckSuper),
                    title: Text("Case 2"),
                    onChanged: (bool value) => _cbCheck2.setValue(value));
              },
            ),
            ValuableConsumer(
              builder: (context, watch, _) {
                return CheckboxListTile(
                    value: watch(_cbCheck3 | _cbCheckSuper),
                    title: Text("Case 3"),
                    onChanged: (bool value) => _cbCheck3.setValue(value));
              },
            ),
            ValuableConsumer(builder: (context, watch, _) {
              return Visibility(
                visible:
                    watch(_cbCheckSuper | _cbCheck1 & _cbCheck2 & _cbCheck3),
                child: Expanded(
                  child: Container(
                    color: Colors.blue,
                  ),
                ),
              );
            }),
          ],
        )
        // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
