/// For Valuable to have its own Exceptions
sealed class ValuableException implements Exception {}

/// For case of illegal use when using Valuable
final class ValuableIllegalUseException extends ValuableException {}
