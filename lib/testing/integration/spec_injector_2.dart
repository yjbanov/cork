library cork.generated.DoubleModuleEntrypoint;

import 'package:cork/cork.dart';
import 'package:cork/testing/integration/spec.dart'
    show Bar, Foo, FooExtensionModule;

class DoubleModuleEntrypointInjector implements Injector {
  Foo _foo;
  Bar _bar;
  get(_) {
    throw new UnsupportedError(
        'Generated injector does not support dynamic get.');
  }

  Foo getFoo() {
    if (_foo == null) {
      _foo = FooExtensionModule.getFoo();
    }
    return _foo;
  }

  Bar getBar() {
    if (_bar == null) {
      _bar = new Bar(getFoo());
    }
    return _bar;
  }
}
