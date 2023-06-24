import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleStreamWidget extends StatefulWidget {
  const SampleStreamWidget({Key? key}) : super(key: key);
  @override
  _SampleStreamWidgetState createState() => _SampleStreamWidgetState();
}

class _SampleStreamWidgetState extends State<SampleStreamWidget> {
  final StatefulValuable<int> countdownValue = StatefulValuable(10);
  final StatefulValuable<Duration> durationValue =
      StatefulValuable(const Duration(seconds: 1));

  late final Valuable<Stream<int>> streamValue =
      Valuable<Stream<int>>.computed((watch, {valuableContext}) async* {
    Duration duration = watch(durationValue);
    await Future.delayed(duration);

    int countdown = watch(countdownValue);
    yield countdown;

    await Future.delayed(duration);

    while (countdown > 0) {
      yield --countdown;
      await Future.delayed(duration);
    }
  });

  late final StreamValuable<ValuableAsyncValue<int>, int> streamValuable =
      StreamValuable.asyncVal(streamValue);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Valuable Text Widget"),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            ValuableCountdownSlider(countdown: countdownValue),
            ValuableDurationSlider(
              duration: durationValue,
            ),
            ValuableText(streamValuable),
          ],
        ),
      ),
    );
  }
}

class ValuableCountdownSlider extends ValuableWidget {
  final StatefulValuable<int> countdown;

  const ValuableCountdownSlider({required this.countdown, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Slider(
      value: watch(countdown).toDouble(),
      onChanged: (value) => countdown.setValue(
        value.toInt(),
      ),
      divisions: 15,
      min: 5,
      max: 20,
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
  final StreamValuable<ValuableAsyncValue<int>, int> textValuable;

  const ValuableText(this.textValuable, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    ValuableAsyncValue<int> asyncValue = watch(textValuable);

    return asyncValue.map(
      onData: (data) => Text(data.data.toString()),
      onError: (error) => Text(error.error.toString()),
      onNoData: (noData) {
        if (noData.closed) {
          return const Icon(Icons.done);
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
