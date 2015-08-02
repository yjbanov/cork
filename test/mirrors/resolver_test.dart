library cork.test.mirrors.resolver_test;

import 'dart:mirrors';

import 'package:cork/src/api/annotations.dart';
import 'package:cork/src/mirrors/resolver.dart';
import 'package:cork/src/testing/matchers.dart';
import 'package:test/test.dart';

void main() {
  group('MirrorsUtils', () {
    test('hasAnnotation should return true when annotation is present', () {
      expect(
          const MirrorUtils<Annotation>().hasAnnotation(reflectType(Foo)),
          isTrue);
    });

    test('hasAnnotation should return false when annotation not present', () {
      expect(
          const MirrorUtils<Annotation>().hasAnnotation(reflectType(Baz)),
          isFalse);
    });

    test('getAnnotation should return when annotation is present', () {
      expect(
          const MirrorUtils<Annotation>().getAnnotation(reflectType(Foo)),
          const isInstanceOf<Annotation>());
    });

    test('getAnnotation should return null when annotation not present', () {
      expect(
          const MirrorUtils<Annotation>().getAnnotation(reflectType(Baz)),
          isNull);
    });

    test('should support inheriting from another annotation', () {
      expect(
          const MirrorUtils<AnnotationPrime>().getAnnotation(reflectType(Bar)),
          const isInstanceOf<Annotation>());
    });
  });

  group('MirrorsResolver', () {
    final resolver = const MirrorsResolver();

    group('isInjectable', () {
      test('should return true for a class annotated with @Inject', () {
        expect(resolver.isInjectable(reflectClass(Engine)), isTrue);
      });

      test('should return false for a class not annotated with @Inject', () {
        expect(resolver.isInjectable(reflectClass(Station)), isFalse);
      });
    });

    group('isProvider', () {
      final mirror = reflectClass(Station);

      test('should return true for a method annotated with @Provide', () {
        expect(resolver.isProvider(mirror.instanceMembers[#getFuel]), isTrue);
      });

      test('should return false for a method not annotated with @Provide', () {
        expect(
            resolver.isProvider(mirror.instanceMembers[#getEngine]),
            isFalse);
      });
    });

    group('getClassProvider', () {
      test('should throw on a class not annotated with @Inject', () {
        expect(
            () => resolver.getClassProvider(reflectClass(NotInjectable)),
            throwsNoAnnotationFoundError);
      });

      test('should throw when multiple methods are annotated @Provide', () {
        expect(
            () => resolver.getClassProvider(reflectClass(TooManyProviders)),
            throwsInvalidConfigurationError);
      });

      test('should return the method annotated with @Provide', () {
        final mirror = resolver.getClassProvider(reflectClass(HasProvider));
        expect(mirror.constructorName, #yay);
      });

      test('should return null when nothing was annotated @Provide', () {
        expect(resolver.getClassProvider(reflectClass(NoProvider)), isNull);
      });
    });

    group('getParameterTypes', () {
      test('should return an empty list on a method with no parameters', () {
        final mirror = (reflect((){}) as ClosureMirror).function;
        expect(resolver.getParameterTypes(mirror), isEmpty);
      });

      test('should return a list of `Type`s for parameters', () {
        final method = (Foo foo, Bar bar) {};
        final mirror = (reflect(method) as ClosureMirror).function;
        expect(resolver.getParameterTypes(mirror), [Foo, Bar]);
      });
    });

    test('resolveAlias should return a resolved binding', () {
      final resolved = resolver.resolveAlias(const Binding.toAlias(Foo, Bar));
      expect(resolved.token, Foo);
      expect(resolved.dependencies, [Bar]);
      expect(resolved.factory([new Bar()]), const isInstanceOf<Bar>());
    });

    test('resolveClass should return a resolved binding', () {
      final binding = const Binding.toClass(Foo, FooImpl);
      final resolved = resolver.resolveClass(binding);
      expect(resolved.token, Foo);
      expect(resolved.dependencies, [Baz]);
      expect(resolved.factory([new Baz()]), const isInstanceOf<FooImpl>());
    });

    test('resolveFactory should return a resolved binding', () {
      final binding = new Binding.toFactory(Foo, (Bar bar) => new Foo());
      final resolved = resolver.resolveFactory(binding);
      expect(resolved.token, Foo);
      expect(resolved.dependencies, [Bar]);
      expect(resolved.factory([new Bar()]), const isInstanceOf<Foo>());
    });

    test('resolveValue should return a resolved binding', () {
      final binding = new Binding.toValue('Name', 'John Smith');
      final resolved = resolver.resolveValue(binding);
      expect(resolved.token, 'Name');
      expect(resolved.dependencies, isEmpty);
      expect(resolved.factory([]), 'John Smith');
    });

    group('resolveBinding', () {
      test('should throw if no provider found in the module', () {
        final binding = const Binding(NoProvider);
        expect(
            () => resolver.resolveBinding(binding),
            throwsNoProviderFoundError);
      });
    });

    group('getModule', () {
      test('should throw if @Module is not found', () {
        expect(
            () => resolver.getModule(Baz),
            throwsNoAnnotationFoundError);
      });

      test('should throw if @Module is entirely blank', () {
        expect(
            () => resolver.getModule(BlankModule),
            throwsStateError);
      });
    });

    group('resolveProviders', () {
      test('should throw if the module is not constructable', () {
        expect(
            () => resolver.resolveProviders(reflectClass(BadModule)),
            throwsInvalidConfigurationError);
      });

      test('should gather providers', () {
        final classMirror = reflectClass(Station);
        final resolvedProviders = resolver.resolveProviders(classMirror);
        expect(resolvedProviders.containsKey(Fuel), isTrue);
        expect(resolvedProviders.containsKey(Engine), isFalse);
      });
    });
  });
}

@Annotation()
class Foo {}

@Inject()
class FooImpl implements Foo {
  @Provide()
  FooImpl(Baz baz);
}

@AnnotationPrime()
class Bar {}

class Baz {}

class Annotation {
  const Annotation();
}

class AnnotationPrime implements Annotation {
  const AnnotationPrime();
}

class Car {}

class NotInjectable {}

@Inject()
class TooManyProviders {
  @Provide()
  TooManyProviders.con1();

  @Provide()
  TooManyProviders.con2();
}

@Inject()
class NoProvider {}

@Inject()
class Engine {}

@Inject()
class Fuel {}

@Inject()
class HasProvider {
  @Provide()
  HasProvider.yay();
}

@Module()
class BlankModule {}

@Module()
class BadModule {
  BadModule.con1();

  @Provide()
  Fuel getFuel() => new Fuel();
}

@Module(bindings: const [
  const Binding(Fuel)
])
class Station {
  Engine getEngine() => new Engine();

  @Provide()
  Fuel getFuel() => new Fuel();
}

@Module(bindings: const [
  const Binding(Engine)
])
class StationWithMissing {
  Engine getEngine() => new Engine();
}
