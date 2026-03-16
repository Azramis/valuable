import 'package:valuable/src/base.dart';

/// Comparison operator
enum CompareOperator {
  equals,
  greaterThan,
  smallerThan,
  greaterOrEquals,
  smallerOrEquals,
  different;

  @Deprecated('Use .greaterThan instead')
  // ignore: non_constant_identifier_names
  static CompareOperator get greater_than => CompareOperator.greaterThan;
  @Deprecated('Use .smallerThan instead')
  // ignore: non_constant_identifier_names
  static CompareOperator get smaller_than => CompareOperator.smallerThan;
  @Deprecated('Use .greaterOrEquals instead')
  // ignore: non_constant_identifier_names
  static CompareOperator get greater_or_equals =>
      CompareOperator.greaterOrEquals;
  @Deprecated('Use .smallerOrEquals instead')
  // ignore: non_constant_identifier_names
  static CompareOperator get smaller_or_equals =>
      CompareOperator.smallerOrEquals;
}

/// A class to map Valuables comparison to a [Valuable<bool>]
///
/// This object will notify any listeners when one of its operands changes
final class ValuableCompare<T> extends Valuable<bool> {
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
    : this(operand1, CompareOperator.greaterThan, operand2);

  /// Greater or equality comparator constructor
  ValuableCompare.greaterOrEquals(Valuable<T> operand1, Valuable<T> operand2)
    : this(operand1, CompareOperator.greaterOrEquals, operand2);

  /// Smaller comparator constructor
  ValuableCompare.smallerThan(Valuable<T> operand1, Valuable<T> operand2)
    : this(operand1, CompareOperator.smallerThan, operand2);

  /// Smaller or equality comparator constructor
  ValuableCompare.smallerOrEquals(Valuable<T> operand1, Valuable<T> operand2)
    : this(operand1, CompareOperator.smallerOrEquals, operand2);

  /// Difference comparator constructor
  ValuableCompare.different(Valuable<T> operand1, Valuable<T> operand2)
    : this(operand1, CompareOperator.different, operand2);

  @override
  bool getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? context = const ValuableContext(),
  ]) {
    return _compareWithOperator(context);
  }

  bool _compareWithOperator(ValuableContext? valuableContext) {
    dynamic fieldValue = watch(_operand1, valuableContext: valuableContext);
    dynamic compareValue = watch(_operand2, valuableContext: valuableContext);

    return switch (_operator) {
      .equals => fieldValue == compareValue,
      .greaterThan => fieldValue > compareValue,
      .smallerThan => fieldValue < compareValue,
      .smallerOrEquals => fieldValue <= compareValue,
      .greaterOrEquals => fieldValue >= compareValue,
      .different => fieldValue != compareValue,
    };
  }
}

/// Calculus operators for num operands
enum NumOperator {
  sum,
  substract,
  multiply,
  divide,
  modulo,
  truncDivide,
  negate,
}

/// Class to do calculus with numeric operands, and obtain a [Valuable<num>].
///
/// When one of its operands changes, this Valuable notify its listeners
class ValuableNumOperation<Output extends num> extends Valuable<Output> {
  final Valuable<num> _operand1;
  final Valuable<num>? _operand2;
  final NumOperator _operator;

  ValuableNumOperation._(this._operand1, this._operator, this._operand2)
    : super();

  /// Sum operation
  static ValuableNumOperation<num> sum(
    Valuable<num> operand1,
    Valuable<num> operand2,
  ) => ValuableNumOperation._(operand1, NumOperator.sum, operand2);

  /// Substraction operation
  static ValuableNumOperation<num> substract(
    Valuable<num> operand1,
    Valuable<num> operand2,
  ) => ValuableNumOperation._(operand1, NumOperator.substract, operand2);

  /// Multiplication operation
  static ValuableNumOperation<num> multiply(
    Valuable<num> operand1,
    Valuable<num> operand2,
  ) => ValuableNumOperation._(operand1, NumOperator.multiply, operand2);

  /// Division operation
  static ValuableNumOperation<double> divide(
    Valuable<num> operand1,
    Valuable<num> operand2,
  ) => _ValuableDoubleOperation(operand1, NumOperator.divide, operand2);

  /// Trunctature division operation
  static ValuableNumOperation<int> truncDivide(
    Valuable<num> operand1,
    Valuable<num> operand2,
  ) => _ValuableIntOperation(operand1, NumOperator.truncDivide, operand2);

  /// Modulo operation
  static ValuableNumOperation<num> modulo(
    Valuable<num> operand1,
    Valuable<num> operand2,
  ) => ValuableNumOperation._(operand1, NumOperator.modulo, operand2);

  /// Negate operation
  static ValuableNumOperation<num> negate(Valuable<num> operand1) =>
      ValuableNumOperation._(operand1, NumOperator.negate, null);

