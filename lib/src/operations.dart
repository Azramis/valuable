import 'package:flutter/foundation.dart';
import 'package:valuable/src/base.dart';

/// Comparison operator
enum CompareOperator {
  equals,
  greater_than,
  smaller_than,
  greater_or_equals,
  smaller_or_equals,
  different
}

/// A class to map Valuables comparison to a [Valuable<bool>]
///
/// This object will notify any listeners when one of its operands changes
class ValuableCompare<T> extends Valuable<bool> {
  final Valuable<T> _operand1;
  final CompareOperator _operator;
  final Valuable<T> _operand2;

  /// Complete constuctor
  ValuableCompare(this._operand1, this._operator, this._operand2) : super();

  /// Equality comparator constructor
  ValuableCompare.equals(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.equals, operand2);

  /// Greater comparator constructor
  ValuableCompare.greaterThan(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.greater_than, operand2);

  /// Greater or equality comparator constructor
  ValuableCompare.greaterOrEquals(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.greater_or_equals, operand2);

  /// Smaller comparator constructor
  ValuableCompare.smallerThan(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.smaller_than, operand2);

  /// Smaller or equality comparator constructor
  ValuableCompare.smallerOrEquals(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.smaller_or_equals, operand2);

  /// Difference comparator constructor
  ValuableCompare.different(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.different, operand2);

  @override
  bool getValueDefinition([ValuableContext context = const ValuableContext()]) {
    return _compareWithOperator(context);
  }

  bool _compareWithOperator(ValuableContext valuableContext) {
    bool retour;
    dynamic fieldValue = watch(_operand1, valuableContext: valuableContext);
    dynamic compareValue = watch(_operand2, valuableContext: valuableContext);

    switch (_operator) {
      case CompareOperator.equals:
        retour = fieldValue == compareValue;
        break;
      case CompareOperator.greater_than:
        retour = fieldValue > compareValue;
        break;
      case CompareOperator.smaller_than:
        retour = fieldValue < compareValue;
        break;
      case CompareOperator.smaller_or_equals:
        retour = fieldValue <= compareValue;
        break;
      case CompareOperator.greater_or_equals:
        retour = fieldValue >= compareValue;
        break;
      case CompareOperator.different:
        retour = fieldValue != compareValue;
        break;
      default:
        retour = false;
        break;
    }
    return retour;
  }
}

/// Calculus operators for num operands
enum NumOperator {
  sum,
  substract,
  multiply,
  divide,
  modulo,
  trunc_divide,
  negate
}

/// Class to do calculus with numeric operands, and obtain a Valuable<num>.
///
/// When one of its operands changes, this Valuable notify its listeners
class ValuableNumOperation<Output extends num> extends Valuable<Output> {
  final Valuable<num> _operand1;
  final Valuable<num> _operand2;
  final NumOperator _operator;

  ValuableNumOperation._(this._operand1, this._operator, this._operand2)
      : super();

  /// Sum operation
  static ValuableNumOperation<num> sum(
          Valuable<num> operand1, Valuable<num> operand2) =>
      ValuableNumOperation._(operand1, NumOperator.sum, operand2);

  /// Substraction operation
  static ValuableNumOperation<num> substract(
          Valuable<num> operand1, Valuable<num> operand2) =>
      ValuableNumOperation._(operand1, NumOperator.substract, operand2);

  /// Multiplication operation
  static ValuableNumOperation<num> multiply(
          Valuable<num> operand1, Valuable<num> operand2) =>
      ValuableNumOperation._(operand1, NumOperator.multiply, operand2);

  /// Division operation
  static ValuableNumOperation<double> divide(
          Valuable<num> operand1, Valuable<num> operand2) =>
      _ValuableDoubleOperation(operand1, NumOperator.divide, operand2);

  /// Trunctature division operation
  static ValuableNumOperation<int> truncDivide(
          Valuable<num> operand1, Valuable<num> operand2) =>
      _ValuableIntOperation(operand1, NumOperator.trunc_divide, operand2);

  /// Modulo operation
  static ValuableNumOperation<num> modulo(
          Valuable<num> operand1, Valuable<num> operand2) =>
      ValuableNumOperation._(operand1, NumOperator.modulo, operand2);

  /// Negate operation
  static ValuableNumOperation<num> negate(Valuable<num> operand1) =>
      ValuableNumOperation._(operand1, NumOperator.sum, null);

  @override
  Output getValueDefinition(
      [ValuableContext context = const ValuableContext()]) {
    return _compareWithOperator(context);
  }

  Output _compareWithOperator(ValuableContext valuableContext) {
    num retour;
    num ope1 = watch(_operand1, valuableContext: valuableContext);
    num ope2 = _operator != NumOperator.negate
        ? watch(_operand2, valuableContext: valuableContext)
        : 0;

    switch (_operator) {
      case NumOperator.sum:
        retour = ope1 + ope2;
        break;
      case NumOperator.divide:
        retour = ope1 / ope2;
        break;
      case NumOperator.modulo:
        retour = ope1 % ope2;
        break;
      case NumOperator.multiply:
        retour = ope1 * ope2;
        break;
      case NumOperator.substract:
        retour = ope1 - ope2;
        break;
      case NumOperator.negate:
        retour = -ope1;
        break;
      default:
        retour = 0.0;
        break;
    }
    return retour;
  }
}

