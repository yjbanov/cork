library cork.test.injector_test;

import 'package:cork/cork.dart';
import 'package:cork/src/binding.dart';

import 'package:test/test.dart';

class Foo {}

void main() {
  group('Injector', () {
    test('works as intended', () {
      final injector = new Injector([
        new Binding(Foo, new Provider((_) => new Foo(), []))
      ]);
      expect(injector.get(Foo), const isInstanceOf<Foo>());
    });
  });
}
