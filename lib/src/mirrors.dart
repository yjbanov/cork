library cork.src.mirrors;

import 'dart:mirrors';

import 'package:cork/interface.dart';
import 'package:cork/src/binding.dart';

/// Saves a [Factory] instance.
final _factoryInstances = new Expando<Factory>('factoryInstances');

/// Returns a list of positional argument types for [mirror].
List<Type> getPositionalArgumentTypes(MethodMirror mirror) {
  return mirror.parameters
      .map((p) => p.type.reflectedType)
      .toList(growable: false);
}

/// Returns a constructor factory [constructorName] for [clazz].
Factory getConstructor(
    ClassMirror clazz,
    Symbol constructorName) {
  Symbol methodName;
  if (constructorName != const Symbol('')) {
    methodName = new Symbol(
        MirrorSystem.getName(clazz.simpleName) +
        '.' +
        MirrorSystem.getName(constructorName));
  }
  final MethodMirror mirror = clazz.declarations[methodName];
  assert(mirror != null);
  var factory = _factoryInstances[mirror];
  if (factory == null) {
    assert(mirror.isConstructor);
    factory = (List positionalArguments) {
      return clazz.newInstance(constructorName, positionalArguments).reflectee;
    };
    _factoryInstances[mirror] = factory;
  }
  return factory;
}

/// Returns a static factory [methodName] for [clazz]. Optionally, asserts
/// that the return type is of [assertReturnType];
Factory getStaticFactory(
    ClassMirror clazz,
    Symbol methodName, [
    Type assertReturnType]) {
  final MethodMirror mirror = clazz.declarations[methodName];
  assert(mirror != null);
  var factory = _factoryInstances[mirror];
  if (factory == null) {
    assert(mirror.isStatic);
    if (assertReturnType != null) {
      assert(mirror.returnType.reflectedType == assertReturnType);
    }
    factory = (List positionalArguments) {
      return clazz.invoke(methodName, positionalArguments).reflectee;
    };
    _factoryInstances[mirror] = factory;
  }
  return factory;
}

/// Returns all annotations of [type] on [mirror].
List getAnnotations(DeclarationMirror mirror, Type type) {
  final typeMirror = reflectType(type);
  final annotations = [];
  for (final annotation in mirror.metadata) {
    if (annotation.type.isSubtypeOf(typeMirror)) {
      annotations.add(annotation.reflectee);
    }
  }
  return annotations;
}

/// Returns the [Inject] annotation on [clazz], or null if there was none.
Inject getInjectable(ClassMirror clazz) {
  final injectables = getAnnotations(clazz, Inject);
  if (injectables.isEmpty) {
    return null;
  }
  assert(injectables.length == 1);
  return injectables.first;
}

/// Returns the [Module] annotation on [clazz], or null if there was none.
Module getModule(ClassMirror clazz) {
  final modules = getAnnotations(clazz, Module);
  if (modules.isEmpty) {
    return null;
  }
  assert(modules.length == 1);
  return modules.first;
}

/// Returns all [MethodMirror]s that have the [Provide] annotation [forType].
List<MethodMirror> getProviders(ClassMirror clazz, Type forType) {
  final providers = <MethodMirror> [];
  for (final method in clazz.declarations.values) {
    if (method is MethodMirror) {
      final List<Provide> annotations = getAnnotations(method, Provide);
      for (final provider in annotations) {
        if (provider.type == forType) {
          providers.add(method);
        }
      }
    }
  }
  return providers;
}

/// Returns a provider tuple to instantiate [clazz]. If [module] is provided
/// and has a @Provide annotation available for the type, it is used as the
/// [Provider.factory]. Else, if [clazz] has a @Provide annotation available
/// for the type, it is used. Else, uses the default constructor on [clazz].
Provider getProvider(ClassMirror clazz, Type forType, [ClassMirror module]) {
  Factory factory;
  MethodMirror mirror;

  // 1. Look for a @Provide-r static method in the module.
  if (module != null) {
    final mirrors = getProviders(module, clazz.reflectedType);
    if (mirrors.isNotEmpty) {
      assert(mirrors.length == 1);
      mirror = mirrors.first;
      factory = getStaticFactory(clazz, mirror.simpleName);
      return new Provider(factory, getPositionalArgumentTypes(mirror));
    }
  }

  // 2. Look for a @Provide-r constructor in the class.
  // If not found, use the default constructor.
  final mirrors = getProviders(clazz, forType);
  if (mirrors.isNotEmpty) {
    assert(mirrors.length == 1);
    mirror = mirrors.first;
  } else {
    // TODO: Is this the "default" constructor? Is there a better one?
    mirror = clazz.declarations[mirror.simpleName];
  }

  if (mirror.isConstructor) {
    factory = getConstructor(clazz, mirror.simpleName);
  } else {
    factory = getStaticFactory(
        clazz, mirror.simpleName, mirror.returnType.reflectedType);
  }
  return new Provider(factory, getPositionalArgumentTypes(mirror));
}

/// Returns resolved [Binding]s from [type], where [type] is annotated with a
/// [Module] annotation type.
Iterable<Binding> resolve(Type type) {
  final clazz = reflectClass(type);
  final module = getModule(clazz);
  if (module == null) {
    throw new ArgumentError('No @Module defined on "$type".');
  }
  final bindings = <Binding> [];
  for (final include in module.included) {
    final subClass = reflectClass(include);
    final subModule = getModule(subClass);
    if (subModule != null) {
      bindings.addAll(resolve(include));
    } else {
      assert(getInjectable(subClass) != null);
      final provider = getProvider(subClass, include, clazz);
      bindings.add(new Binding(include, provider));
    }
  }
  return bindings;
}
