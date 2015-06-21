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
If you want to use Cork today, without reflection. It's tedious, but works.

You define a single `Binding` for every `@Inject`-able, and pass both the token of what will be injected (i.e. `Foo`) and a `Provider`, which is a tuple between a factory-function for creating a `Foo` instance and the dependencies required to be injected to create one.

```dart
import 'package:cork/cork.dart';

import 'foo.dart';

void main() {
  var bindings = [
    new Binding(Foo, new Provider((_) => new CustomFooImpl(), const [])),
    new Binding(Bar, new Provider((args) => new Bar(args[0]), const [Foo]))
  ];
  
  var injector = new Injector(bindings);
  var foo = injector.get(Foo);
  assert(foo.runtimeType == CustomFooImpl);
}
```

## Simple codegen mode (using the binding generator):

**Experimental**: Still in development. Does not properly support the `@Module` or `@Entrypoint` annotation, and is not recommended for use in anything but an experiment.

Instead of hand-writing your `Binding`s, have Cork generate them by pointing at an entrypoint file and saving the output as your static bindings. For example:

```dart
var foo = Uri.parse('package:cork/testing/library/foo.dart');

// The dart file generated.
var generator = new StaticBindingGenerator();
var result = await generator.generate(foo);
// result.toSource() is a formatted file that looks like the code blob below.
```

```dart
final staticBindings = <import_1.Binding>[
  new import_1.Binding(import_2.Foo,
      new import_1.Provider((args) => new import_2.Foo(), const [])),
  new import_1.Binding(import_2.Bar, new import_1.Provider(
      (args) => new import_2.Bar(args[0]), const [import_2.Foo]))
];
```

You can then create a new static injector:

```dart
import 'your_static_bindings_file.dart';

var injector = new Injector(staticBindings);
var foo = injector.get(Foo);
assert(foo.runtimeType == CustomFooImpl);
```

## Static class mode:

**Experimental**: Still in development. Does not properly support the `@Module` or `@Entrypoint` annotation, and is not recommended for use in anything but an experiment.

It is easier to use the dynamic `Injector`, either with mirrors or with the binding generator, in most applications, because you are able to at runtime determine what to create a new instance of. However, there are performance penalities involved:

- dart2js will only be able to treeshake method bodies, at best, because you refer to every injectable class
- Factory functions are [megamorphic](http://mrale.ph/blog/2015/01/11/whats-up-with-monomorphism.html).

For scenarios where you are able to take full advantage of a completely typed and static injector, Cork will help generate a typed injector *specifically* for your application. For example:

Generates a class called `$GeneratedClass`:

```dart
var foo = Uri.parse('package:cork/testing/library/foo.dart');

// The dart file generated.
var generator = new StaticClassGenerator();
var result = await generator.generate(foo);
// result.toSource() is a formatted file that looks like the code blob below.
```

```dart
class $GeneratedInjector {
  import_2.Foo _1;
  import_2.Bar _2;
  import_2.Foo get1() {
    if (_1 == null) {
      _1 = new import_2.Foo();
    }
    return _1;
  }

  import_2.Bar get2(import_2.Foo a1) {
    if (_2 == null) {
      _2 = new import_2.Bar(a1);
    }
    return _2;
  }
}
```

It's possible to use this injector directly like any other class in your code:

```dart
var injector = new $GeneratedInjector();
var foo = injector.get1();
assert(foo.runtimeType == Foo);
```

Ultimately, Cork will also supply source generation helpers to rewrite parts of your application to take use of the statically defined methods. Something like below is planned - it will run using *mirrors* in development mode.

```dart
@Entrypoint()
class Foo {
  final Injector _injector;
  
  Foo(this._injector);
  
  Bar getBar() => _injector.get(Bar);
}

void main() {
  var injector = createInjector(Foo);
  injector.getFoo().getBar();
}
```

And in static mode will be rewritten:

```dart
class Foo {
  final $GeneratedInjector _injector;
  
  Foo(this._injector);
  
  Bar getBar() => _injector.get2();
}

void main() {
  var injector = new $GeneratedInjector();
  injector.get1().getBar();
}
```
