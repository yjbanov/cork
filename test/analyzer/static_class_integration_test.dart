library cork.test.static.static_class_integration_test;

import 'dart:io';

import 'package:analysis/analysis.dart';
import 'package:cork/cork.dart';
import 'package:cork/src/generator/class_generator.dart';
import 'package:cork/testing/integration/library_spec.dart';
import 'package:cork/testing/integration/library_spec.bindings.dart';
import 'package:dart_builder/dart_builder.dart';
import 'package:test/test.dart';

void main() {
  group('Generating static bindings', () {
    InjectorClassGenerator generator;
    SourceResolver resolver;

    final bindingsUri = Uri.parse(
        'package:cork/testing/integration/library_spec.injector.dart');
    final uri = Uri.parse('package:cork/testing/integration/library_spec.dart');

    setUp(() {
      resolver = new SourceResolver.forTesting();
      generator = new InjectorClassGenerator(resolver: resolver);
    });

    test('can generate correctly', () async {
      SourceFile result = await generator.generate(uri);
      var path = resolver.find(bindingsUri);
      var file = await new File(path).readAsString();
      expect(result.toSource(), file);
    });
  });

  group('Integration of modules', () {
    Injector injector;
    Bar bar;

    test('based on a single module', () {
      injector = new Injector(staticBindings);
      bar = injector.get(Bar);
      expect(bar.foo, const isInstanceOf<Foo>());
    });

    test('based on an overriding module', () {
      injector = new Injector(/* bindingsForSingleModuleEntrypoint */ []);
      bar = injector.get(Bar);
      expect(bar.foo, const isInstanceOf<FooImpl>());
    }, skip: 'Not supported yet in static mode.');
  });
}
