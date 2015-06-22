library cork.src.binding.analysis;

import 'package:dart_builder/dart_builder.dart';

/// A factory function reference.
class FactoryRef {
  final TypeRef classTypeRef;
  final bool isConstructor;
  final String methodName;

  /// Creates a new factory from a constructor on [classTypeRef].
  factory FactoryRef.fromConstructor(
      TypeRef classTypeRef, [
      String constructorName]) {
    return new FactoryRef._(classTypeRef, true, constructorName);
  }

  /// Creates a new factory from a static method on [classTypeRef].
  factory FactoryRef.fromStaticMethod(
      TypeRef classTypeRef,
      String methodName) {
    return new FactoryRef._(classTypeRef, false, methodName);
  }

  FactoryRef._(
      this.classTypeRef, [
      this.isConstructor = false,
      this.methodName = '']);

  /// When invoking the factory with [positionalArguments], return call site.
  CallRef invoke(List positionalArguments) {
    if (isConstructor) {
      return new CallRef.constructor(
          classTypeRef,
          constructorName: methodName,
          positionalArguments: positionalArguments);
    } else {
      return new CallRef.static(
          classTypeRef,
          methodName,
          positionalArguments: positionalArguments);
    }
  }
}

/// A resolved factory function for a type of [T].
class ProviderRef {
  /// A factory function that returns an instance of [factoryRef.classTypeRef].
  final FactoryRef factoryRef;

  /// Dependencies required for [factory] to be executed (arguments).
  final List<TypeRef> dependencies;

  ProviderRef(this.factoryRef, [this.dependencies = const []]);

  @override
  String toString() => 'ProviderRef ' + {
    'factoryRef': factoryRef.invoke([]).toSource(),
    'dependencies': dependencies.map((d) => d.toSource())
  }.toString();
}

/// A resolved DI binding. When [token] should be instantiated, then
/// [providerRef] should be used to create it.
class BindingRef {
  /// Provider tuple for [token].
  final ProviderRef providerRef;

  /// The type to be injected.
  final TypeRef tokenRef;

  BindingRef(this.tokenRef, this.providerRef);

  @override
  String toString() => 'BindingRef ' + {
    'token': tokenRef.toSource(),
    'provider': providerRef.toString()
  }.toString();
}
