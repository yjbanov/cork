library cork.test.integration_test;

import 'package:cork/dynamic.dart';
import 'package:test/test.dart';

// Base class that is used.
@Inject()
class Foo {}

// Another implementation of the base class.
class FooImpl implements Foo {}

// Class that has a dependency.
@Inject()
class Bar {
  final Foo foo;

  const Bar(this.foo);
}

// Base module.
@Module(const [
  Foo,
  Bar
])
class FooModule {}

// Extension module.
@Module(const [
  Foo
])
class FooExtensionModule {
  @Provide(Foo)
  static Foo getFoo() => new FooImpl();
}

@Entrypoint(const [FooModule])
class SingleModuleEntrypoint {}

@Entrypoint(const [FooModule, FooExtensionModule])
class DoubleModuleEntrypoint {}

void main() {
  group('Integration of modules', () {
    Injector injector;
    Bar bar;

    test('based on a single module', () {
      injector = createInjector(SingleModuleEntrypoint);
      bar = injector.get(Bar);
      expect(bar.foo.runtimeType, Foo);
    });

    test('based on an overriding module', () {
      injector = createInjector(DoubleModuleEntrypoint);
      bar = injector.get(Bar);
      expect(bar.foo.runtimeType, FooImpl);
    });
  });
}
