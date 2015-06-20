library cork.src.generator.binding_generator;

import 'package:analyzer/analyzer.dart'
    show
        ClassDeclaration,
        ClassMember,
        ConstructorDeclaration,
        MethodDeclaration;
import 'package:analyzer/src/generated/element.dart' as analyzer;
import 'package:analysis/analysis.dart';
import 'package:cork/cork.dart';
import 'package:cork/src/generator/analyzed_binding.dart';
import 'package:dart_builder/dart_builder.dart';

/// A utility class that maintains a unique ID for every [Library] in a scope.
abstract class LocalImportScope {
  static const Noop = const _NoopLocalImportScope();

  /// Create an import scope using [anthology] as the backend.
  factory LocalImportScope(Anthology anthology) = _CountingLocalImportScope;

  String scopeAndResolve(analyzer.DartType type);
}

class _CountingLocalImportScope implements LocalImportScope {
  final Anthology _anthology;
  int _counter = 0;
  final _libraryId = new Expando<String>();

  _CountingLocalImportScope(this._anthology);

  @override
  String scopeAndResolve(analyzer.DartType type) {
    var library = _anthology.getLibraryOfType(type);
    var scope = _libraryId[library];
    if (scope == null) {
      _libraryId[library] = scope = 'import_${++_counter}';
    }
    return scope;
  }
}

class _NoopLocalImportScope implements LocalImportScope {
  const _NoopLocalImportScope();

  @override
  String scopeAndResolve(_) => null;
}

/// Returns a list of positional argument types for [method].
List<DartType> getPositionalArgumentTypes(
    MethodDeclaration method, {
    LocalImportScope scope: LocalImportScope.Noop}) {
  return method.parameters.parameterElements.map((el) {
    return new DartType(
        el.type.name,
        namespace: scope.scopeAndResolve(el.type));
  }).toList(growable: false);
}

/// Given a [clazz] annotated with `@Inject` find the default factory.
FactoryRef getConstructor(
    ClassDeclaration clazz, {
    String constructorName,
    LocalImportScope scope: LocalImportScope.Noop}) {
  final method = clazz.getConstructor(constructorName);
  assert(method != null);
  final typeRef = new DartType(
      clazz.element.displayName,
      namespace: scope.scopeAndResolve(clazz.element.type));
  return new _ConstructorFactoryRef(typeRef);
}

class _ConstructorFactoryRef extends FactoryRef {
  _ConstructorFactoryRef(DartType typeRef) : super(typeRef);

  @override
  InvokeMethod invoke([List<Source> positionalArguments = const []]) {
    return new InvokeMethod.constructor(
        typeRef,
        positionalArguments: positionalArguments);
  }
}

/// Returns a static factory [methodName] for [clazz]. Optionally asserts that
/// return type is of [assertReturnType].
FactoryRef getStaticFactory(
    ClassDeclaration clazz,
    String methodName, [
    DartType assertReturnType]) {
  final method = clazz.getMethod(methodName);
  assert(method != null);
  assert(method.isStatic);
  if (assertReturnType != null) {
    throw new UnimplementedError();
  }
  final typeRef = new DartType(clazz.element.displayName);
  return new _StaticMethodFactoryRef(typeRef, methodName);
}

class _StaticMethodFactoryRef extends FactoryRef {
  final String _methodName;

  _StaticMethodFactoryRef(DartType typeRef, this._methodName) : super(typeRef);

  @override
  InvokeMethod invoke([List<Source> positionalArguments = const []]) {
    return new InvokeMethod.static(
        typeRef,
        _methodName,
        positionalArguments: positionalArguments);
  }
}

/// Returns all [ClassMember]s that have the [Provide] annotation [forType].
List<ClassMember> getProviders(ClassDeclaration clazz, DartType forType) {
  final providers = <ClassMember> [];
  for (final method in clazz.members) {
    if (method is! ConstructorDeclaration && method is! MethodDeclaration) {
      continue;
    }
    for (final metadata in method.metadata) {
      // TODO: Improve this logic. Don't use hardcoded literal.
      if (metadata.element.displayName == 'Provider') {
        // TODO: Implement.
      }
    }
  }
  return providers;
}

/// Returns a provider tuple to instantiate [clazz]. If [module] is provided
/// and has a @Provide annotation available for the type, it is used as the
/// [Provider.factoryRef]. Else, if [clazz] has a @Provide annotation available
/// for the type, it is used. Else, uses the default constructor on [clazz].
ProviderRef getProvider(
    ClassDeclaration clazz, {
    LocalImportScope scope: LocalImportScope.Noop,
    DartType forType,
    ClassDeclaration module}) {
  FactoryRef factoryRef;
  ClassMember method;

  // 1. Look for a @Provide-r static method in the module.
  if (module != null) {
    final methods = getProviders(clazz, forType);
    if (methods.isNotEmpty) {
      assert(methods.length == 1);
      method = methods.first;
      factoryRef = getStaticFactory(clazz, method.element.displayName);
      return new ProviderRef(factoryRef, getPositionalArgumentTypes(method));
    }
  }

  // 2. Look for a @Provide-r constructor in the class.
  // If not found, use the default constructor.
  final methods = getProviders(clazz, forType);
  if (methods.isNotEmpty) {
    assert(methods.length == 1);
    method = methods.first;
  } else {
    method = clazz.getConstructor(null);
  }

  if (method is ConstructorDeclaration) {
    factoryRef = getConstructor(
        clazz,
        constructorName: method.element.displayName);
  } else {
    factoryRef = getStaticFactory(
        clazz,
        method.element.displayName,
        /*(method as MethodDeclaration).element.returnType*/ null);
  }

  return new ProviderRef(factoryRef, getPositionalArgumentTypes(method));
}
