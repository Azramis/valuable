import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleFutureWidget extends StatefulWidget {
  const SampleFutureWidget({super.key});
  @override
  State<SampleFutureWidget> createState() => _SampleFutureWidgetState();
}

class _SampleFutureWidgetState extends State<SampleFutureWidget>
    with StateValuableScopeMixin<SampleFutureWidget> {
  late final _textValue = vScope.stateful<String>("");
  late final _durationValue = vScope.stateful<Duration>(
    const Duration(seconds: 1),
  );

  late final _futureTextValue = vScope.computed((
    watch, {
    valuableContext,
  }) async {
    Duration duration = watch(_durationValue);
    await Future.delayed(duration);

    return watch(_textValue);
  });

  late final futureValuable = _futureTextValue.toFutureAsyncValue();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Valuable Text Widget")),
      body: Center(
        child: Column(
          children: <Widget>[
            TextField(onChanged: (value) => _textValue.setValue(value)),
            ValuableDurationSlider(duration: _durationValue),
            ValuableText(futureValuable),
          ],
        ),
      ),
    );
  }
}

class ValuableDurationSlider extends ValuableWidget {
  final StatefulValuable<Duration> duration;

  const ValuableDurationSlider({required this.duration, super.key});

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Slider(
      value: watch(duration).inSeconds.toDouble(),
      onChanged: (value) => duration.setValue(Duration(seconds: value.ceil())),
      divisions: 10,
      min: 0,
      max: 10,
    );
  }
}

class ValuableText extends ValuableWidget {
  final Valuable<ValuableAsyncValue<String>> textValuable;

  const ValuableText(this.textValuable, {super.key});

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    final asyncValue = watch(textValuable);

    return asyncValue.map(
      onData: (data) => Text(data.data),
      onError: (error) => Text(error.error.toString()),
      onNoData: (noData) => const CircularProgressIndicator(),
    );
  }
}
