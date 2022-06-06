import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleColorPickerWidget extends StatelessWidget {
  final StatefulValuable<double> redVal = StatefulValuable<double>(0);
  final StatefulValuable<double> greenVal = StatefulValuable<double>(0);
  final StatefulValuable<double> blueVal = StatefulValuable<double>(0);

  late final Valuable<Color> myColor = Valuable.byValuer(
    (watch, {valuableContext}) {
      return Color.fromARGB(
        255,
        watch(redVal).toInt(),
        watch(greenVal).toInt(),
        watch(blueVal).toInt(),
      );
    },
  );

  SampleColorPickerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Valuable Color Picker Widget"),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RGBValueSlider(
            rgbValue: redVal,
            title: "RED",
          ),
          RGBValueSlider(
            rgbValue: greenVal,
            title: "GREEN",
          ),
          RGBValueSlider(
            rgbValue: blueVal,
            title: "BLUE",
          ),
          Expanded(
            child: ColorShow(
              myColor: myColor,
            ),
          ),
        ],
      ),
    );
  }
}

class ColorShow extends ValuableWidget {
  final Valuable<Color> myColor;

  const ColorShow({
    required this.myColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, ValuableWatcher watch) => Container(
        color: watch(myColor),
      );
}

class RGBValueSlider extends ValuableWidget {
  final String title;
  final StatefulValuable<double> rgbValue;

  const RGBValueSlider({
    required this.rgbValue,
    required this.title,
    Key? key,
  }) : super(key: key);

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
