import 'package:flutter/material.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/stateful.dart';
import 'package:valuable/src/widgets.dart';

class DropdownButtonValuable<T> extends StatelessWidget {
  final StatefulValuable<T?> value;
  final List<DropdownMenuItem<T>>? items;
  final Valuable<List<DropdownMenuItem<T>>>? itemsValuable;

  final Widget? hint;
  final Valuable<Widget>? hintValuable;
  final Widget? disabledHint;
  final Valuable<Widget>? disabledHintValuable;
  final DropdownButtonBuilder? selectedItemBuilder;

  final int elevation;
  final Valuable<int>? elevationValuable;
  final TextStyle? style;
  final Valuable<TextStyle>? styleValuable;
  final Widget? underline;
  final Valuable<Widget>? underlineValuable;
  final Widget? icon;
  final Valuable<Widget>? iconValuable;
  final Color? iconDisabledColor;
  final Valuable<Color>? iconDisabledColorValuable;
  final Color? iconEnabledColor;
  final Valuable<Color>? iconEnabledColorValuable;
  final double iconSize;
  final Valuable<double>? iconSizeValuable;
  final bool? isDense;
  final Valuable<bool>? isDenseValuable;
  final bool? isExpanded;
  final Valuable<bool>? isExpandedValuable;

  final double? itemHeight;
  final Valuable<double>? itemHeightValuable;

  final Color? focusColor;
  final Valuable<Color>? focusColorValuable;
  final FocusNode? focusNode;

  final bool autofocus;

  final Color? dropdownColor;
  final Valuable<Color>? dropdownColorValuable;

  DropdownButtonValuable({
    required this.value,
    Key? key,
    this.items,
    this.itemsValuable,
    this.hint,
    this.hintValuable,
    this.disabledHint,
    this.disabledHintValuable,
    this.selectedItemBuilder,
    this.elevation = 8,
    this.elevationValuable,
    this.style,
    this.styleValuable,
    this.underline,
    this.underlineValuable,
    this.icon,
    this.iconValuable,
    this.iconDisabledColor,
    this.iconDisabledColorValuable,
    this.iconEnabledColor,
    this.iconEnabledColorValuable,
    this.iconSize = 24,
    this.iconSizeValuable,
    this.isDense,
    this.isDenseValuable,
    this.isExpanded,
    this.isExpandedValuable,
    this.itemHeight,
    this.itemHeightValuable,
    this.focusColor,
    this.focusColorValuable,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.dropdownColorValuable,
  })  : assert(items != null || itemsValuable != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValuableConsumer(
      builder: (BuildContext context, ValuableWatcher watch, Widget? child) {
        bool isDenseVal = isDenseValuable?.watchIt(context) ?? isDense ?? false;
        bool isExpandedVal =
            isExpandedValuable?.watchIt(context) ?? isExpanded ?? false;

        return DropdownButton<T>(
          items: itemsValuable?.watchIt(context) ?? items,
          onChanged: (T? value) {
            this.value.setValue(value);
          },
          value: watch(value),
          selectedItemBuilder: selectedItemBuilder,
          isDense: isDenseVal,
          isExpanded: isExpandedVal,
          autofocus: autofocus,
          disabledHint: disabledHintValuable?.watchIt(context) ?? disabledHint,
          dropdownColor:
              dropdownColorValuable?.watchIt(context) ?? dropdownColor,
          elevation: elevationValuable?.watchIt(context) ?? elevation,
          focusColor: focusColorValuable?.watchIt(context) ?? focusColor,
          focusNode: focusNode,
          hint: hintValuable?.watchIt(context) ?? hint,
          icon: iconValuable?.watchIt(context) ?? icon,
          iconDisabledColor:
              iconDisabledColorValuable?.watchIt(context) ?? iconDisabledColor,
          iconEnabledColor:
              iconEnabledColorValuable?.watchIt(context) ?? iconEnabledColor,
          iconSize: iconSizeValuable?.watchIt(context) ?? iconSize,
          itemHeight: itemHeightValuable?.watchIt(context) ?? itemHeight,
          style: styleValuable?.watchIt(context) ?? style,
          underline: underlineValuable?.watchIt(context) ?? underline,
        );
      },
    );
  }
}
