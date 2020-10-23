import 'package:flutter/material.dart';
import 'package:valuable/src/base.dart';
import 'package:valuable/src/mixins.dart';

class StatefulValuable<T> extends Valuable<T> {
  T _state;

  StatefulValuable(T initialState)
      : _state = initialState,
        super();

  void setValue(T value) {
    if (_state != value) {
      _state = value;
      notifyListeners();
    }
  }

  T getValue(BuildContext context) => _state;
}

class StatefulValuableBool extends StatefulValuable<bool>
    with ValuableBoolOperators {
  StatefulValuableBool(bool initialValue) : super(initialValue);
}
