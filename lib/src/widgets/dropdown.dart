import 'package:flutter/material.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/stateful.dart';
import 'package:valuable/src/widgets.dart';

class DropdownButtonValuable<T> extends StatelessWidget {
  final StatefulValuable<T> value;
  final List<DropdownMenuItem<T>> items;
  final Valuable<List<DropdownMenuItem<T>>> itemsValuable;

  final Widget hint;
  final Valuable<Widget> hintValuable;
  final Widget disabledHint;
  final Valuable<Widget> disabledHintValuable;
  final DropdownButtonBuilder selectedItemBuilder;

  final int elevation;
  final Valuable<int> elevationValuable;
  final TextStyle style;
  final Valuable<TextStyle> styleValuable;
  final Widget underline;
  final Valuable<Widget> underlineValuable;
  final Widget icon;
  final Valuable<Widget> iconValuable;
  final Color iconDisabledColor;
  final Valuable<Color> iconDisabledColorValuable;
  final Color iconEnabledColor;
  final Valuable<Color> iconEnabledColorValuable;
  final double iconSize;
  final Valuable<double> iconSizeValuable;
  final bool isDense;
  final Valuable<bool> isDenseValuable;
  final bool isExpanded;
  final Valuable<bool> isExpandedValuable;

  final double itemHeight;
  final Valuable<double> itemHeightValuable;

  final Color focusColor;
  final Valuable<Color> focusColorValuable;
  final FocusNode focusNode;

  final bool autofocus;

  final Color dropdownColor;
  final Valuable<Color> dropdownColorValuable;

  DropdownButtonValuable({
    @required this.value,
    Key key,
    this.items,
    this.itemsValuable,
    this.hint,
    this.hintValuable,
    this.disabledHint,
    this.disabledHintValuable,
    this.selectedItemBuilder,
    this.elevation,
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
    this.iconSize,
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
    this.autofocus,
    this.dropdownColor,
    this.dropdownColorValuable,
  })  : assert(items != null || itemsValuable != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValuableConsumer(
      builder: (BuildContext context, ValuableWatcher watch, Widget child) {
        bool isDenseVal = isDenseValuable?.watch(context) ?? isDense;
        bool isExpandedVal = isExpandedValuable?.watch(context) ?? isExpanded;

        return DropdownButton<T>(
          items: itemsValuable?.watch(context) ?? itemsValuable,
          onChanged: (T value) {
            this.value.setValue(value);
          },
          value: watch(value),
          selectedItemBuilder: selectedItemBuilder,
          isDense: isDenseVal,
          isExpanded: isExpandedVal,
          autofocus: autofocus,
          disabledHint: disabledHintValuable?.watch(context) ?? disabledHint,
          dropdownColor: dropdownColorValuable?.watch(context) ?? dropdownColor,
          elevation: elevationValuable?.watch(context) ?? elevation,
          focusColor: focusColorValuable?.watch(context) ?? focusColor,
          focusNode: focusNode,
          hint: hintValuable?.watch(context) ?? hint,
          icon: iconValuable?.watch(context) ?? icon,
          iconDisabledColor:
              iconDisabledColorValuable?.watch(context) ?? iconDisabledColor,
          iconEnabledColor:
              iconEnabledColorValuable?.watch(context) ?? iconEnabledColor,
          iconSize: iconSizeValuable?.watch(context) ?? iconSize,
          itemHeight: itemHeightValuable?.watch(context) ?? itemHeight,
          style: styleValuable?.watch(context) ?? style,
          underline: underlineValuable?.watch(context) ?? underline,
        );
      },
    );
  }
}
