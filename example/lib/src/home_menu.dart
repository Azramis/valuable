import 'package:example/src/sample_bool_ope.dart';
import 'package:example/src/sample_checkbox.dart';
import 'package:example/src/sample_text.dart';
import 'package:flutter/material.dart';

class HomeMenu extends StatelessWidget {
  final List<_MenuItem> menus = <_MenuItem>[
    _MenuItem(
        name: "Checkbox",
        icon: Icons.check_box,
        callback: _callbackPush(
          (context) => SampleCheckboxWidget(),
        )),
    _MenuItem(
      name: "Text",
      icon: Icons.text_fields,
      callback: _callbackPush(
        (context) => SampleTextWidget(),
      ),
    ),
    _MenuItem(
      name: "Bool operation",
      icon: Icons.account_tree,
      callback: _callbackPush(
        (context) => SampleBoolOpe(),
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
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
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

  const _MenuItem({this.name, this.icon, this.callback});
}
