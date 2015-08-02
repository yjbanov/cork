library cork.src.runtime.injector;

import 'package:cork/src/api/interfaces.dart';
import 'package:cork/src/api/errors.dart';

/// A resolved [Binding] at runtime.
class RuntimeResolvedBinding {
  /// Tokens of all dependencies, ordered, that are required to create [token].
  final List<Object> dependencies;

  /// A factory method, when called, creates an instance of [token].
  final RuntimeResolvedFactory factory;

  /// The injectable binding.
  final Object token;

  RuntimeResolvedBinding(this.token, this.dependencies, this.factory);
}

/// Returns a new instance of an object by satisfying [resolvedDependencies].
typedef Object RuntimeResolvedFactory(Iterable resolvedDependencies);

/// A default implementation of the [Injector] that throws
/// [NoProviderFoundError] whenever [get] is called.
class NullInjector implements Injector {
  const NullInjector();

  @override
  Object get(Object token) => throw new NoProviderFoundError(token.toString());

  @override
  final supportsDynamicInjection = true;
}

/// An implementation of [Injector] that is backed by a growable collection of
/// bindings that can be created at runtime versus strictly at compile time.
class RuntimeInjector implements Injector {
  final Injector _parent;
  final _objectInstances = <Object, Object> {};
  final Map<Object, RuntimeResolvedBinding> _resolvedBindings;

  RuntimeInjector(
      Iterable<RuntimeResolvedBinding> bindings, [
      this._parent = const NullInjector()])
          : _resolvedBindings = new Map<Object, RuntimeResolvedBinding>
                .fromIterable(bindings, key:
                    (RuntimeResolvedBinding b) => b.token);

  /// Returns a new child injector, using [bindings] as additional or overriding
  /// bindings over the parent.
  RuntimeInjector createChild(Iterable<RuntimeResolvedBinding> bindings) {
    return new RuntimeInjector(bindings, this);
  }

  @override
  Object get(Object token) {
    var instance = _objectInstances[token];
    if (instance == null) {
      final binding = _resolvedBindings[token];
      if (binding == null) {
        return _parent.get(token);
      }
      final resolvedDependencies = binding.dependencies
          .map(get)
          .toList(growable: false);
      instance = binding.factory(resolvedDependencies);
      _objectInstances[token] = instance;
    }
    return instance;
  }

  @override
  final supportsDynamicInjection = true;
}
