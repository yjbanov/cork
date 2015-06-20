library cork.test.integration_test;

import 'package:cork/mirrors.dart';
import 'package:cork/testing/integration/library_spec.dart';
import 'package:test/test.dart';

void main() {
  group('Integration of modules', () {
    Injector injector;
    Bar bar;

    test('based on a single module', () {
      injector = createInjector(SingleModuleEntrypoint);
      bar = injector.get(Bar);
      expect(bar.foo, const isInstanceOf<Foo>());
    });

    test('based on an overriding module', () {
      injector = createInjector(DoubleModuleEntrypoint);
      bar = injector.get(Bar);
      expect(bar.foo, const isInstanceOf<FooImpl>());
    });
  });
}