  @override
  Output getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? context = const ValuableContext(),
  ]) {
    return _compareWithOperator(context);
  }

  Output _compareWithOperator(ValuableContext? valuableContext) {
    num ope1 = watch(_operand1, valuableContext: valuableContext);
    num ope2 = _operator != NumOperator.negate
        ? watch(_operand2!, valuableContext: valuableContext)
        : 0;

    return switch (_operator) {
          NumOperator.sum => ope1 + ope2,
          NumOperator.modulo => ope1 % ope2,
          NumOperator.multiply => ope1 * ope2,
          NumOperator.substract => ope1 - ope2,
          NumOperator.negate => -ope1,
          _ => throw UnimplementedError(
            'Operator $_operator is not implemented for ValuableNumOperation<Output> with Output = $Output',
          ),
        }
        as Output;
  }
}

class _ValuableIntOperation extends ValuableNumOperation<int> {
  _ValuableIntOperation(
    super.operand1,
    super.operat,
    Valuable<num> super.operand2,
  ) : super._();

  @override
  int _compareWithOperator(ValuableContext? valuableContext) {
    int retour;
    num ope1 = watch(_operand1, valuableContext: valuableContext);
    num ope2 = _operator != NumOperator.negate
        ? watch(_operand2!, valuableContext: valuableContext)
        : 0;

    switch (_operator) {
      case NumOperator.truncDivide:
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
    super.operand1,
    super.operat,
    Valuable<num> super.operand2,
  ) : super._();

  @override
  double _compareWithOperator(ValuableContext? valuableContext) {
    double retour;
    num ope1 = watch(_operand1, valuableContext: valuableContext);
    num ope2 = _operator != NumOperator.negate
        ? watch(_operand2!, valuableContext: valuableContext)
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

/// Possible operations between [Valuable<String>]
enum StringOperator { concate }

/// Operations for String
class ValuableStringOperation extends Valuable<String> {
  final Valuable<String> _operand1;
  final Valuable<String> _operand2;
  final StringOperator _operator;

  ValuableStringOperation(this._operand1, this._operator, this._operand2)
    : super();

  /// Sum operation
  ValuableStringOperation.concate(
    Valuable<String> operand1,
    Valuable<String> operand2,
  ) : this(operand1, StringOperator.concate, operand2);

  @override
  String getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? context = const ValuableContext(),
  ]) {
    return _compareWithOperator(context);
  }

  String _compareWithOperator(ValuableContext? valuableContext) {
    String retour;
    String ope1 = watch(_operand1, valuableContext: valuableContext);
    String ope2 = watch(_operand2, valuableContext: valuableContext);

    switch (_operator) {
      case StringOperator.concate:
        retour = ope1 + ope2;
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
        (ValuableWatcher watch, {ValuableContext? valuableContext}) => value,
      );
}

class ValuableSwitch<Switch, Output> extends Valuable<Output> {
  final Valuable<Switch> testable;
  final List<ValuableCaseItem<Output>>? cases;
  final ValuableParentWatcher<Output> defaultCase;

  ValuableSwitch(this.testable, {required this.defaultCase, this.cases});

  ValuableSwitch.value(
    Valuable<Switch> testable, {
    required Output defaultValue,
    List<ValuableCaseItem<Output>>? cases,
  }) : this(
         testable,
         defaultCase:
             (ValuableWatcher watch, {ValuableContext? valuableContext}) =>
                 defaultValue,
         cases: cases,
       );

  @override
  Output getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? valuableContext = const ValuableContext(),
  ]) {
    bool test = false;
    late Output value;
    if (cases?.isNotEmpty ?? false) {
      Iterator<ValuableCaseItem<Output>>? iterator = cases?.iterator;
      while (iterator != null &&
          iterator.moveNext() &&
          (test =
              testable
                  .equals(iterator.current.caseValue)
                  .getValue(valuableContext) ==
              false)) {
        value = iterator.current.getValue(
          watch,
          valuableContext: valuableContext,
        );
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
  final ValuableParentWatcher<Output>? elseCase;

  ValuableIf(this.testable, this.thenCase, {this.elseCase});

  ValuableIf.value(
    Valuable<bool> testable,
    Output thenValue, {
    required Output elseValue,
  }) : this(
         testable,
         (ValuableWatcher watch, {ValuableContext? valuableContext}) =>
             thenValue,
         elseCase:
             (ValuableWatcher watch, {ValuableContext? valuableContext}) =>
                 elseValue,
       );

  @override
  Output getValueDefinition(
    bool reevaluatingNeeded, [
    ValuableContext? valuableContext = const ValuableContext(),
  ]) {
    bool test = false;
    late Output value;

    test = watch(testable);

    if (test) {
      value = thenCase(watch, valuableContext: valuableContext);
    } else if (elseCase != null) {
      value = elseCase!.call(watch, valuableContext: valuableContext);
    }

    return value;
  }
}
