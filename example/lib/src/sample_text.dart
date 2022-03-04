import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleTextWidget extends StatefulWidget {
  const SampleTextWidget({Key? key}) : super(key: key);
  @override
  _SampleTextWidgetState createState() => _SampleTextWidgetState();
}

class _SampleTextWidgetState extends State<SampleTextWidget> {
  final StatefulValuable<String> textValue = StatefulValuable<String>("");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Valuable Text Widget"),
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
