import 'package:flutter/material.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/stateful.dart';
import 'package:valuable/src/widgets.dart';

class ValuableCheckbox extends StatelessWidget {
  /// Valuable to manage checkbox value
  final StatefulValuable<bool?> valuable;

  /* ********************************* */
  /*        Checkbox properties        */
  /* ********************************* */

  /// The color to use when this checkbox is checked.
  ///
  /// Defaults to [ThemeData.toggleableActiveColor].
  final Color? activeColor;

  /// See [activeColor]
  ///
  /// Priority if not null
  final Valuable<Color>? activeColorValuable;

  /// The color to use for the check icon when this checkbox is checked.
  ///
  /// Defaults to Color(0xFFFFFFFF)
  final Color? checkColor;

  /// See [checkColor]
  ///
  /// Priority if not null
  final Valuable<Color>? checkColorValuable;

  /// If true the checkbox's [value] can be true, false, or null.
  ///
  /// Checkbox displays a dash when its value is null.
  ///
  /// When a tri-state checkbox ([tristate] is true) is tapped, its [onChanged]
  /// callback will be applied to true if the current value is false, to null if
  /// value is true, and to false if value is null (i.e. it cycles through false
  /// => true => null => false when tapped).
  ///
  /// If tristate is false (the default), [value] must not be null.
  final bool tristate;

  /// See [tristate]
  ///
  /// Priority if not null
  final Valuable<bool>? tristateValuable;

  /// The color for the checkbox's [Material] when it has the input focus.
  final Color? focusColor;

  /// See [focusColor]
  ///
  /// Priority if not null
  final Valuable<Color>? focusColorValuable;

  /// The color for the checkbox's [Material] when a pointer is hovering over it.
  final Color? hoverColor;

  /// See [hoverColor]
  ///
  /// Priority if not null
  final Valuable<Color>? hoverColorValuable;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.Focus.autofocus}
  final bool autofocus;

  const ValuableCheckbox(
      {Key? key,
      required this.valuable,
      this.activeColor,
      this.activeColorValuable,
      this.autofocus = false,
      this.checkColor,
      this.checkColorValuable,
      this.focusColor,
      this.focusColorValuable,
      this.focusNode,
      this.hoverColor,
      this.hoverColorValuable,
      this.tristate = false,
      this.tristateValuable})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValuableConsumer(
      builder: (BuildContext context, ValuableWatcher watch, Widget? child) {
        bool tristateVal = tristateValuable?.watchIt(context) ?? tristate;
        bool? value =
            tristateVal ? watch(valuable) : (watch(valuable) ?? false);

        return Checkbox(
          value: value,
          onChanged: (bool? value) => valuable.setValue(value),
          activeColor: activeColorValuable?.watchIt(context) ?? activeColor,
          autofocus: autofocus,
          checkColor: checkColorValuable?.watchIt(context) ?? checkColor,
          focusColor: focusColorValuable?.watchIt(context) ?? focusColor,
          focusNode: focusNode,
          hoverColor: hoverColorValuable?.watchIt(context) ?? hoverColor,
          tristate: tristateVal,
        );
      },
    );
  }
}
