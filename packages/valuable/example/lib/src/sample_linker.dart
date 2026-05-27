// ignore_for_file: unused_element_parameter

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleLinker extends StatefulWidget {
  const SampleLinker({super.key});

  @override
  State<SampleLinker> createState() => _SampleLinkerState();
}

class _SampleLinkerState extends State<SampleLinker>
    with StateValuableScopeMixin<SampleLinker> {
  late final widthLinker = vScope.linker(0.0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sample Linker")),
      body: Stack(
        children: [
          _LinkableContainer(widthLinker: widthLinker),
          _LinkedContainer(widthLinker),
        ],
      ),
    );
  }
}

class _LinkedContainer extends ValuableWidget {
  final Valuable<double> leftOffset;

  const _LinkedContainer(this.leftOffset);

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Positioned(
      top: watch(leftOffset),
      right: watch(leftOffset),
      left: watch(leftOffset),
      child: Container(
        color: Colors.green,
        child: const Row(children: [Icon(Icons.settings_accessibility)]),
      ),
    );
  }
}

class _LinkableContainer extends StatefulWidget {
  final ValuableLinker<double>? widthLinker;

  const _LinkableContainer({this.widthLinker, super.key});

  @override
  State<_LinkableContainer> createState() => __LinkableContainerState();
}

class __LinkableContainerState extends State<_LinkableContainer>
    with TickerProviderStateMixin, StateValuableScopeMixin<_LinkableContainer> {
  late final _animationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  late final _animationColor = ColorTween(
    begin: Colors.blue,
    end: Colors.amber,
  ).animate(_animationController);

  late final _animationValuable = _animationController.toValuable(vScope);
  late final _colorValuable = _animationColor.toValuable(vScope);
  late final _widthValuable = vScope.computed(
    (watch, {valuableContext}) =>
        lerpDouble(minWidth, maxWidth, watch(_animationValuable)) ?? 0,
  );

  static const double minWidth = 56;
  static const double maxWidth = 240;

  @override
  void initState() {
    super.initState();
    widget.widthLinker?.link(_widthValuable);
  }

  @override
  void didUpdateWidget(covariant _LinkableContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    oldWidget.widthLinker?.unlink(_widthValuable);
    widget.widthLinker?.link(_widthValuable);
  }

  @override
  void dispose() {
    widget.widthLinker?.unlink(_widthValuable);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      child: _ContainerValuable(
        widthValuable: _widthValuable,
        colorValuable: _colorValuable,
        child: IconButton(
          onPressed: () {
            if (_animationController.isDismissed) {
              _animationController.forward();
            } else if (_animationController.isCompleted) {
              _animationController.reverse();
            }
          },
          icon: const Icon(Icons.animation),
        ),
      ),
    );
  }
}

class _ContainerValuable extends ValuableWidget {
  final Valuable<double?>? widthValuable;
  final Valuable<double?>? heightValuable;
  final Valuable<Color?>? colorValuable;
  final Widget? child;

  const _ContainerValuable({
    this.widthValuable,
    this.heightValuable,
    this.colorValuable,
    this.child,
  });

  @override
  Widget build(BuildContext context, ValuableWatcher watch) {
    return Container(
      width: watch.def(widthValuable, null),
      height: watch.def(heightValuable, null),
      color: watch.def(colorValuable, null),
      child: child,
    );
  }
}
