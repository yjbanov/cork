library cork.src.binding.analyzer;

import 'dart:mirrors';

import 'package:analysis/analysis.dart';
import 'package:analyzer/analyzer.dart' hide ImportDirective;
import 'package:analyzer/src/generated/element.dart' as analyzer;
import 'package:cork/cork.dart';
import 'package:cork/src/binding/static.dart';
import 'package:dart_builder/dart_builder.dart';

/// An interface for providing additional static analysis capabilities to
/// [StaticBindingAnalyzer]. Generic in order to be more easily pluggable and
/// testable.
abstract class StaticAnalysisProvider {
  /// Resolves [staticType] to the [Library] containing it.
  Library findStaticType(analyzer.DartType staticType);

  /// Resolves [staticType] to the [Uri] containing it.
  Uri resolveStaticType(analyzer.DartType staticType);
}

/// Implementation of [StaticAnalysisProvider] that uses an [Anthology].
class AnthologyAnalysisProvider implements StaticAnalysisProvider {
  final Anthology _anthology;

  AnthologyAnalysisProvider(this._anthology);

  @override
  Library findStaticType(analyzer.DartType dartType) {
    return _anthology.getLibraryOfType(dartType);
  }

  @override
  Uri resolveStaticType(analyzer.DartType dartType) {
    return findStaticType(dartType).uri;
  }
}

/// A reference to [Module].
class ModuleRef {
  final List<ClassDeclaration> included;

  ModuleRef(this.included);
}

/// How to, if at all, scope types and imports to avoid conflicts.
abstract class NamespaceStrategy {
  /// Creates an implementation that automatically prefixes all imports.
  factory NamespaceStrategy() = _ScopedNamespaceStrategy;

  /// Creates an implementation that does nothing.
  const factory NamespaceStrategy.noop() = _NoopNamespaceStrategy;

  /// Hashes [uniqueValue] to an incremented value.
  int getUniqueId(String source);

  /// Returns the namespace for [identifier], or null if it should not be.
  TypeRef namespace(String source, String identifier);
}

/// A no-op implementation that is suitable for tests.
class _NoopNamespaceStrategy implements NamespaceStrategy {
  const _NoopNamespaceStrategy();

  @override
  int getUniqueId(_) => 0;

  @override
  TypeRef namespace(_, String identifier) {
    return new TypeRef(identifier.split('<').first);
  }
}

/// A scoped implementation.
class _ScopedNamespaceStrategy implements NamespaceStrategy {
  final _cachedDartTypeRefs = <String, TypeRef> {};
  final _libraryNamespaceId = <String, int> {};

  int _importCounter = 1;

  @override
  int getUniqueId(String source) {
    var uniqueId = _libraryNamespaceId[source];
    if (uniqueId == null) {
      uniqueId = _libraryNamespaceId[source] = _importCounter++;
    }
    return uniqueId;
  }

  @override
  TypeRef namespace(String source, String identifier) {
    identifier = identifier.split('<').first;
    var cacheKey = '$source:$identifier';
    var typeRef = _cachedDartTypeRefs[cacheKey];
    if (typeRef == null) {
      var id = getUniqueId(source);
      typeRef = new TypeRef(identifier, namespace: 'import_$id');
    }
    return typeRef;
  }
}

/// A set of utility methods mimicking those of the "mirrors.dart"
/// implementation that instead relies on generating Dart source code using the
/// analysis and dart_builder packages.
class StaticBindingAnalyzer {
  final _importDirectives = <Uri, List<String>> {};
  final NamespaceStrategy _namespaceStrategy;
  final StaticAnalysisProvider _provider;

  StaticBindingAnalyzer(
      this._provider, [
      this._namespaceStrategy = const NamespaceStrategy.noop()]);

  /// Returns all of the types necessary to call [method].
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

