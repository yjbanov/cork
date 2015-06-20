library cork.test.generator_test;

import 'dart:io';

import 'package:analysis/analysis.dart';
import 'package:cork/cork.dart';
import 'package:cork/src/generator/binding_generator.dart';
import 'package:cork/testing/library/foo.dart';
import 'package:cork/testing/library/foo_generated.dart' as generated;
import 'package:dart_builder/dart_builder.dart';
import 'package:test/test.dart';

void main() {
  final foo = Uri.parse('package:cork/testing/library/foo.dart');
  final gen = Uri.parse('package:cork/testing/library/foo_generated.dart');

  // TODO: Remove this package root hack.
  final resolver = new SourceResolver.forTesting();

  group('StaticBindingGenerator', () {
    StaticBindingGenerator generator;

    setUp(() {
      generator = new StaticBindingGenerator(resolver: resolver);
    });

    test('analyzes a library and generate a collection of bindings', () async {
      SourceFile result = await generator.generate(foo);
      var path = new SourceResolver().find(gen);
      var file = await new File(path).readAsString();
      expect(result.toSource(), file);
    });

    test('produces bindings that work with Injector', () {
      var injector = new Injector(generated.staticBindings);
      expect(injector.get(Foo), const isInstanceOf<Foo>());
    });
  });
}
