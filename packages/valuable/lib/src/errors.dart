import 'package:valuable/src/base.dart';

/// Base for an error thrown by a Valuable
abstract class ValuableError extends Error {
  final Valuable target;

  ValuableError(this.target) : super();
}

/// An error for a mismatch between a Valuable and an Object
class UnmatchTypeValuableError extends ValuableError {
  final Type mismatchType;

  UnmatchTypeValuableError(Valuable target, this.mismatchType) : super(target);
}
