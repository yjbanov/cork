library cork.src.binding.runtime;

import 'package:collection/equality.dart' show IterableEquality;

/// A factory function.
typedef T Factory<T>(List positionalArguments);

/// A resolved factory function for a type of [T].
class Provider<T> {
  /// A factory function that returns an instance of [T].
  final Factory factory;

  /// Dependencies required for [factory] to be executed (arguments).
  final List<Type> dependencies;

  const Provider(this.factory, [this.dependencies = const []]);

  @override
  bool operator==(Provider<T> other) {
    return
      identical(this, other) ||
      factory == other.factory &&
      const IterableEquality().equals(dependencies, other.dependencies);
  }
}

/// A resolved DI binding. When [token] should be instantiated, then [provider]
/// should be used to create it.
class Binding<T> {
  /// Provider tuple for [T].
  final Provider<T> provider;

  /// The type of [T].
  final Type token;

  const Binding(this.token, this.provider);

  @override
  bool operator==(Binding<T> other) {
    return
      identical(this, other) ||
      token == other.token &&
      provider == other.provider;
  }

  @override
  String toString() => 'Binding ' + {
    'token': token,
    'provider': 'Provider ' + provider.dependencies.toString()
  }.toString();
}
