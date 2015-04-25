library cork.test.mirrors_test;

import 'dart:mirrors';

import 'package:cork/cork.dart';
import 'package:cork/src/mirrors.dart';

import 'package:guinness/guinness.dart';

@Inject()
class Foo {
  Foo.create() {}

  @Provide(Foo)
  static Foo staticFooFactory(String a1, DateTime a2) => new Foo.create();
}

@Module(const [Foo])
class FooModule {}

void main() {
  describe('Mirrors implementation of binding resolution', () {
    it('has getPositionalArgumentTypes working as intended', () {
      final method = reflectClass(Foo).declarations[#staticFooFactory];
      expect(getPositionalArgumentTypes(method)).toEqual([
        String,
        DateTime
      ]);
    });

    describe('has getConstructor', () {
      it('working as intended', () {
        final factory = getConstructor(reflectClass(Foo), #create);
        expect(factory(const [])).toBeAnInstanceOf(Foo);
      });

      it('returning the same instance every time', () {
        expect(getConstructor(reflectClass(Foo), #create))
            .toBe(getConstructor(reflectClass(Foo), #create));
      });
    });

    describe('has getStaticFactory', () {
      it('working as intended', () {
        final factory = getStaticFactory(reflectClass(Foo), #staticFooFactory);
        expect(factory(['', new DateTime.now()])).toBeAnInstanceOf(Foo);
      });

      it('returning the same instance every time', () {
        expect(getStaticFactory(reflectClass(Foo), #staticFooFactory))
            .toBe(getStaticFactory(reflectClass(Foo), #staticFooFactory));
      });
    });

    it('has getAnnotations working as intended', () {
      expect(getAnnotations(reflectClass(Foo), Inject)).toEqual([
        const Inject()
      ]);
      expect(getAnnotations(reflectClass(Foo), Module)).toEqual([]);
    });

    it('has getInjectable working as intended', () {
      expect(getInjectable(reflectClass(Foo))).toEqual(const Inject());
      expect(getInjectable(reflectClass(FooModule))).toBeNull();
    });

    it('has getModule working as intended', () {
      expect(getModule(reflectClass(FooModule)))
          .toEqual(const Module(const [Foo]));
      expect(getModule(reflectClass(Foo))).toBeNull();
    });

    it('getProviders works as intended', () {
      expect(getProviders(reflectClass(Foo), Foo).length).toEqual(1);
    });

    it('getProvider works as intended', () {
      final provider = getProvider(reflectClass(Foo), Foo);
      expect(provider.factory([null, null])).toBeAnInstanceOf(Foo);
    });

    it('resolve works as intended', () {
      final bindings = resolve(FooModule);
      expect(bindings.length).toEqual(1);
    });
  });
}
