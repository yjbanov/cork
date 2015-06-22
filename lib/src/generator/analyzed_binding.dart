library cork.src.generated.analyzed_binding;

// Similar to cork.src.binding, but based off of static analysis, not mirrors.
// Uses dart_builder to define structures.

import 'package:dart_builder/dart_builder.dart';

/// A factory reference.
abstract class FactoryRef {
  /// The class that will be constructed.
  final TypeRef typeRef;

  FactoryRef(this.typeRef);

  /// Creates a function invoker, that when called, will create a new [typeRef].
  ///
  /// Optionally, define [positionalArguments].
  CallRef invoke([List<Source> positionalArguments = const []]);
}

/// A resolved factory function.
class ProviderRef {
  /// A factory reference that returns an instance of [FactoryRef.typeRef].
  final FactoryRef factoryRef;

  /// Dependencies required for [factory] to be executed (arguments).
  final List<TypeRef> dependencies;

  ProviderRef(this.factoryRef, [this.dependencies = const []]);
}

/// A resolved DI binding. When [tokenType] should be instantiated, then
/// [providerRef] should be used to create it.
class BindingRef {
  /// A resolved factory reference for [tokenType].
  final ProviderRef providerRef;

  /// The type to be created.
  final TypeRef tokenRef;

  BindingRef(this.tokenRef, this.providerRef);
}
