library cork.test.genreator.bindings_test;

import 'dart:io';

import 'package:analysis/analysis.dart';
import 'package:cork/src/generator/class.dart';
import 'package:cork/testing/integration/spec.dart';
import 'package:cork/testing/integration/spec_injector_1.dart' as generated_1;
import 'package:cork/testing/integration/spec_injector_2.dart' as generated_2;
import 'package:dart_builder/dart_builder.dart';
import 'package:test/test.dart';

void main() {
  group('ClassGenerator', () {
    ClassGenerator generator;
    final resolver = new SourceResolver.forTesting();

    setUp(() {
      var anthology = new Anthology(resolver: resolver);
      generator = new ClassGenerator(anthology);
    });

    test('generation matches the golden file (spec_injector_1.dart)', () async {
      final uri1 = Uri.parse('package:cork/testing/integration/spec.dart');
      final uri2 =
          Uri.parse('package:cork/testing/integration/spec_injector_1.dart');
      SourceFile file = await generator.process(uri1, 'SingleModuleEntrypoint');
      final goldenFile = new File(resolver.find(uri2));
      String goldenSource = await goldenFile.readAsString();
      expect(file.toSource(), goldenSource);
    });

    test('\'s content works as expected (SingleModuleEntrypoint)', () {
      var injector = new generated_1.SingleModuleEntrypointInjector();
      Bar bar = injector.getBar();
      expect(bar.foo, const isInstanceOf<Foo>());
    });

    test('generation matches the golden file (spec_injector_2.dart)', () async {
      final uri1 = Uri.parse('package:cork/testing/integration/spec.dart');
      final uri2 =
          Uri.parse('package:cork/testing/integration/spec_injector_2.dart');
      SourceFile file = await generator.process(uri1, 'DoubleModuleEntrypoint');
      final goldenFile = new File(resolver.find(uri2));
      String goldenSource = await goldenFile.readAsString();
      expect(file.toSource(), goldenSource);
    });

    test('\'s content works as expected (DoubleModuleEntrypoint)', () {
      var injector = new generated_2.DoubleModuleEntrypointInjector();
      Bar bar = injector.getBar();
      expect(bar.foo, const isInstanceOf<FooImpl>());
    });
  });
}
