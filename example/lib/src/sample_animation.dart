import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:valuable/valuable.dart';

class SampleAnimation extends StatefulWidget {
  const SampleAnimation({Key? key}) : super(key: key);

  @override
  State<SampleAnimation> createState() => _SampleAnimationState();
}

class _SampleAnimationState extends State<SampleAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _animate = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  );
  late final Valuable<String> _valuable =
      _animate.toValuable().map((e) => e.toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the SampleBoolOpe object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Sample Animation"),
      ),
      body: Column(
        children: [
          TextButton(
            child: const Text("Click"),
            onPressed: () {
              if (_animate.isAnimating) {
                return;
              }

              if (_animate.isCompleted) {
                _animate.reverse();
              } else {
                _animate.forward();
              }
            },
          ),
          ValuableText(_valuable),
        ],
      ),
    );
  }
}
