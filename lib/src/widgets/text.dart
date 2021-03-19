import 'package:flutter/material.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/stateful.dart';
import 'package:valuable/src/widgets.dart';

import 'dart:ui' as ui show Shadow, FontFeature;

/// Provide a simple Text widget that depends on a Valuable
class ValuableText extends StatelessWidget {
  final Valuable<String> value;
  final TextStyle? style;
  final Valuable<TextStyle>? styleValuable;
  final int? maxLines;
  final Valuable<int>? maxLinesValuable;

  ValuableText(this.value,
      {Key? key,
      this.style,
      this.styleValuable,
      this.maxLines,
      this.maxLinesValuable})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValuableConsumer(
      builder: (BuildContext context, ValuableWatcher watch, Widget? child) {
        return Text(
          watch(value),
          style: styleValuable?.watchIt(context) ?? style,
          maxLines: maxLinesValuable?.watchIt(context) ?? maxLines,
        );
      },
    );
  }
}

class ValuableTextStyle extends StatefulValuable<TextStyle> {
  ValuableTextStyle(TextStyle initialState) : super(initialState);

  void copyWith({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
  }) {
    setValue(
      getValue().copyWith(
        inherit: inherit,
        color: color,
        backgroundColor: backgroundColor,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
        debugLabel: debugLabel,
      ),
    );
  }

  void apply({
    Color? color,
    Color? backgroundColor,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double decorationThicknessFactor = 1.0,
    double decorationThicknessDelta = 0.0,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    double fontSizeFactor = 1.0,
    double fontSizeDelta = 0.0,
    int fontWeightDelta = 0,
    FontStyle? fontStyle,
    double letterSpacingFactor = 1.0,
    double letterSpacingDelta = 0.0,
    double wordSpacingFactor = 1.0,
    double wordSpacingDelta = 0.0,
    double heightFactor = 1.0,
    double heightDelta = 0.0,
    TextBaseline? textBaseline,
    Locale? locale,
    List<ui.Shadow>? shadows,
    List<ui.FontFeature>? fontFeatures,
  }) {
    setValue(
      getValue().apply(
        color: color,
        backgroundColor: backgroundColor,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThicknessFactor: decorationThicknessFactor,
        decorationThicknessDelta: decorationThicknessDelta,
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSizeFactor: fontSizeFactor,
        fontSizeDelta: fontSizeDelta,
        fontWeightDelta: fontWeightDelta,
        fontStyle: fontStyle,
        letterSpacingFactor: letterSpacingFactor,
        letterSpacingDelta: letterSpacingDelta,
        wordSpacingFactor: wordSpacingFactor,
        wordSpacingDelta: wordSpacingDelta,
        heightFactor: heightFactor,
        heightDelta: heightDelta,
        textBaseline: textBaseline,
        locale: locale,
        shadows: shadows,
        fontFeatures: fontFeatures,
      ),
    );
  }
}
