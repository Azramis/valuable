import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleTextWidget extends StatefulWidget {
  const SampleTextWidget({super.key});
  @override
  State<SampleTextWidget> createState() => _SampleTextWidgetState();
}

class _SampleTextWidgetState extends State<SampleTextWidget>
    with StateValuableScopeMixin<SampleTextWidget> {
  late final _textValue = vScope.stateful("");
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Valuable Text Widget")),
      body: Center(
        child: Column(
          children: <Widget>[
            TextField(onChanged: (value) => _textValue.setValue(value)),
            ValuableText(_textValue),
          ],
        ),
      ),
    );
  }
}

class ValuableText extends ValuableWidget {
  final Valuable<String> textValuable;

  const ValuableText(this.textValuable, {super.key});

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Text(watch(textValuable));
  }
}
