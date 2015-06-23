# cork

[![Build Status](https://drone.io/github.com/matanlurey/cork/status.png)](https://drone.io/github.com/matanlurey/cork/latest)

A **fast** dependency injection framework and codegen engine for Dart.

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

Cork is built with static analysis and tree-shaking in mind. As such, unlike [package:di](https://pub.dartlang.org/packages/di), all bindings are declared via Dart [metadata annotations](https://www.dartlang.org/docs/dart-up-and-running/ch02.html#metadata).

It is possible to run Cork with either _runtime_ or _compile-time_ analysis, depending on your target platform, and even mix and match (i.e. use runtime reflection for development, and compile-time for production).

## Running Cork

### Reflective mode (using `dart:mirrors`)
Suitable for use in the Dart VM (e.g. server-side), or within Dartium for develpopment only.

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

### Static mode
Disable reflection and use Cork in a production/static mode by analyzing your app and generating bindings.

**NOTE**: This is still experimental.

There are a few strategies:

#### Dynamic mode

To maintain API compatibility, it is possible to manually create an `Injector` with generated bindings:

```dart
import 'package:cork/cork.dart';

import 'foo.dart';
import 'foo_generated.dart' as generated;

void main() {
  var injector = new Injector(generated.bindingsForFooModule);
  var foo = injector.get(Foo);
  assert(foo.runtimeType == CustomFooImpl)
}
```

##### Background

The reflective mode of Cork uses mirrors to generate `Binding` objects:

```dart
abstract class Binding {
  /// Provider tuple for [T].
  final Provider<T> provider;

  /// The type of [T].
  final Type token;
}
```

Simply put, a `Binding` is a tuple between a `Provider` (factory) and a `Type` (token).

##### Generating bindings

The Cork binding generator can analyze an `@Entrypoint`, and generate a full list of bindings:

```dart
var foo = Uri.parse('package:cork/testing/integration/spec.dart');

// The dart file generated.
var generator = new BindingGenerator(anthology);
var result = await generator.generate(uri, 'SingleModuleEntrypoint');
// result.toSource() is a formatted file that looks like the code blob below.
```

```dart
final bindingsForSingleModuleEntrypoint = <import_2.Binding>[
  new import_2.Binding(import_1.Foo,
      new import_2.Provider((args) => new import_1.Foo(), const [])),
  new import_2.Binding(import_1.Bar, new import_2.Provider(
      (args) => new import_1.Bar(args[0]), const [import_1.Foo]))
];
```

**NOTE**: A transformer will be available in an upcoming version. Right now it requires manual work.

#### Static mode:


It is easier to use the dynamic `Injector`, either with mirrors or with the binding generator, in most applications, because you are able to at runtime determine what to create a new instance of. However, there are performance penalities involved:

- dart2js will only be able to treeshake method bodies, at best, because you refer to every injectable class
- Factory functions are [megamorphic](http://mrale.ph/blog/2015/01/11/whats-up-with-monomorphism.html).

For scenarios where you are able to take full advantage of a completely typed and static injector, Cork will help generate a typed injector *specifically* for your application. For example:

Generates a class called `SingleModuleEntrypointInjector`:

```dart
var foo = Uri.parse('package:cork/testing/integration/spec.dart');

// The dart file generated.
var generator = new ClassGenerator(anthology);
var result = await generator.generate(uri, 'SingleModuleEntrypoint');
// result.toSource() is a formatted file that looks like the code blob below.
```

```dart
class SingleModuleEntrypointInjector {
  import_1.Foo _1;
  import_1.Bar _2;
  import_1.Foo get1() {
    if (_1 == null) {
      _1 = new import_1.Foo();
    }
    return _1;
  }

  import_1.Bar get2() {
    if (_2 == null) {
      _2 = new import_1.Bar(get1());
    }
    return _2;
  }
}
```

It's possible to use this injector directly like any other class in your code:

```dart
var injector = new SingleModuleEntrypointInjector();
var foo = injector.get1();
assert(foo.runtimeType == Foo);
```

## Future plans

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

There are also adapters planned to use Cork in Angular 1.0 and Angular 2.0 applications.
