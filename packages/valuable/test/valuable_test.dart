import 'package:valuable/valuable.dart';

void main() async {
  await Future(
    () => print('Future #1'),
  );
  Future(
    () => print('Future #1 bis'),
  );
  Test().test();
  await Future(
    () => print('Future #2'),
  );
}

class Test {
  final StatefulValuable<int> cpt = StatefulValuable<int>(0);

  ValuableCallback get ecrire => ValuableCallback.immediate(
          (ValuableWatcher watch, {ValuableContext? valuableContext}) {
        print('Immediate : ${watch(cpt)}');
      });

  ValuableCallback get ecrireMicrotask => ValuableCallback.microtask(
          (ValuableWatcher watch, {ValuableContext? valuableContext}) {
        print('Microtask : ${watch(cpt)}');
      });

  ValuableCallback get ecrireFuture => ValuableCallback.future(
          (ValuableWatcher watch, {ValuableContext? valuableContext}) {
        print('Future : ${watch(cpt)}');
      });

  void test() {
    ecrire();
    ecrireMicrotask();
    ecrireFuture();

    for (int count = cpt.getValue(); count <= 10; count++) {
      cpt.setValue(count);
    }
  }
}
