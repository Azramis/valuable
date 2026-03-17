import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleCheckboxWidget extends StatefulWidget {
  const SampleCheckboxWidget({super.key});
  @override
  State<SampleCheckboxWidget> createState() => _SampleCheckboxWidgetState();
}

class _SampleCheckboxWidgetState extends State<SampleCheckboxWidget> {
  final StatefulValuable<bool> checkValue = StatefulValuable<bool>(false);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Valuable Checkbox Widget")),
      body: Center(
        child: Column(
          children: <Widget>[
            ValuableConsumer(
              builder: (BuildContext context, ValuableWatcher watch, _) {
                return watch(checkValue)
                    ? const Icon(Icons.verified, color: Colors.green)
                    : const Icon(Icons.cancel, color: Colors.red);
              },
            ),
            ValuableCheckbox(valuable: checkValue),
          ],
        ),
      ),
    );
  }
}

class ValuableCheckbox extends ValuableWidget {
  final StatefulValuable<bool?> valuable;

  const ValuableCheckbox({required this.valuable, super.key});

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Checkbox(value: watch(valuable), onChanged: valuable.setValue);
  }
}
