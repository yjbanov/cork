library cork.mirrors.object_graph;

@MirrorsUsed(metaTargets: const [Inject, Module, Provide])
import 'dart:mirrors';

import 'package:cork/src/api/annotations.dart';
import 'package:cork/src/api/errors.dart';
import 'package:cork/src/api/interfaces.dart';
import 'package:cork/src/mirrors/resolver.dart';
import 'package:cork/src/runtime/injector.dart';

/// Recursively resolve and add [type]'s bindings to [resolved].
void recursivelyResolve(
    Type type,
    List<RuntimeResolvedBinding> resolved,
    MirrorsResolver resolver) {
  final module = resolver.getModule(type);
  final providers = resolver.resolveProviders(reflectClass(type));
  module.bindings.forEach((binding) {
    resolved.add(resolver.resolveBinding(binding, providers));
  });
  module.includes.forEach((include) {
    recursivelyResolve(include, resolved, resolver);
  });
}

/// An implementation of the [ObjectGraph] API that uses runtime reflection
/// (i.e. mirrors) in order to traverse and resolve bindings.
///
/// It is advised *not* to use this in production due to the code size and
/// performance implications of using mirrors with dart2js.
///
/// __Example use__:
///     final injector = const MirrorsObjectGraph<FooModule>.resolve();
class MirrorsObjectGraph<T> implements ObjectGraph<T> {
  final MirrorsResolver _resolver;

  const MirrorsObjectGraph([this._resolver = const MirrorsResolver()]);

  /// Resolves the type [T] into an object graph, optionally with a [parent].
  ///
  /// Throws [InvalidTypeError] if [T] is not a class.
  /// Throws [NoAnnotationFoundError] if [T] is not annotated with @Module if
  /// [verifyTree] is enabled.
  Injector resolve({
      Injector parent: const NullInjector(),
      bool verifyTree: true}) {
    // Start a list of resolved bindings;
    final resolvedBindings = <RuntimeResolvedBinding> [];

    // Start resolving.
    recursivelyResolve(T, resolvedBindings, _resolver);

    // Verify.
    if (verifyTree) {
      final resolutionMap = new Map.fromIterable(
          resolvedBindings,
          key: (RuntimeResolvedBinding b) => b.token);
      for (final resolvedBinding in resolvedBindings) {
        for (final dependency in resolvedBinding.dependencies) {
          if (!resolutionMap.containsKey(dependency)) {
            throw new NoProviderFoundError(
                'Provider missing for "$dependency" on '
                '"${resolvedBinding.token}');
          }
        }
      }
    }

    return new RuntimeInjector(resolvedBindings);
  }
}
