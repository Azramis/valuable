import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleFutureWidget extends StatefulWidget {
  const SampleFutureWidget({Key? key}) : super(key: key);
  @override
  _SampleFutureWidgetState createState() => _SampleFutureWidgetState();
}

class _SampleFutureWidgetState extends State<SampleFutureWidget> {
  final StatefulValuable<String> textValue = StatefulValuable("");
  final StatefulValuable<Duration> durationValue =
      StatefulValuable(const Duration(seconds: 1));

  late final Valuable<Future<String>> futureTextValue =
      Valuable<Future<String>>.computed((watch, {valuableContext}) async {
    Duration duration = watch(durationValue);
    await Future.delayed(duration);

    return watch(textValue);
  });

  late final FutureValuableAsyncValue<String> futureValuable =
      futureTextValue.toFutureAsyncValue();

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
            ValuableDurationSlider(
              duration: durationValue,
            ),
            ValuableText(futureValuable),
          ],
        ),
      ),
    );
  }
}

class ValuableDurationSlider extends ValuableWidget {
  final StatefulValuable<Duration> duration;

  const ValuableDurationSlider({required this.duration, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Slider(
      value: watch(duration).inSeconds.toDouble(),
      onChanged: (value) => duration.setValue(
        Duration(
          seconds: value.ceil(),
        ),
      ),
      divisions: 10,
      min: 0,
      max: 10,
    );
  }
}

class ValuableText extends ValuableWidget {
  final FutureValuable<ValuableAsyncValue<String>, String> textValuable;

  const ValuableText(this.textValuable, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    ValuableAsyncValue<String> asyncValue = watch(textValuable);

    return asyncValue.map(
      onData: (data) => Text(data.data),
      onError: (error) => Text(error.error.toString()),
      onNoData: (noData) => const CircularProgressIndicator(),
    );
  }
}
