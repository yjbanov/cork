library cork.src.analyzer.scope;

import 'package:analyzer/analyzer.dart' hide ImportDirective;
import 'package:analyzer/src/generated/element.dart' as analyzer;
import 'package:analysis/analysis.dart';
import 'package:cork/src/generator/analyzed_binding.dart';
import 'package:dart_builder/dart_builder.dart';

/// A set of utility methods mimicking those of the 'mirrors.dart'
/// implementation that instead relies on generating Dart source code using the
/// analysis and dart_builder packages.
class ScopedAnalyzerUtils {
  final Anthology _anthology;
  final Library _sourceLibrary;

  final _cachedDartTypes = <String, DartType> {};
  final _importCache = <String, int> {};
  final _importDirectives = new Set<ImportDirective>();

  int _importCounter = 1;

  /// Creates a utility class using an existing analysis [Anthology].
  ScopedAnalyzerUtils.fromAnthology(this._anthology, this._sourceLibrary);

  /// Returns a factory reference for creating a new [clazz].[constructorName].
  FactoryRef getConstructor(ClassDeclaration clazz, {String constructorName}) {
    // If a class doesn't actually specify a default constructor we should still
    // be able to access it.
    // TODO: Find a better way.
    if (constructorName == null) {
      return new _ConstructorFactoryRef(typeRef(clazz.element.type));
    }
    final method = clazz.getConstructor(constructorName);
    if (method == null) {
      throw new StateError('No constructor "$constructorName" defined.');
    } else {
      final dartType = typeRef(clazz.element.type);
      return new _ConstructorFactoryRef(dartType, constructorName);
    }
  }

  /// Returns a static factory [methodName] for [clazz].
  FactoryRef getStaticFactory(ClassDeclaration clazz, String methodName) {
    final method = clazz.getMethod(methodName);
    if (method == null) {
      throw new StateError('No method "$methodName" defined.');
    } else if (!method.isStatic) {
      throw new StateError('Method "$methodName" is not static.');
    } else {
      return new _StaticMethodFactoryRef(
          typeRef(method.returnType.type),
          methodName);
    }
  }

  /// Returns a list of positional argument types for [methodOrConstructor].
  List<DartType> getPositionalArgumentTypes(ClassMember methodOrConstructor) {
    if (methodOrConstructor == null) {
      throw new ArgumentError.notNull('methorOrConstructor');
    }
    List<analyzer.ParameterElement> parameters;
    if (methodOrConstructor is MethodDeclaration) {
      parameters = methodOrConstructor.parameters.parameterElements;
    } else if (methodOrConstructor is ConstructorDeclaration) {
      parameters = methodOrConstructor.parameters.parameterElements;
    } else {
      throw new ArgumentError.value(methodOrConstructor.runtimeType);
    }
    return parameters.map((el) => typeRef(el.type)).toList(growable: false);
  }

  /// Resolved imports.
  Iterable<ImportDirective> get imports => _importDirectives;

  /// Converts [staticType] into a generation-friendly [DartType].
  DartType typeRef(analyzer.DartType staticType) {
    // TODO: Rename DartType TypeRef.
    // TODO: Better deal with dart: core types.
    if (staticType.element.library.isDartCore) {
      return new DartType(staticType.displayName);
    }
    final typeSourceUri = staticType.element.library.source.toString();
    final cacheKey = '$typeSourceUri:${staticType.displayName}';
    var dartType = _cachedDartTypes[cacheKey];
    var counter = _importCache[typeSourceUri];
    if (counter == null) {
      counter = _importCache[typeSourceUri] = _importCounter++;
    }
    if (dartType == null) {
      var namespace = 'import_$counter';
      var importLib = _anthology.getLibraryOfType(staticType);
      var importDirective = new ImportDirective(importLib.uri, as: namespace);
      _importDirectives.add(importDirective);
      dartType = new DartType(
          staticType.displayName.split('<').first, // TODO: Remove hack
          namespace: namespace);
    }
    return dartType;
  }
}

class _ConstructorFactoryRef extends FactoryRef {
  final String _constructorName;

  _ConstructorFactoryRef(DartType typeRef, [this._constructorName])
      : super(typeRef);

  @override
  InvokeMethod invoke([List<Source> positionalArguments = const []]) {
    return new InvokeMethod.constructor(
        typeRef,
        constructorName: _constructorName,
        positionalArguments: positionalArguments);
  }
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
