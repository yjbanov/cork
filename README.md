# cork

[![Build Status](https://drone.io/github.com/matanlurey/cork/status.png)](https://drone.io/github.com/matanlurey/cork/latest)

Yet another dependency injection framework for Dart, built based on [Dagger](https://google.github.io/dagger/).

Example:

```dart
import 'package:cork/cork.dart';

// "Inject" means that something can be created by an Injector.
@Inject()
class Foo {}

class CustomFooImpl implements Foo {}

// "Module" is a collection of Inject-ables, and other Modules.
// It can also provide custom factory functions.
@Module(const [Foo])
class FooModule {
  // Instead of using the default factory for Foo, use this function.
  @Provide(Foo)
  static Foo getFoo() => new CustomFooImpl();
}
```

Cork is built with static analysis and tree-shaking in mind, but is currently only a __prototype__. There are three planned ways to use Cork in your application:

## Dynamic mode (using `dart:mirrors`)
Suitable for use in the Dart VM (e.g. server-side), or within Dartium only.

```dart
import 'package:cork/dynamic.dart';

// Assume same file as above.
import 'foo.dart';

void main() {
  var injector = createInjector(FooModule);
  var foo = injector.get(Foo);
  assert(foo.runtimeType == CustomFooImpl)
}
```

## Simple codegen mode (using hand-written bindings):

```dart
import 'package:cork/cork.dart';

// This is currently *not* recommended, and for experimental use only.
import 'package:cork/src/binding.dart';

import 'foo.dart';

void main() {
  var bindings = [
    new Binding(Foo, new Provider(() => new CustomFooImpl()))
  ];
  
  var injector = new Injector(bindings);
  var foo = injector.get(Foo);
  assert(foo.runtimeType == CustomFooImpl);
}
```

## Simple codegen mode (using the binding generator):

**Experimental**: Still in development.

```dart
final foo = Uri.parse('package:cork/testing/library/foo.dart');

// The dart file generated.
final result = await generator.generate(foo);
```

## Static mode:
Not yet implemented; a transformer generates a `$FooModuleInjector` class that would look like this:

```dart
import 'package:cork/cork.dart';

import 'foo.dart';

class $FooModuleInjector implements Injector {
  Foo _foo;
  
  @override
  get(Type type) => throw new UnsupportedError('Does not supported dynamic "get".');
  
  Foo getFoo() {
    if (_foo == null) {
      _foo = FooModule.getFoo();
    }
    return _foo;
  }
}
```