  /// Returns an analyzed [Module] annotation on [clazz], or null if none.
  ModuleRef getModuleRef(ClassDeclaration clazz) {
    // TODO: Use deep type inspection instead of this hack.
    final modules = getAnnotations(clazz, Module);
    final entryPoints = getAnnotations(clazz, Entrypoint);
    if (modules.isEmpty && entryPoints.isEmpty) {
      return null;
    }
    assert(modules.length + entryPoints.length == 1);
    Annotation a = modules.isNotEmpty ? modules.first : entryPoints.first;

    Expression list = a.arguments.arguments.first;
    Iterable<analyzer.ClassElementImpl> classElements = list.childEntities
        .where((e) => e is SimpleIdentifier)
        .map((SimpleIdentifier e) =>
            (e.staticElement as analyzer.ClassElementImpl));

    final included = classElements.map((clazzEl) {
      return clazzEl.node;
    }).toList(growable: false);

    return new ModuleRef(included);
  }

  /// Returns all [ClassMember]s that have the [Provide] annotation [forType].
  List<ClassMember> getProviders(
      ClassDeclaration clazz,
      analyzer.DartType forType) {
    final providers = <ClassMember> [];
    for (final member in clazz.members) {
      final annotations = getAnnotations(member, Provide);
      for (final provider in annotations) {
        SimpleIdentifier item = provider.arguments.arguments.first;
        final dartType = (item.staticElement as analyzer.ClassElementImpl).type;
        if (dartType == forType) {
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
        factoryRef = getStaticFactory(module, member.element.name);
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
      member = clazz.getConstructor(null);
    }

    List<TypeRef> dependencies = const [];

    if (member == null) {
      factoryRef = getConstructor(clazz, '');
    } else if (member is ConstructorDeclaration) {
      factoryRef = getConstructor(clazz, member.element.name);
      dependencies = getPositionalArgumentTypes(member);
    } else {
      factoryRef = getStaticFactory(clazz, member.element.name);
      dependencies = getPositionalArgumentTypes(member);
    }

    return new ProviderRef(factoryRef, dependencies);
  }

  /// Returns resolved [BindingRef]s from [clazz], where [clazz] is annotated
  /// with a [Module] annotation type.
  Iterable<BindingRef> resolve(ClassDeclaration clazz) {
    final moduleRef = getModuleRef(clazz);
    if (moduleRef == null) {
      throw new ArgumentError('No @Module defined on "$clazz".');
    }
    final bindingRefs = <BindingRef> [];
    for (final include in moduleRef.included) {
      final subModule = getModuleRef(include);
      if (subModule != null) {
        bindingRefs.addAll(resolve(include));
      } else {
        assert(hasInjectable(include));
        final provider = getProvider(include, include.element.type, clazz);
        final tokenTypeRef = scopeType(include.element.type);
        bindingRefs.add(new BindingRef(tokenTypeRef, provider));
      }
    }
    return bindingRefs;
  }

  /// A collection of all import directives that were generated from scoping.
  Iterable<ImportDirective> calculateImports() {
    var directives = <ImportDirective> [];
    _importDirectives.forEach((uri, visible) {
      directives.add(new ImportDirective(
          uri,
          show: visible.toSet().toList(growable: false)..sort()));
    });
    return directives;
  }

  /// Converts [staticDartType] into a generation-friendly [DartType].
  TypeRef scopeType(analyzer.DartType staticDartType) {
    // For dart:core types, just assume it is visible in the namespace for now.
    if (staticDartType.element.library.isDartCore) {
      return new TypeRef(staticDartType.displayName);
    }
    final typeSourceUri = staticDartType.element.library.source.toString();
    final typeRef = _namespaceStrategy.namespace(
        typeSourceUri,
        staticDartType.displayName);
    final sourceUri = _provider.resolveStaticType(staticDartType);
    var showIdentifiers = _importDirectives[sourceUri];
    if (showIdentifiers == null) {
      showIdentifiers = _importDirectives[sourceUri] = <String> [];
    }
    showIdentifiers.add(staticDartType.displayName.split('<').first);
    return typeRef;
  }
}
