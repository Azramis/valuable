import 'package:valuable/src/base.dart';

/// Base for an error thrown by a Valuable
sealed class ValuableError extends Error {
  final Valuable target;

  ValuableError(this.target) : super();
}

/// An error for a mismatch between a Valuable and an Object
final class UnmatchTypeValuableError extends ValuableError {
  final Type mismatchType;

  UnmatchTypeValuableError(super.target, this.mismatchType);
}
