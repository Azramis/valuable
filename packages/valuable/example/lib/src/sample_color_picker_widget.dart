import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleColorPickerWidget extends StatefulWidget {
  const SampleColorPickerWidget({super.key});

  @override
  State<SampleColorPickerWidget> createState() =>
      _SampleColorPickerWidgetState();
}

class _SampleColorPickerWidgetState extends State<SampleColorPickerWidget>
    with StateValuableScopeMixin<SampleColorPickerWidget> {
  late final _redVal = vScope.stateful<double>(0);
  late final _greenVal = vScope.stateful<double>(0);
  late final _blueVal = vScope.stateful<double>(0);

  late final _myColor = vScope.computed(
    (watch, {valuableContext}) => Color.fromARGB(
      255,
      watch(_redVal).toInt(),
      watch(_greenVal).toInt(),
      watch(_blueVal).toInt(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Valuable Color Picker Widget")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RGBValueSlider(rgbValue: _redVal, title: "RED"),
          RGBValueSlider(rgbValue: _greenVal, title: "GREEN"),
          RGBValueSlider(rgbValue: _blueVal, title: "BLUE"),
          Expanded(child: ColorShow(myColor: _myColor)),
        ],
      ),
    );
  }
}

class ColorShow extends ValuableWidget {
  final Valuable<Color> myColor;

  const ColorShow({required this.myColor, super.key});

  @override
  Widget build(BuildContext context, ValuableWatcher watch) =>
      Container(color: watch(myColor));
}

class RGBValueSlider extends ValuableWidget {
  final String title;
  final StatefulValuable<double> rgbValue;

  const RGBValueSlider({
    required this.rgbValue,
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context, ValuableWatcher watch) => Column(
    children: [
      Text(title),
      Slider(
        value: watch(rgbValue),
        onChanged: rgbValue.setValue,
        min: 0,
        max: 255,
      ),
    ],
  );
}
