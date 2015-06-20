library cork.test.generator_test;

import 'dart:io';

import 'package:analysis/analysis.dart';
import 'package:dart_builder/dart_builder.dart' show SourceFile;
import 'package:cork/src/generator/class_generator.dart';
import 'package:cork/testing/library/foo.dart';
import 'package:cork/testing/library/foo_generated_class.dart' as clazz;
import 'package:test/test.dart';

void main() {
  final foo = Uri.parse('package:cork/testing/library/foo.dart');
  final cl = Uri.parse('package:cork/testing/library/foo_generated_class.dart');

  // TODO: Remove this package root hack.
  final resolver = new SourceResolver.forTesting();

  group('StaticClassGenerator', () {
    InjectorClassGenerator generator;

    setUp(() {
      generator = new InjectorClassGenerator(resolver: resolver);
    });

    test('analyzes a library and generates a class', () async {
      SourceFile result = await generator.generate(foo);
      var path = new SourceResolver().find(cl);
      var file = await new File(path).readAsString();
      expect(result.toSource(), file);
    });

    test('produces a custom Injector', () {
      var injector = new clazz.$GeneratedInjector();
      expect(injector.get1(), const isInstanceOf<Foo>());
    });
  });;
}
