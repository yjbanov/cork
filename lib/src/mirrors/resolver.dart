library cork.mirrors.resolver;

import 'dart:mirrors';

import 'package:cork/src/api/annotations.dart';
import 'package:cork/src/api/errors.dart';
import 'package:cork/src/runtime/injector.dart';
import 'package:cork/src/runtime/logger.dart';

// TODO: Consider moving into a more common place or library.
class MirrorUtils<T> {
  const MirrorUtils();

  /// Returns whether [mirror] is annotated with [T].
  bool hasAnnotation(DeclarationMirror mirror) {
    return getAnnotation(mirror) != null;
  }

  /// Utility method for getting the first [T] on [mirror].
  Object getAnnotation(DeclarationMirror mirror) {
    for (final metadata in mirror.metadata) {
      if (metadata.reflectee is T) {
        return metadata.reflectee;
      }
    }
    return null;
  }
}

// TODO: Refactor out a base RuntimeResolver.
class MirrorsResolver {
  final bool _safeMode;

  /// Create a new resolver, optionally with [enableSafetyChecks] or not.
  const MirrorsResolver({bool enableSafetyChecks: true})
      : _safeMode = enableSafetyChecks;

  /// Returns true if [classMirror] is annotated with `@Inject`.
  bool isInjectable(ClassMirror classMirror) {
    return const MirrorUtils<Inject>().hasAnnotation(classMirror);
  }

  /// Returns true if [declarationMirror] is annotated with `@Provide`.
  bool isProvider(DeclarationMirror declarationMirror) {
    return const MirrorUtils<Provide>().hasAnnotation(declarationMirror);
  }

  /// Returns a constructor method for [classMirror].
  MethodMirror getClassProvider(ClassMirror classMirror) {
    if (_safeMode && !isInjectable(classMirror)) {
      throw new NoAnnotationFoundError(Inject, classMirror.reflectedType);
    }
    MethodMirror providingMethod;
    classMirror.declarations.forEach((methodName, methodMirror) {
      if (methodMirror is MethodMirror &&
          methodMirror.isConstructor &&
          isProvider(methodMirror)) {
        if (providingMethod != null && _safeMode) {
          throw new InvalidConfigurationError(
              'Only one constructor on ${classMirror.reflectedType} '
              'should be annotated with `@Provide`.');
        }
        providingMethod = methodMirror;
      }
    });
    return providingMethod;
  }

  /// Returns [methodMirror]'s parameters as a list of types.
  List<Type> getParameterTypes(MethodMirror methodMirror) {
    return methodMirror.parameters
        .map((p) => p.type.reflectedType)
        .toList(growable: false);
  }

  /// Resolves [aliasBinding] into a [RuntimeResolvedBinding].
  RuntimeResolvedBinding resolveAlias(AliasBinding aliasBinding) {
    if (aliasBinding.toAlias == null) {
      throw new ArgumentError('toAlias must not be null.');
    }
    return new RuntimeResolvedBinding(
        aliasBinding.token,
        [aliasBinding.toAlias],
        (List resolvedDependencies) => resolvedDependencies[0]);
  }

  /// Resolves [classBinding] into a [RuntimeResolvedBinding].
  RuntimeResolvedBinding resolveClass(ClassBinding classBinding) {
    if (classBinding.toClass == null) {
      throw new ArgumentError('toClass must not be null.');
    }
    ClassMirror classMirror = reflectClass(classBinding.toClass);
    MethodMirror provider = getClassProvider(classMirror);
    if (provider == null) {
      throw new NoProviderFoundError(
          'Could not find a provider for '
          '${classBinding.token} on ${classBinding.toClass}');
    }
    return new RuntimeResolvedBinding(
        classBinding.token,
        getParameterTypes(provider),
        (List resolvedDependencies) =>
            classMirror
                .newInstance(provider.constructorName, resolvedDependencies)
                .reflectee);
  }

