import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:valuable/valuable.dart';

class SampleLinker extends StatefulWidget {
  const SampleLinker({Key? key}) : super(key: key);

  @override
  State<SampleLinker> createState() => _SampleLinkerState();
}

class _SampleLinkerState extends State<SampleLinker> {
  final ValuableLinker<double> widthLinker = ValuableLinker<double>(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sample Linker"),
      ),
      body: Stack(children: [
        _LinkableContainer(widthLinker: widthLinker),
        _LinkedContainer(widthLinker),
      ]),
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
        child: const Row(
          children: [Icon(Icons.settings_accessibility)],
        ),
      ),
    );
  }
}

class _LinkableContainer extends StatefulWidget {
  final ValuableLinker<double>? widthLinker;

  const _LinkableContainer({this.widthLinker, Key? key}) : super(key: key);

  @override
  State<_LinkableContainer> createState() => __LinkableContainerState();
}

class __LinkableContainerState extends State<_LinkableContainer>
    with TickerProviderStateMixin {
  late final AnimationController animationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );
  late final Animation<Color?> animationColor =
      ColorTween(begin: Colors.blue, end: Colors.amber)
          .animate(animationController);

  late final Valuable<double> animationValuable =
      animationController.toValuable();
  late final Valuable<Color?> colorValuable = animationColor.toValuable();
  late final Valuable<double> widthValuable =
      Valuable<double>.computed((watch, {valuableContext}) {
    return lerpDouble(minWidth, maxWidth, watch(animationValuable)) ?? 0;
  });

  static const double minWidth = 56;
  static const double maxWidth = 240;

  @override
  void initState() {
    super.initState();
    widget.widthLinker?.link(widthValuable);
  }

  @override
  void didUpdateWidget(covariant _LinkableContainer oldWidget) {
    super.didUpdateWidget(oldWidget);

    oldWidget.widthLinker?.unlink();
    widget.widthLinker?.link(widthValuable);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      child: _ContainerValuable(
        widthValuable: widthValuable,
        colorValuable: colorValuable,
        child: IconButton(
          onPressed: () {
            if (animationController.isDismissed) {
              animationController.forward();
            } else if (animationController.isCompleted) {
              animationController.reverse();
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

  // ignore: unused_element
  const _ContainerValuable({
    // ignore: unused_element
    this.widthValuable,
    // ignore: unused_element
    this.heightValuable,
    // ignore: unused_element
    this.colorValuable,
    // ignore: unused_element
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
