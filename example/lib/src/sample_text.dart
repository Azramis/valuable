import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleTextWidget extends StatefulWidget {
  @override
  _SampleTextWidgetState createState() => _SampleTextWidgetState();
}

class _SampleTextWidgetState extends State<SampleTextWidget> {
  final StatefulValuable<String> textValue = StatefulValuable<String>("");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Valuable Text Widget"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            TextField(
              onChanged: (value) => textValue.setValue(value),
            ),
            ValuableText(textValue),
          ],
        ),
      ),
    );
  }
}
