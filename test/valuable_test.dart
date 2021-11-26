import 'package:valuable/valuable.dart';

void main() {
  Test().test();
}

class Test {
  final StatefulValuable<int> cpt = StatefulValuable<int>(0);

  ValuableCallback get ecrire => ValuableCallback((ValuableWatcher watch,
          {ValuableContext? valuableContext}) {
        print(watch(cpt));
      });

  void test() {
    ecrire();

    for (int count = cpt.getValue(); count <= 10; count++) {
      cpt.setValue(count);
    }
  }
}
