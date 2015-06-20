library cork.testing.integration.library_spec;

import 'package:cork/cork.dart';

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
