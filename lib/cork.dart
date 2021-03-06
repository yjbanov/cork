/// Import this library in order to get the abstract classes and annotations for
/// the library. Useful to use another implementation without depending on any
/// implementation code within.
library cork.interface;

import 'package:cork/src/binding/runtime.dart';

/// Annotation for denoting a class that can be injected within a [Component].
/// An injectable type can also override so that child dependencies inject
/// itself instead of the app-level injectable. Example usage:
///     @Inject()
///     class FooImpl implements Foo {}
///       @Provide(Foo)
///       static Foo getFoo(FooImpl self) => self;
///     }
class Inject {
  const Inject();
}

/// Annotation for denoting a class that includes [Inject]able classes and other
/// defined [Module] annotated classes. Example usage:
///     @Module(const [
///       CoffeeBeanStorage // A class annotated with @Inject.
///       CoffeePumpModule, // A class annotated with @Module.
///       Heater            // A third party class which uses @Provide below.
///     ])
///     class CoffeeMakerModule {
///       @Provide(Heater)
///       static Heater getHeater() => return new ThirdPartyHeater();
///     }
class Module {
  /// A collection of injectable [Type]s annotated with `@Inject` (or with a
  /// @Provide method in this module or in an imported module) or `@Module`.
  final List<Type> included;

  const Module(this.included);
}

/// An alternative for 3rd party classes that cannot be annotated with [Inject].
/// A [Module] can define custom provider functions, or have one automatically
/// generated. Example usage:
///
///   // Uses an user-defined factory.
///   @Module(const [Heater])
///   class CoffeeMakerModule {
///     @Provide(Heater, const [Fire])
///     static Heater getHeater(Fire fire) => return new ThirdPartyHeater(fire);
///   }
///
///   // Uses an automatically generated factory.
///   @Module(const [Heater])
///   @Provide(Heater)
///   class CoffeeMakerModule {}
class Provide {
  /// What types should be injected.
  final List<Type> inject;

  /// The dart [Type] that is provided by the annotated method.
  ///
  /// If not specified, it is considered to be the parent class.
  final Type type;

  const Provide([this.type, this.inject = const []]);
}

/// A type of [Module] that should have a factory created for it in order to
/// create an injector. Example usage:
///
///   @Entrypoint(const [CoffeeMakerModule])
///   class CoffeeApplication() {
///     // This will be automatically instantiated by the injector.
///     CoffeeApplication(CoffeeMaker coffeeMaker) {}
///   }
///
/// Unlike module, [Entrypoint] also registers itself as a (root) injectable.
class Entrypoint extends Module implements Inject {
  const Entrypoint(List<Type> included) : super(included);
}

/// An injector interface. Not ideal for tree-shakeable injectors, but generic
/// enough to be used anywhere without a transformer.
abstract class Injector {
  /// A default injector that always throws.
  static const Null = const _NullInjector();

  /// Create a new injector from resolved [bindings].
  ///
  /// If a provider is not found for a type, tries [parent].
  factory Injector(Iterable<Binding> bindings, [Injector parent = Null]) {
    return new _BindingInjector(new Map<Type, Provider>.fromIterable(bindings,
        key: (Binding b) => b.token,
        value: (Binding b) => b.provider),
        parent);
  }

  /// Returns an instance of [type].
  Object get(Type type);
}

class _NullInjector implements Injector {
  const _NullInjector();

  @override
  Object get(Type type) {
    throw new StateError('No provider found for "$type".');
  }
}

/// A simple implementation of [Injector] using [Binding]s.
class _BindingInjector implements Injector {
  final Injector _parent;
  final Map<Type, Provider> _providers;

  const _BindingInjector(this._providers, this._parent);

  @override
  Object get(Type type) {
    final provider = _providers[type];
    if (provider == null) {
      return _parent.get(type);
    }
    final arguments = provider.dependencies.map(get).toList(growable: false);
    return provider.factory(arguments);
  }
}
