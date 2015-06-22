library cork.test.binding_integration_test;

import 'package:cork/cork.dart';
import 'package:cork/src/binding/runtime.dart';
import 'package:test/test.dart';

class Foo {}

void main() {
  group('Injector', () {
    test('works when created from provided bindings', () {
      final injector = new Injector([
        new Binding(Foo, new Provider((_) => new Foo(), []))
      ]);
      expect(injector.get(Foo), const isInstanceOf<Foo>());
    });

    test('throws when a binding is missing', () {
      final injector = new Injector(const []);
      expect(() => injector.get(Foo), throwsStateError);
    });

    test('uses the parent injector if a binding is missing', () {
      final parent = new Injector([
        new Binding(Foo, new Provider((_) => new Foo(), []))
      ]);
      final injector = new Injector(const [], parent);
      expect(injector.get(Foo), const isInstanceOf<Foo>());
    });
  });
}
