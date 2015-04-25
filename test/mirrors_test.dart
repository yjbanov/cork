library cork.test.mirrors_test;

import 'dart:mirrors';

import 'package:cork/cork.dart';
import 'package:cork/src/mirrors.dart';

import 'package:test/test.dart';

@Inject()
class Foo {
  Foo.create() {}

  @Provide(Foo)
  static Foo staticFooFactory(String a1, DateTime a2) => new Foo.create();
}

@Module(const [Foo])
class FooModule {}

void main() {
  group('Mirrors implementation of binding resolution', () {
    test('has getPositionalArgumentTypes working as intended', () {
      final method = reflectClass(Foo).declarations[#staticFooFactory];
      expect(getPositionalArgumentTypes(method), [
        String,
        DateTime
      ]);
    });

    group('has getConstructor', () {
      test('working as intended', () {
        final factory = getConstructor(reflectClass(Foo), #create);
        expect(factory(const []), const isInstanceOf<Foo>());
      });

      test('returning the same instance every time', () {
        expect(
          getConstructor(reflectClass(Foo), #create) ==
          getConstructor(reflectClass(Foo), #create), isTrue);
      });
    });

    group('has getStaticFactory', () {
      test('working as intended', () {
        final factory = getStaticFactory(reflectClass(Foo), #staticFooFactory);
        expect(factory(['', new DateTime.now()]), const isInstanceOf<Foo>());
      });

      test('returning the same instance every time', () {
        expect(
          getStaticFactory(reflectClass(Foo), #staticFooFactory) ==
          getStaticFactory(reflectClass(Foo), #staticFooFactory), isTrue);
      });
    });

    test('has getAnnotations working as intended', () {
      expect(getAnnotations(reflectClass(Foo), Inject), [
        const Inject()
      ]);
      expect(getAnnotations(reflectClass(Foo), Module), []);
    });

    test('has getInjectable working as intended', () {
      expect(
        getInjectable(reflectClass(Foo)), const Inject());
      expect(getInjectable(reflectClass(FooModule)), isNull);
    });

    test('has getModule working as intended', () {
      expect(getModule(reflectClass(FooModule)), const Module(const [Foo]));
      expect(getModule(reflectClass(Foo)), isNull);
    });

    test('getProviders works as intended', () {
      expect(getProviders(reflectClass(Foo), Foo), hasLength(1));
    });

    test('getProvider works as intended', () {
      final provider = getProvider(reflectClass(Foo), Foo);
      expect(provider.factory([null, null]), const isInstanceOf<Foo>());
    });

    test('resolve works as intended', () {
      final bindings = resolve(FooModule);
      expect(bindings, hasLength(1));
    });
  });
}
