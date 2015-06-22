library cork.src.binding.analyzer;

import 'dart:mirrors';

import 'package:analyzer/analyzer.dart' hide ImportDirective;
import 'package:analyzer/src/generated/element.dart' as analyzer;
import 'package:cork/cork.dart';
import 'package:cork/src/binding/static.dart';
import 'package:dart_builder/dart_builder.dart';

/// An interface for providing additional static analysis capabilities to
/// [StaticBindingAnalyzer]. Generic in order to be more easily pluggable and
/// testable.
abstract class StaticAnalysisProvider {
  /// Resolves [staticType] to the [Uri] containing it.
  Uri resolveStaticType(analyzer.DartType staticType);
}

/// A reference to [Module].
class ModuleRef {
  final List<ClassDeclaration> included;

  ModuleRef(this.included);
}

/// A set of utility methods mimicking those of the "mirrors.dart"
/// implementation that instead relies on generating Dart source code using the
/// analysis and dart_builder packages.
class StaticBindingAnalyzer {
  final _cachedDartTypeRefs = <String, TypeRef> {};
  final _importDirectives = new Set<ImportDirective>();
  final _libraryNamespaceId = <String, int> {};
  final StaticAnalysisProvider _provider;

  int _importCounter = 1;

  StaticBindingAnalyzer(this._provider);

  List<TypeRef> getPositionalArgumentTypes(ClassMember method) {
    List<FormalParameter> parameters;
    if (method is ConstructorDeclaration) {
      parameters = method.parameters.parameters;
    } else if (method is MethodDeclaration) {
      parameters = method.parameters.parameters;
    } else {
      throw new ArgumentError.value(method, 'method');
    }
    return parameters
        .map((p) => scopeType(p.element.type))
        .toList(growable: false);
  }

  /// Returns a constructor factory [constructorName] for [clazz].
  FactoryRef getConstructor(ClassDeclaration clazz, String constructorName) {
    return new FactoryRef.fromConstructor(
        scopeType(clazz.element.type),
        constructorName);
  }

  /// Returns a static factory ref [methodName] for [clazz].
  FactoryRef getStaticFactory(ClassDeclaration clazz, String methodName) {
    return new FactoryRef.fromStaticMethod(
        scopeType(clazz.element.type),
        methodName);
  }

  /// Returns all annotations of [type] on [node].
  List<Annotation> getAnnotations(AnnotatedNode node, Type type) {
    final typeMirror = reflectType(type);
    final annotations = <Annotation> [];
    for (final annotation in node.metadata) {
      // TODO: Replace with deep-type inspection.
      if (annotation.name.name == MirrorSystem.getName(typeMirror.simpleName)) {
        annotations.add(annotation);
      }
    }
    return annotations;
  }

  /// Returns true if [clazz] has the [Inject] annotation.
  bool hasInjectable(ClassDeclaration clazz) {
    // TODO: Use deep type inspection instead of this hack.
    final injectables = getAnnotations(clazz, Inject);
    final entryPoints = getAnnotations(clazz, Entrypoint);
    if (injectables.isEmpty && entryPoints.isEmpty) {
      return false;
    }
    assert(injectables.length + entryPoints.length == 1);
    return true;
  }

  ModuleRef getModuleRef(ClassDeclaration clazz) {
    // TODO: Use deep type inspection instead of this hack.
    final modules = getAnnotations(clazz, Module);
    final entryPoints = getAnnotations(clazz, Entrypoint);
    if (modules.isEmpty && entryPoints.isEmpty) {
      return null;
    }
    assert(modules.length + entryPoints.length == 1);
    throw new UnimplementedError();
  }

  /// Returns all [ClassMember]s that have the [Provide] annotation [forType].
  List<ClassMember> getProviders(
      ClassDeclaration clazz,
      analyzer.DartType forType) {
    final providers = <ClassMember> [];
    for (final member in clazz.members) {
      final annotations = getAnnotations(member, Provide);
      for (final provider in annotations) {
        if (provider.arguments.arguments.first.bestType == forType) {
          providers.add(member);
        }
      }
    }
    return providers;
  }

  /// Returns a provider tuple to create [clazz]. If [module] is provided and
  /// has a `@Provide` annotation available [forType], it is used as the
  /// factory. Else, if [clazz] has a `@Provide` annotation available [forType]
  /// it is used. Else, uses the default constructor on [clazz].
  ProviderRef getProvider(
      ClassDeclaration clazz,
      analyzer.DartType forType, [
      ClassDeclaration module]) {
    FactoryRef factoryRef;
    ClassMember member;

    // 1. Look for a @Provide-r static method in the module.
    if (module != null) {
      final providers = getProviders(module, clazz.element.type);
      if (providers.isNotEmpty) {
        assert(providers.isNotEmpty);
        member = providers.first;
        factoryRef = getStaticFactory(clazz, member.element.name);
        return new ProviderRef(factoryRef, getPositionalArgumentTypes(member));
      }
    }

    // 2. Look for a @Provide-r constructor in the class.
    // If not found, use the default constructor.
    final providers = getProviders(clazz, forType);
    if (providers.isNotEmpty) {
      assert(providers.length == 1);
      member = providers.first;
    } else {
      member = clazz.getConstructor('');
    }

    if (member is ConstructorDeclaration) {
      factoryRef = getConstructor(
          clazz,
          member != null ? member.element.name : '');
    } else {
      factoryRef = getStaticFactory(clazz, member.element.name);
    }
    return new ProviderRef(factoryRef, getPositionalArgumentTypes(member));
  }

  /// Returns resolved [BindingRef]s from [clazz], where [clazz] is annotated
  /// with a [Module] annotation type.
  Iterable<BindingRef> resolve(ClassDeclaration clazz) {
    final modules = getAnnotations(clazz, Module);

  }

  /// A collection of all import directives that were generated from scoping.
  Iterable<ImportDirective> get scopedImports => _importDirectives;

  /// Converts [staticDartType] into a generation-friendly [DartType].
  TypeRef scopeType(analyzer.DartType staticDartType) {
    // For dart:core types, just assume it is visible in the namespace for now.
    if (staticDartType.element.library.isDartCore) {
      return new TypeRef(staticDartType.displayName);
    }
    final typeSourceUri = staticDartType.element.library.source.toString();
    final cacheKey = '$typeSourceUri:${staticDartType.displayName}';
    var typeRef = _cachedDartTypeRefs[cacheKey];
    var counter = _libraryNamespaceId[typeSourceUri];
    if (counter == null) {
      counter = _libraryNamespaceId[typeSourceUri] = _importCounter++;
    }
    if (typeRef == null) {
      final namespace = 'import_$counter';
      final uri = _provider.resolveStaticType(staticDartType);
      final importDirective = new ImportDirective(uri, as: namespace);
      _importDirectives.add(importDirective);

      // TODO: Support generic types.
      typeRef = new TypeRef(
          staticDartType.displayName.split('<').first,
          namespace: namespace);
    }
    return typeRef;
  }
}