class _ValuableIntOperation extends ValuableNumOperation<int> {
  _ValuableIntOperation(
      Valuable<num> operand1, NumOperator operat, Valuable<num> operand2)
      : super._(operand1, operat, operand2);

  int _compareWithOperator(ValuableContext valuableContext) {
    int retour;
    num ope1 = watch(_operand1, valuableContext: valuableContext);
    num ope2 = _operator != NumOperator.negate
        ? watch(_operand2, valuableContext: valuableContext)
        : 0;

    switch (_operator) {
      case NumOperator.trunc_divide:
        retour = ope1 ~/ ope2;
        break;
      default:
        retour = super._compareWithOperator(valuableContext);
        break;
    }
    return retour;
  }
}

class _ValuableDoubleOperation extends ValuableNumOperation<double> {
  _ValuableDoubleOperation(
      Valuable<num> operand1, NumOperator operat, Valuable<num> operand2)
      : super._(operand1, operat, operand2);

  double _compareWithOperator(ValuableContext valuableContext) {
    double retour;
    num ope1 = watch(_operand1, valuableContext: valuableContext);
    num ope2 = _operator != NumOperator.negate
        ? watch(_operand2, valuableContext: valuableContext)
        : 0;

    switch (_operator) {
      case NumOperator.divide:
        retour = ope1 / ope2;
        break;
      default:
        retour = super._compareWithOperator(valuableContext);
        break;
    }
    return retour;
  }
}

/// Possible operations between Valuable<String>
enum StringOperator {
  concate,
}

/// Operations for String
class ValuableStringOperation extends Valuable<String> {
  final Valuable<String> _operand1;
  final Valuable<String> _operand2;
  final StringOperator _operator;

  ValuableStringOperation(this._operand1, this._operator, this._operand2)
      : super();

  /// Sum operation
  ValuableStringOperation.concate(
      Valuable<String> operand1, Valuable<String> operand2)
      : this(operand1, StringOperator.concate, operand2);

  @override
  String getValueDefinition(
      [ValuableContext context = const ValuableContext()]) {
    return _compareWithOperator(context);
  }

  String _compareWithOperator(ValuableContext valuableContext) {
    String retour;
    String ope1 = watch(_operand1, valuableContext: valuableContext);
    String ope2 = watch(_operand2, valuableContext: valuableContext);

    switch (_operator) {
      case StringOperator.concate:
        retour = ope1 + ope2;
        break;
      default:
        break;
    }

    return retour;
  }
}

class ValuableCaseItem<Output> {
  final dynamic caseValue;
  final ValuableParentWatcher<Output> getValue;

  ValuableCaseItem(this.caseValue, this.getValue);

  ValuableCaseItem.value(dynamic caseValue, Output value)
      : this(
            caseValue,
            (ValuableWatcher<dynamic> watch,
                    {ValuableContext valuableContext}) =>
                value);
}

class ValuableSwitch<Switch, Output> extends Valuable<Output> {
  final Valuable<Switch> testable;
  final List<ValuableCaseItem<Output>> cases;
  final ValuableParentWatcher<Output> defaultCase;

  ValuableSwitch(this.testable, {@required this.defaultCase, this.cases})
      : assert(testable != null, "testable must not be null !"),
        assert(defaultCase != null, "defaultCase must not be null !");

  ValuableSwitch.value(Valuable<Switch> testable,
      {@required Output defaultValue, List<ValuableCaseItem<Output>> cases})
      : this(testable,
            defaultCase: (ValuableWatcher<dynamic> watch,
                    {ValuableContext valuableContext}) =>
                defaultValue,
            cases: cases);

  @override
  Output getValueDefinition(
      [ValuableContext valuableContext = const ValuableContext()]) {
    bool test = false;
    Output value;
    if (cases?.isNotEmpty ?? false) {
      Iterator<ValuableCaseItem<Output>> iterator = cases.iterator;
      while (iterator.moveNext() &&
          (test = testable
                  .equals(iterator.current.caseValue)
                  .getValue(valuableContext) ==
              false)) {
        value =
            iterator.current.getValue(watch, valuableContext: valuableContext);
      }
    }

    if (test == false) {
      value = defaultCase(watch, valuableContext: valuableContext);
    }
    return value;
  }
}

class ValuableIf<Output> extends Valuable<Output> {
  final Valuable<bool> testable;
  final ValuableParentWatcher<Output> thenCase;
  final ValuableParentWatcher<Output> elseCase;

  ValuableIf(this.testable, this.thenCase, {this.elseCase})
      : assert(testable != null, "testable must not be null !"),
        assert(thenCase != null, "thenCase must not be null !");

  ValuableIf.value(Valuable<bool> testable, Output thenValue,
      {Output elseValue})
      : this(
          testable,
          (ValuableWatcher<dynamic> watch, {ValuableContext valuableContext}) =>
              thenValue,
          elseCase: (ValuableWatcher<dynamic> watch,
                  {ValuableContext valuableContext}) =>
              elseValue,
        );

  @override
  Output getValueDefinition(
      [ValuableContext valuableContext = const ValuableContext()]) {
    bool test = false;
    Output value;

    test = watch(testable);

    if (test) {
      value = thenCase(watch, valuableContext: valuableContext);
    } else {
      value = elseCase?.call(watch, valuableContext: valuableContext);
    }
    return value;
  }
}
