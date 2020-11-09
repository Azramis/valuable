// Comparator
import 'package:valuable/src/base.dart';

enum CompareOperator {
  equals,
  greater_than,
  smaller_than,
  greater_or_equals,
  smaller_or_equals,
  different
}

class ValuableCompare<T> extends ValuableBool {
  final Valuable<T> _operand1;
  final CompareOperator _operator;
  final Valuable<T> _operand2;

  ValuableCompare(this._operand1, this._operator, this._operand2)
      : super(false);

  // Equality comparator
  ValuableCompare.equals(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.equals, operand2);
  // Greater comparator
  ValuableCompare.greaterThan(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.greater_than, operand2);
  // Greater or equality comparator
  ValuableCompare.greaterOrEquals(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.greater_or_equals, operand2);
  // Smaller comparator
  ValuableCompare.smallerThan(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.smaller_than, operand2);
  // Smaller or equality comparator
  ValuableCompare.smallerOrEquals(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.smaller_or_equals, operand2);
  // Difference comparator
  ValuableCompare.different(Valuable<T> operand1, Valuable<T> operand2)
      : this(operand1, CompareOperator.different, operand2);

  @override
  bool getValue([ValuableContext context = const ValuableContext()]) {
    return _compareWithOperator(context);
  }

  bool _compareWithOperator(ValuableContext context) {
    bool retour;
    dynamic fieldValue = readValuable(_operand1, context);
    dynamic compareValue = readValuable(_operand2, context);

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

enum NumOperator {
  sum,
  substract,
  multiply,
  divide,
  modulo,
  trunc_divide,
  negate
}

class ValuableNumOperation extends ValuableNum {
  final Valuable<num> _operand1;
  final Valuable<num> _operand2;
  final NumOperator _operator;

  ValuableNumOperation(this._operand1, this._operator, this._operand2)
      : super(0);

  /// Sum operation
  ValuableNumOperation.sum(Valuable<num> operand1, Valuable<num> operand2)
      : this(operand1, NumOperator.sum, operand2);

  /// Substraction operation
  ValuableNumOperation.substract(Valuable<num> operand1, Valuable<num> operand2)
      : this(operand1, NumOperator.substract, operand2);

  /// Multiplication operation
  ValuableNumOperation.multiply(Valuable<num> operand1, Valuable<num> operand2)
      : this(operand1, NumOperator.multiply, operand2);

  /// Division operation
  ValuableNumOperation.divide(Valuable<num> operand1, Valuable<num> operand2)
      : this(operand1, NumOperator.divide, operand2);

  /// Trunctature division operation
  ValuableNumOperation.truncDivide(
      Valuable<num> operand1, Valuable<num> operand2)
      : this(operand1, NumOperator.trunc_divide, operand2);

  /// Modulo operation
  ValuableNumOperation.modulo(Valuable<num> operand1, Valuable<num> operand2)
      : this(operand1, NumOperator.modulo, operand2);

  /// Negate operation
  ValuableNumOperation.negate(Valuable<num> operand1)
      : this(operand1, NumOperator.sum, null);

  @override
  num getValue([ValuableContext context = const ValuableContext()]) {
    return _compareWithOperator(context);
  }

  num _compareWithOperator(ValuableContext context) {
    num retour;
    num ope1 = readValuable(_operand1, context);
    num ope2 =
        _operator != NumOperator.negate ? readValuable(_operand2, context) : 0;

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
      case NumOperator.trunc_divide:
        retour = ope1 ~/ ope2;
        break;
      case NumOperator.negate:
        retour = -ope1;
        break;
      default:
        retour = 0;
        break;
    }
    return retour;
  }
}

enum StringOperator {
  concate,
}

class ValuableStringOperation extends ValuableString {
  final Valuable<String> _operand1;
  final Valuable<String> _operand2;
  final StringOperator _operator;

  ValuableStringOperation(this._operand1, this._operator, this._operand2)
      : super("");

  /// Sum operation
  ValuableStringOperation.concate(
      Valuable<String> operand1, Valuable<String> operand2)
      : this(operand1, StringOperator.concate, operand2);

  @override
  String getValue([ValuableContext context = const ValuableContext()]) {
    return _compareWithOperator(context);
  }

  String _compareWithOperator(ValuableContext context) {
    String retour;
    String ope1 = readValuable(_operand1, context);
    String ope2 = readValuable(_operand2, context);

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
