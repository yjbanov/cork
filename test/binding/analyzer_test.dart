library cork.test.binding.static_test;

import 'package:analysis/analysis.dart';
import 'package:analyzer/analyzer.dart';
import 'package:cork/cork.dart';
import 'package:cork/src/binding/analyzer.dart';
import 'package:dart_builder/dart_builder.dart';
import 'package:test/test.dart';

void main() {
  group('Static implementation of binding resolution', () {
    final resolver = new SourceResolver.forTesting();
    final uri = Uri.parse('package:cork/testing/library/foo.dart');

    Anthology anthology;
    StaticBindingAnalyzer analyzer;
    AnthologyAnalysisProvider provider;

    Library library;

    setUp(() {
      anthology = new Anthology(resolver: resolver);
      provider = new AnthologyAnalysisProvider(anthology);
      analyzer = new StaticBindingAnalyzer(provider);

      library = anthology.visit(uri: uri);
    });

    test('has getPositionalArgumentTypes working as intended', () {
      ClassDeclaration clazz = library.getDeclaration('Foo');
      final method = clazz.getMethod('staticFooFactory');
      expect(analyzer.getPositionalArgumentTypes(method), [
        TypeRef.STRING,
        new TypeRef('Bar')
      ]);
    });

    group('hasConstructor', () {
      test('working as intended', () {
        ClassDeclaration clazz = library.getDeclaration('Foo');
        final factory = analyzer.getConstructor(clazz, 'create');
        expect(factory.invoke([]).toSource(), 'new Foo.create()');
      });
    });

    group('has getStaticFactory', () {
      test('working as intended', () {
        final uri = Uri.parse('package:cork/testing/library/foo_imported.dart');
        ClassDeclaration bar = anthology.visit(uri: uri).getDeclaration('Bar');

        ClassDeclaration clazz = library.getDeclaration('Foo');
        final factory = analyzer.getStaticFactory(clazz, 'staticFooFactory');
        expect(
            factory.invoke([
              new Source.fromDart("''"),
              new CallRef.constructor(analyzer.scopeType(bar.element.type))
            ]).toSource(),
            'Foo.staticFooFactory(\'\', new Bar())');
      });
    });

    test('has getAnnotations working as intended', () {
      ClassDeclaration foo = library.getDeclaration('Foo');
      expect(analyzer.getAnnotations(foo, Inject), hasLength(1));
      expect(analyzer.getAnnotations(foo, Module), hasLength(0));
    });

    test('has hasInjectable working as intended', () {
      ClassDeclaration foo = library.getDeclaration('Foo');
      ClassDeclaration fooModule = library.getDeclaration('FooModule');
      expect(analyzer.hasInjectable(foo), isTrue);
      expect(analyzer.hasInjectable(fooModule), isFalse);
    });

    test('has getModuleRef working as intended', () {
      ClassDeclaration foo = library.getDeclaration('Foo');
      ClassDeclaration fooModule = library.getDeclaration('FooModule');
      final fooModuleRef = analyzer.getModuleRef(fooModule);
      expect(
          fooModuleRef.included.map((i) => i.element.type.displayName),
          ['Foo']);
      expect(analyzer.getModuleRef(foo), isNull);
    });

    test('has getProviders working as intended', () {
      ClassDeclaration foo = library.getDeclaration('Foo');
      expect(analyzer.getProviders(foo, foo.element.type), hasLength(1));
    });

    test('has getProvider working as intended', () {
      ClassDeclaration foo = library.getDeclaration('Foo');
      final providerRef = analyzer.getProvider(foo, foo.element.type);
      expect(providerRef.dependencies, [
        TypeRef.STRING,
        new TypeRef('Bar')
      ]);
      expect(
          providerRef.factoryRef.invoke([
            new Source.fromDart('null'),
            new Source.fromDart('null')
          ]).toSource(),
          'Foo.staticFooFactory(null, null)');
    });

    test('resolve works as intended', () {
      ClassDeclaration fooModule = library.getDeclaration('FooModule');
      final bindingRefs = analyzer.resolve(fooModule);
      expect(bindingRefs, hasLength(1));

      final fooBinding = bindingRefs.first;
      expect(fooBinding.tokenRef.toSource(), 'Foo');
      expect(
          fooBinding.providerRef.factoryRef.invoke([]).toSource(),
          'Foo.staticFooFactory()');
      expect(
          fooBinding.providerRef.dependencies,
          [TypeRef.STRING, new TypeRef('Bar')]);
    });
  });
}
