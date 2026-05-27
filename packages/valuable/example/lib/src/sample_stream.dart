import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleStreamWidget extends StatefulWidget {
  const SampleStreamWidget({super.key});
  @override
  State<SampleStreamWidget> createState() => _SampleStreamWidgetState();
}

class _SampleStreamWidgetState extends State<SampleStreamWidget>
    with StateValuableScopeMixin<SampleStreamWidget> {
  late final _countdownValue = vScope.stateful(10);
  late final _durationValue = vScope.stateful(const Duration(seconds: 1));

  late final _streamValue = vScope.computed((watch, {valuableContext}) async* {
    Duration duration = watch(_durationValue);
    await Future.delayed(duration);

    int countdown = watch(_countdownValue);
    yield countdown;

    await Future.delayed(duration);

    while (countdown > 0) {
      yield --countdown;
      await Future.delayed(duration);
    }
  });

  late final _streamValuable = vScope.streamToAsyncVal(_streamValue);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Valuable Text Widget")),
      body: Center(
        child: Column(
          children: <Widget>[
            ValuableCountdownSlider(countdown: _countdownValue),
            ValuableDurationSlider(duration: _durationValue),
            ValuableText(_streamValuable),
          ],
        ),
      ),
    );
  }
}

class ValuableCountdownSlider extends ValuableWidget {
  final StatefulValuable<int> countdown;

  const ValuableCountdownSlider({required this.countdown, super.key});

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Slider(
      value: watch(countdown).toDouble(),
      onChanged: (value) => countdown.setValue(value.toInt()),
      divisions: 15,
      min: 5,
      max: 20,
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
  final Valuable<ValuableAsyncValue<int>> textValuable;

  const ValuableText(this.textValuable, {super.key});

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
