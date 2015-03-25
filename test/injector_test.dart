library cork.test.injector_test;

import 'package:cork/interface.dart';
import 'package:cork/src/binding.dart';

import 'package:guinness/guinness.dart';

class Foo {}

void main() {
  describe('Injector', () {
    it('works as intended', () {
      final injector = new Injector([
        new Binding(Foo, new Provider((_) => new Foo(), []))
      ]);
      expect(injector.get(Foo)).toBeAnInstanceOf(Foo);
    });
  });
}
