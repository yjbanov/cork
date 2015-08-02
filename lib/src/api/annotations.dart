library cork.src.api.annotations;

/// An annotation for either a class to mark the class as injectable.
///
/// A class without an `@Inject` annotation will not be included in the object
/// graph, and may fail with a [NoProviderFound] error in reflective mode if
/// running in checked mode.
///
/// __Example use:__
///     @Inject()
///     class Foo {}
///
/// For classes with multiple constructors, use [Provide] to specify which
/// constructor should be used for injection.
///
/// __Example use:__
///     @Inject()
///     class Foo {
///       Foo.con1();
///
///       @Provide()
///       Foo.con2();
///     }
class Inject {
  const Inject();
}

/// Marks [token] as valid for injection within the object graph.
class Binding {
  /// The token that should be valid for injection.
  final Object token;

  const Binding(this.token);

  /// Use [toAlias] as the token when resolving [token].
  const factory Binding.toAlias(Object token, Object toAlias) = AliasBinding;

  /// Creates a new instance of [toClass] to resolve [token].
  const factory Binding.toClass(Object token, Type toClass) = ClassBinding;

  /// Calls [toFactory] to resolve [token].
  ///
  /// If [dependencies] is set, uses instead of the factories parameters.
  const factory Binding.toFactory(
      Object token,
      Function toFactory, {
      List<Object> dependencies}) = FactoryBinding;

  /// Uses [toValue] as the resolved value of [token].
  const factory Binding.toValue(Object token, Object toValue) = ValueBinding;
}

/// Uses the provider for [toAlias] instead of [token].
class AliasBinding extends Binding {
  /// An alternative [token].
  final Object toAlias;

  const AliasBinding(Object token, this.toAlias) : super(token);
}

/// Uses the provider for [toClass] to instantiate a [token].
class ClassBinding extends Binding {
  /// The class that should be created to resolve [token].
  final Type toClass;

  const ClassBinding(Object token, this.toClass) : super(token);
}

/// Uses [toFactory] to instantiate [token].
class FactoryBinding extends Binding {
  /// Dependencies needed to call [toFactory].
  ///
  /// If not specified, the types of [toFactory]'s parameters should be
  /// considered the default dependencies;
  final List<Object> dependencies;

  /// The function that should be called to resolved [token].
  ///
  /// The positional arguments are considered dependencies to be resolved.
  final Function toFactory;

  const FactoryBinding(
      Object token,
      this.toFactory, {
      this.dependencies})
          : super(token);
}

/// Uses [toValue] as the value for [token].
class ValueBinding extends Binding {
  /// The value for a resolved [token].
  final Object toValue;

  const ValueBinding(Object token, this.toValue) : super(token);
}

/// An annotation for a method that returns an instance of [token] if specified,
/// otherwise falls back to the return type of the method.
///
/// __Example use:__
///     var gasStation = new GasStation();
///
///     class CarModule {
///       @Provide(Fuel)
///       Fuel getFuel() => gasStation.pump();
///     }
class Provide {
  final Object token;

  const Provide([this.token]);
}

/// An annotation for a class to mark the class a module of [Binding]s.
///
/// A module with every dependency satisfied in the object graph can be
/// considered to be an entrypoint, while a module with any dependencies missing
/// must be included with other modules.
///
/// __Example use:__
///     @Module(
///       bindings: const [
///         const Binding(Car)
///       ],
///       include: const [DriverModule, FuelingModule]
///     )
///     class CarModule {}
///
/// A module with no bindings or includes will fail at compile time.
class Module {
  /// A collection of bindings the module has specified.
  ///
  /// Modules may specify custom providers for a binding by adding the [Provide]
  /// annotation to an instance method on the module.
  final List<Binding> bindings;

  /// Other modules that are included in this module.
  ///
  /// Any [Type] not annotated with `@Module` will fail with a [TypeError].
  final List<Type> includes;

  const Module({this.bindings: const [], this.includes: const []});
}
