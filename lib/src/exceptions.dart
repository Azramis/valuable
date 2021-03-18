/// For Valuable to have its own Exceptions
abstract class ValuableException implements Exception {}

/// For case of illegal use when using Valuable
class ValuableIllegalUseException extends ValuableException {}
