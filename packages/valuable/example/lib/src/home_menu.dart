import 'package:example/src/sample_animation.dart';
import 'package:example/src/sample_bool_ope.dart';
import 'package:example/src/sample_checkbox.dart';
import 'package:example/src/sample_color_picker_widget.dart';
import 'package:example/src/sample_future.dart';
import 'package:example/src/sample_history.dart';
import 'package:example/src/sample_linker.dart';
import 'package:example/src/sample_stream.dart';
import 'package:example/src/sample_text.dart';
import 'package:flutter/material.dart';

class HomeMenu extends StatelessWidget {
  HomeMenu({Key? key}) : super(key: key);
  final List<_MenuItem> menus = <_MenuItem>[
    _MenuItem(
        name: "Checkbox",
        icon: Icons.check_box,
        callback: _callbackPush(
          (context) => const SampleCheckboxWidget(),
        )),
    _MenuItem(
      name: "Text",
      icon: Icons.text_fields,
      callback: _callbackPush(
        (context) => const SampleTextWidget(),
      ),
    ),
    _MenuItem(
      name: "Bool operation",
      icon: Icons.account_tree,
      callback: _callbackPush(
        (context) => const SampleBoolOpe(title: "Bool operation"),
      ),
    ),
    _MenuItem(
      name: "Color Picker",
      icon: Icons.account_tree,
      callback: _callbackPush(
        (context) => SampleColorPickerWidget(),
      ),
    ),
    _MenuItem(
      name: "Animation",
      icon: Icons.animation,
      callback: _callbackPush(
        (context) => const SampleAnimation(),
      ),
    ),
    _MenuItem(
      name: "History",
      icon: Icons.history,
      callback: _callbackPush(
        (context) => const SampleHistory(),
      ),
    ),
    _MenuItem(
      name: "Linker",
      icon: Icons.link,
      callback: _callbackPush(
        (context) => const SampleLinker(),
      ),
    ),
    _MenuItem(
      name: "Future",
      icon: Icons.agriculture,
      callback: _callbackPush(
        (context) => const SampleFutureWidget(),
      ),
    ),
    _MenuItem(
      name: "Stream",
      icon: Icons.stream,
      callback: _callbackPush(
        (context) => const SampleStreamWidget(),
      ),
    ),
  ];

  static void Function(BuildContext context) _callbackPush(
      WidgetBuilder builder) {
    return (BuildContext context) async {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: builder,
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: GridView.builder(
        itemCount: menus.length,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemBuilder: (BuildContext context, int index) {
          return Card(
            color: Colors.indigoAccent.shade100,
            child: InkWell(
              onTap: () => menus[index].callback(context),
              child: GridTile(
                child: Icon(menus[index].icon),
                footer: GridTileBar(
                  title: Text(menus[index].name),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final String name;
  final IconData icon;
  final void Function(BuildContext context) callback;

  const _MenuItem({
    required this.name,
    required this.icon,
    required this.callback,
  });
}
