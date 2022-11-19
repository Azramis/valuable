/// Allows compatibility between Flutter 2 and Flutter 3 for null-safety on WidgetBindings
/// and others
T? mitigate<T>(T? instance) => instance;
