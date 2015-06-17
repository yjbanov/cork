library cork.test.generator_test;

import 'dart:io';

import 'package:analysis/analysis.dart';
import 'package:cork/cork.dart';
import 'package:cork/src/generator.dart';
import 'package:cork/testing/library/foo.dart';
import 'package:cork/testing/library/foo_generated.dart' as generated;
import 'package:test/test.dart';

void main() {
  group('StaticBindingGenerator', () {
    final foo = Uri.parse('package:cork/testing/library/foo.dart');
    final gen = Uri.parse('package:cork/testing/library/foo_generated.dart');

    StaticBindingGenerator generator;

    // TODO: Remove this package root hack.
    var customPackageRoot = Platform.packageRoot.toString();
    customPackageRoot = customPackageRoot.replaceFirst('file://', '');
    if (!Platform.script.toFilePath().endsWith('generator_test.dart')) {
      customPackageRoot = customPackageRoot.replaceFirst('/packages', '');
    }

    final resolver = new SourceResolver.fromPackageRoots([
      customPackageRoot,
    ], includeDefaultPackageRoot: false);

    setUp(() {
      generator = new StaticBindingGenerator(resolver: resolver);
    });

    test('analyzes a library and generate a collection of bindings', () async {
      var result = await generator.generate(foo);
      var path = new SourceResolver().find(gen);
      var file = await new File(path).readAsString();
      expect(result, file);
    });

    test('produces bindings that work with Injector', () {
      var injector = new Injector(generated.staticBindings);
      expect(injector.get(Foo), const isInstanceOf<Foo>());
    });
  });
}
