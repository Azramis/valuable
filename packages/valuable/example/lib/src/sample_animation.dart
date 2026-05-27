import 'package:example/src/sample_text.dart';
import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleAnimation extends StatefulWidget {
  const SampleAnimation({super.key});

  @override
  State<SampleAnimation> createState() => _SampleAnimationState();
}

class _SampleAnimationState extends State<SampleAnimation>
    with TickerProviderStateMixin, StateValuableScopeMixin<SampleAnimation> {
  late final _animate = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
  );
  late final _valuable = _animate.toValuable(vScope).map((e) => e.toString());

  @override
  void dispose() {
    _animate.dispose();
    super.dispose();
  }

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
