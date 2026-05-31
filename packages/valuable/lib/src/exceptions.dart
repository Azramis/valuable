part of 'base.dart';

/// For Valuable to have its own Exceptions
sealed class ValuableException implements Exception {
  const ValuableException();
}

/// For case of illegal use when using Valuable
final class ValuableIllegalUseException extends ValuableException {
  const ValuableIllegalUseException();
}

/// For case of trying to read a Valuable that is already disposed
final class ValuableDisposedException<T> extends ValuableException {
  ValuableDisposedException(this.valuable);
  final Valuable<T> valuable;
}
