library foo;

import 'package:cork/cork.dart';
import 'package:cork/testing/library/foo_imported.dart';

@Inject()
class Foo {
  // TODO: Remove the default constructor.
  Foo() {}

  Foo.create() {}

  @Provide(Foo)
  static Foo staticFooFactory(String a1, Bar a2) => new Foo.create();
}

@Module(const [Foo])
class FooModule {
  @Provide(Bar)
  static Bar staticBarFactory() => new Bar();
}
