library cork.src.api.errors;

/// An error that may be thrown when something was configured incorrectly.
class InvalidConfigurationError extends Error {
  final String message;

  InvalidConfigurationError(this.message) : super();

  @override
  String toString() => 'Invalid configuration: $message';
}

/// An error that may be thrown when the wrong [Type] is specified.
class InvalidTypeError extends TypeError {
  @override
  final String message;

  InvalidTypeError(this.message) : super();

  @override
  String toString() => 'Invalid type: $message';
}

/// An error that thrown when an annotation is expected but was not found.
///
/// The compiler and mirrors-runtime may optionally ignore omitted annotations
/// in some cases (and with safety checks disabled). Otherwise, this is thrown.
class NoAnnotationFoundError extends StateError {
  NoAnnotationFoundError(Type annotation, Object on)
      : super('Did not find annotation "$annotation" on "$on".');
}

/// An error that may be thrown by a resolved object graph (Injector) that does
/// not support runtime or dynamic injection, and expects all calls to the
/// injector to have been statically predetermined.
class NoDynamicInjectionError extends UnsupportedError {
  NoDynamicInjectionError() : super('Dynamic injection is not supported');
}

/// An error that may be thrown by the DI system when an attempt to inject
/// something fails due to no corresponding binding being available.
///
/// In practice, this error should only be found in either reflection mode or
/// with dynamic injectors, since a static object graph will throw provider
/// errors during compile time.
class NoProviderFoundError extends UnsupportedError {
  NoProviderFoundError(String message) : super(message);

  @override
  String toString() => 'No provider found for "$message".';
}