  /// Resolves [factoryBinding] into a [RuntimeResolvedBinding].
  RuntimeResolvedBinding resolveFactory(FactoryBinding factoryBinding) {
    if (factoryBinding.toFactory == null) {
      throw new ArgumentError('toFactory must not be null.');
    }
    var dependencies = factoryBinding.dependencies;
    if (dependencies == null) {
      final closureMirror = reflect(factoryBinding.toFactory) as ClosureMirror;
      dependencies = getParameterTypes(closureMirror.function);
    }
    return new RuntimeResolvedBinding(
        factoryBinding.token,
        dependencies,
        (List resolvedDependencies) =>
            Function.apply(factoryBinding.toFactory, resolvedDependencies));
  }

  /// Resolves [valueBinding] into a [RuntimeResolvedBinding].
  RuntimeResolvedBinding resolveValue(ValueBinding valueBinding) {
    return new RuntimeResolvedBinding(
        valueBinding.token,
        const [],
        (_) => valueBinding.toValue);
  }

  /// Resolves [binding] into a [RuntimeResolvedBinding].
  ///
  /// If the binding could not be resolved, falls back to checking
  /// [moduleProviders] before throwing [NoProviderFoundError].
  RuntimeResolvedBinding resolveBinding(
      Binding binding, [
      Map<Object,RuntimeResolvedBinding> moduleProviders = const {}]) {
    if (binding is AliasBinding) {
      return resolveAlias(binding);
    }
    if (binding is ClassBinding) {
      return resolveClass(binding);
    }
    if (binding is FactoryBinding) {
      return resolveFactory(binding);
    }
    if (binding is ValueBinding) {
      return resolveValue(binding);
    }
    var resolvedBinding = moduleProviders[binding.token];
    if (resolvedBinding == null && binding.token is Type) {
      resolvedBinding = resolveClass(
          new ClassBinding(binding.token, binding.token));
    }
    if (resolvedBinding == null) {
      throw new NoProviderFoundError('Could not find "${binding.token}".');
    }
    return resolvedBinding;
  }

  /// Returns an map of all [Provide] annotated methods within [clazz].
  Map<Object, RuntimeResolvedBinding> resolveProviders(ClassMirror clazz) {
    Object moduleInstance;
    final resolvedBindings = <Object, RuntimeResolvedBinding> {};
    clazz.instanceMembers.forEach((methodName, methodMirror) {
      Provide provide = const MirrorUtils<Provide>().getAnnotation(methodMirror);
      if (provide != null) {
        if (moduleInstance == null) {
          try {
            moduleInstance = clazz
                .newInstance(const Symbol(''), const [])
                .reflectee;
          } catch (e) {
            final className = MirrorSystem.getName(clazz.qualifiedName);
            throw new InvalidConfigurationError(
                'Could not create a new module instance of ${className}.\n'
                'Source: $e\n'
                'Cork expects a module with a @Provide annotation on a method to '
                'have a default constructor with no parameters.');
          }
        }

        // What will become RuntimeResolvedBinding.dependencies.
        final dependencies = methodMirror.parameters
            .map((p) => p.type.reflectedType)
            .toList(growable: false);

        // Create a factory.
        RuntimeResolvedFactory factory = (List resolvedDependencies) {
          return reflect(moduleInstance)
              .invoke(methodName, resolvedDependencies)
              .reflectee;
        };

        // Add to the bindings map.
        final token = provide.token != null
            ? provide.token
            : methodMirror.returnType.reflectedType;
        resolvedBindings[token] = new RuntimeResolvedBinding(
            token,
            dependencies,
            factory);
      }
    });
    return resolvedBindings;
  }

  /// Checks and returns a [Module] from [type]'s class definition.
  Module getModule(Type type) {
    final typeMirror = reflectType(type);
    if (typeMirror is! ClassMirror) {
      throw new InvalidTypeError('Expected a class, instead got: $typeMirror');
    }
    Module module = const MirrorUtils<Module>().getAnnotation(typeMirror);
    if (module == null) {
      final error = new NoAnnotationFoundError(Module, type);
      if (_safeMode) {
        throw error;
      } else {
        // Default to a blank module and log a warning.
        logger.warn('Did not find @Module annotation', error, getStackTrace());
        module = new Module();
      }
    } else {
      if (module.bindings.isEmpty && module.includes.isEmpty) {
        final error = new StateError('A module must have a binding or include');
        if (_safeMode) {
          throw error;
        } else {
          logger.warn('No bindings or incoudes found', error, getStackTrace());
        }
      }
    }
    return module;
  }
}
