library cork.src.api.interfaces;

/// The result of a resolved object graph.
///
/// A dynamic injector or an injector with dynamic support will support the
/// [get] method, otherwise a completely static injector will throw an
/// [UnsupportedError]
abstract class Injector {
  /// Attempts to dynamically look up [token] and returns an instance according
  /// to a binding that was defined for it.
  ///
  /// If no binding was found, throws [NoProviderFoundError].
  ///
  /// If [supportsDynamicInjection] not set, throws [NoDynamicInjectionError].
  Object get(Object token);

  /// Whether [get] will not throw a [NoDynamicInjectionError].
  bool get supportsDynamicInjection;
}

/// A factory class that can [resolve] a module [T] into an [Injector].
abstract class ObjectGraph<T> {
  /// Creates a new injector from module [T], optionally as a child of [parent].
  ///
  /// If [verifyTree] is true, the graph will strictly make sure that all
  /// DI configuration is present and not attempt to make assumptions about
  /// missing annotations and the like.
  Injector resolve({Injector parent, bool verifyTree: true});
}
